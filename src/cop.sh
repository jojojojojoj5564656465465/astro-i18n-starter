#!/bin/bash

# Script: Enhanced File Copier & Concatenator
# Auteur: [Nom Original/Utilisateur] (révisé et amélioré par une IA)
# Date de révision: 2024-03-15
# Version: 3.2 (Options de format réduites, correction show_header)
# Description:
# Ce script Bash interactif permet à l'utilisateur de sélectionner plusieurs fichiers
# via une interface utilisateur basée sur 'gum'. Le contenu concaténé des fichiers
# sélectionnés est ensuite copié dans le presse-papiers du système.
# L'utilisateur peut choisir entre un format Simple ou Markdown pour le contenu copié.
# Fonctionnalités clés :
#   - Interface utilisateur élégante avec 'gum'.
#   - Sélection de fichiers via les arguments de la ligne de commande ou un navigateur de fichiers.
#   - Détection et prévention des doublons de fichiers.
#   - Choix du format de sortie (Simple, Markdown).
#   - Copie multi-plateforme dans le presse-papiers (Linux, macOS, WSL).
#   - Aperçu optionnel du contenu copié avec 'gum pager < FICHIER_TEMP'.
#   - Affichage de statistiques sur le contenu copié.
# Dépendances:
#   - gum (https://github.com/charmbracelet/gum)
#   - Utilitaires de presse-papiers: xclip (Linux), pbcopy (macOS), clip.exe (WSL)
# Usage: ./copy_files_content.sh [fichier1 fichier2 ...]

# Configuration des couleurs et styles
BLUE="#87CEEB"
GREEN="#98FB98"
YELLOW="#F0E68C"
RED="#FFB6C1"
PURPLE="#DDA0DD"

# Vérifier si gum est installé
if ! command -v gum >/dev/null 2>&1; then
    echo "❌ Erreur: Gum n'est pas installé." >&2 
    echo "Installez-le avec: brew install gum (ou voir https://github.com/charmbracelet/gum )" >&2
    exit 1
fi

# Vérifier les utilitaires de presse-papiers
CLIPBOARD_CMD="" 
if command -v xclip >/dev/null 2>&1; then
    CLIPBOARD_CMD="xclip -selection clipboard"
elif command -v pbcopy >/dev/null 2>&1; then
    CLIPBOARD_CMD="pbcopy"
elif command -v clip.exe >/dev/null 2>&1; then 
    CLIPBOARD_CMD="clip.exe"
else
    command gum style --foreground "$RED" --bold "❌ Aucun utilitaire de presse-papiers trouvé." >&2
    command gum style --foreground "$YELLOW" "Installez xclip (Linux), pbcopy (macOS), ou clip.exe (WSL)." >&2
    exit 1
fi

# Fonction pour afficher le titre
show_header() {
    # CORRECTION: Le titre doit être sur stderr pour ne pas interférer avec la sortie de select_files
    command gum style --foreground "$PURPLE" --border double --align center --width 60 --margin "1 2" --padding "1 2" \
        "📁 Select multiple files from project ✨" >&2
}

# Fonction pour ajouter un fichier unique à la liste
add_unique_file() {
    local file_to_add="$1"
    local -n files_array_ref="$2" 

    local abs_path_to_add
    abs_path_to_add=$(realpath "$file_to_add" 2>/dev/null || echo "$file_to_add")

    for existing_file in "${files_array_ref[@]}"; do
        local existing_abs_path
        existing_abs_path=$(realpath "$existing_file" 2>/dev/null || echo "$existing_file")
        if [ "$abs_path_to_add" = "$existing_abs_path" ]; then
            command gum style --foreground "$YELLOW" "⚠️  Fichier déjà sélectionné: $(basename "$file_to_add")" >&2
            return 1 
        fi
    done

    files_array_ref+=("$file_to_add") 
    return 0 
}

# Fonction pour sélectionner des fichiers
select_files() {
    local files=() 

    if [ $# -gt 0 ]; then
        command gum style --foreground "$BLUE" "📂 Fichiers fournis en arguments:" >&2
        local initial_files_from_args=()
        for arg_file in "$@"; do
            if [ -f "$arg_file" ]; then
                if add_unique_file "$arg_file" initial_files_from_args; then
                    command gum style --foreground "$GREEN" "  ✓ $arg_file (valide)" >&2
                else
                    : 
                fi
            else
                command gum style --foreground "$RED" "  ✗ $arg_file (non trouvé ou pas un fichier)" >&2
            fi
        done

        if [ ${#initial_files_from_args[@]} -gt 0 ]; then
            command gum style --foreground "$BLUE" "Souhaitez-vous utiliser ces ${#initial_files_from_args[@]} fichier(s) valide(s) trouvés dans les arguments ?" >&2
            if command gum confirm --default=true "Utiliser ces fichiers ?"; then
                files=("${initial_files_from_args[@]}")
                printf '%s\n' "${files[@]}" 
                return
            else
                 command gum style --foreground "$YELLOW" "ℹ️ Les fichiers des arguments ne seront pas utilisés. Passage à la sélection interactive." >&2
            fi
        else
            command gum style --foreground "$YELLOW" "ℹ️ Aucun fichier valide fourni en argument. Passage à la sélection interactive." >&2
        fi
    fi

    command gum style --foreground "$BLUE" --bold "📁 Sélection interactive de fichiers" >&2

    while true; do
        local num_files=${#files[@]}
        local header_text="Fichiers sélectionnés: $num_files. Action ?"
        if [ "$num_files" -eq 0 ]; then
            header_text="Aucun fichier sélectionné. Que faire ?"
        fi
        
        local METHOD
        METHOD=$(command gum choose --header "$header_text" \
            "Ajouter un fichier (Navigateur)" \
            "Terminer la sélection ($num_files fichier(s))")

        if [ -z "$METHOD" ]; then 
            command gum style --foreground "$YELLOW" "⚠️ Sélection annulée. Terminer la sélection ?" >&2
            if command gum confirm "Oui, terminer" ; then
                break 
            else
                continue 
            fi
        fi

        case "$METHOD" in
            "Ajouter un fichier (Navigateur)")
                local selected_path
                selected_path=$(command gum file --directory .) 
                
                if [ -n "$selected_path" ]; then 
                    if [ -f "$selected_path" ]; then
                        if add_unique_file "$selected_path" files; then
                            command gum style --foreground "$GREEN" "✓ Ajouté: $(basename "$selected_path")" >&2
                        fi
                    else
                        if [ -d "$selected_path" ]; then
                            command gum style --foreground "$RED" "✗ '$(basename "$selected_path")' est un répertoire. Veuillez sélectionner un fichier." >&2
                        else
                            command gum style --foreground "$RED" "✗ '$(basename "$selected_path")' n'est pas un fichier valide." >&2
                        fi
                    fi
                else
                    command gum style --foreground "$YELLOW" "ℹ️ Aucune sélection depuis le navigateur." >&2
                fi
                ;;
            
            "Terminer la sélection ($num_files fichier(s))")
                if [ ${#files[@]} -eq 0 ]; then
                    command gum style --foreground "$YELLOW" "⚠️ Aucun fichier n'a été sélectionné." >&2
                    if ! command gum confirm "Voulez-vous vraiment terminer sans sélectionner de fichiers ?"; then
                        continue 
                    fi
                fi
                if [ ${#files[@]} -gt 0 ]; then
                    command gum style --foreground "$BLUE" --bold "📋 Liste finale des fichiers sélectionnés (${#files[@]}):" >&2
                    for f_path in "${files[@]}"; do
                        echo "  - $(basename "$f_path")" | command gum style --foreground "$GREEN" --margin "0 2" >&2
                    done
                fi
                break 
                ;;
            *)
                command gum style --foreground "$RED" "Option invalide." >&2
                ;;
        esac
    done

    if [ ${#files[@]} -gt 0 ]; then
        printf '%s\n' "${files[@]}"
    fi
}

# Fonction pour choisir le format de sortie
# MODIFICATION: Options de format réduites
format_content() {
    local format_choice

    format_choice=$(command gum choose --header "Choisissez le format de sortie du contenu:" \
        "Simple (avec séparateurs)" \
        "Markdown (avec blocs de code)")

    case "$format_choice" in
        "Markdown (avec blocs de code)")
            return 1
            ;;
        "Simple (avec séparateurs)" | *) # Cas par défaut si "Simple" est choisi ou si la sélection est annulée
            return 0
            ;;
    esac
}

# Fonction principale
main() {
    show_header

    local selected_files=() 
    mapfile -t selected_files < <(select_files "$@")

    if [ ${#selected_files[@]} -eq 0 ]; then
        command gum style --foreground "$YELLOW" --bold "ℹ️  Aucun fichier sélectionné. Arrêt du script." >&2 
        exit 0
    fi

    format_content 
    local FORMAT_TYPE=$? 

    local TEMP_FILE
    TEMP_FILE=$(mktemp)
    if [[ -z "$TEMP_FILE" || ! -f "$TEMP_FILE" ]]; then
        command gum style --foreground "$RED" --bold "❌ Erreur critique: Impossible de créer le fichier temporaire." >&2
        exit 1
    fi
    trap 'rm -f "$TEMP_FILE"' EXIT


    command gum spin --spinner dot --title "Préparation du contenu des fichiers..." -- sleep 0.1

    local FILES_PROCESSED=0
    local file_path 

    for file_path in "${selected_files[@]}"; do
        if [ -f "$file_path" ]; then 
            local filename
            filename=$(basename "$file_path")

            # MODIFICATION: Logique de formatage simplifiée
            case $FORMAT_TYPE in
                1) # Markdown
                    local extension="${filename##*.}" 
                    if [[ "$extension" == "$filename" ]] || [[ -z "$extension" ]]; then 
                        extension="text" 
                    elif [[ "$filename" == ".$extension" ]]; then 
                        extension="${filename#.}" 
                    fi
                    [[ -z "$extension" ]] && extension="text"

                    echo "\`\`\`${extension}" >> "$TEMP_FILE"
                    echo "// Fichier: $file_path" >> "$TEMP_FILE"
                    cat "$file_path" >> "$TEMP_FILE"
                    [[ $(tail -c1 "$file_path" | wc -l) -eq 0 ]] && echo >> "$TEMP_FILE"
                    echo "\`\`\`" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE" 
                    ;;
                0 | *) # Simple (FORMAT_TYPE 0) et cas par défaut
                    echo "=== FICHIER: $file_path ===" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    cat "$file_path" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    echo "----------------------------------------" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    ;;
            esac
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
        else
             command gum style --foreground "$RED" "⚠️ Fichier '$file_path' non trouvé ou inaccessible au moment du traitement. Ignoré." >&2
        fi
    done

    if [ "$FILES_PROCESSED" -eq 0 ]; then
        command gum style --foreground "$RED" --bold "❌ Aucun fichier n'a pu être traité. Vérifiez les chemins ou permissions." >&2
        exit 1
    fi

    if command gum spin --spinner globe --title "Copie du contenu dans le presse-papiers..." -- bash -c "cat '$TEMP_FILE' | $CLIPBOARD_CMD"; then
        command gum style --foreground "$GREEN" --bold "✅ Succès!" >&2 
        command gum style --foreground "$BLUE" "$FILES_PROCESSED fichier(s) traité(s) et contenu copié dans le presse-papiers." >&2 

        local TOTAL_LINES CHAR_COUNT WORD_COUNT
        read TOTAL_LINES _ < <(wc -l "$TEMP_FILE")
        read CHAR_COUNT _ < <(wc -c "$TEMP_FILE")
        read WORD_COUNT _ < <(wc -w "$TEMP_FILE")

        if command gum confirm --default=false "Voir le contenu (qui a été copié) avec un pager ?"; then
            command gum style --foreground "$PURPLE" --border double --padding "1 2" --margin "1 0" "📄 APERÇU DU CONTENU (via gum pager)" >&2
            
            if command gum pager < "$TEMP_FILE"; then
                command gum style --foreground "$GREEN" --bold "💾 Total: $TOTAL_LINES lignes de contenu (consultées avec le pager)." >&2
            else
                command gum style --foreground "$YELLOW" "⚠️  Le pager (gum pager < $TEMP_FILE) n'a pas pu s'afficher correctement ou a été fermé prématurément." >&2
                command gum style --foreground "$YELLOW" "Affichage des 30 premières lignes du contenu à la place :" >&2
                head -n 30 "$TEMP_FILE" | sed 's/^/  /' | command gum style --margin "0 1" >&2 
                if [ "$TOTAL_LINES" -gt 30 ]; then
                    command gum style --foreground "$YELLOW" "  ...et $(($TOTAL_LINES - 30)) lignes supplémentaires." >&2
                fi
                command gum style --foreground "$GREEN" --bold "💾 Total: $TOTAL_LINES lignes de contenu." >&2
            fi
        fi

        command gum join --vertical --align left \
            "$(command gum style --foreground "$PURPLE" --bold "📊 STATISTIQUES DU CONTENU")" \
            "$(command gum style --foreground "$BLUE" "Fichiers traités: $FILES_PROCESSED")" \
            "$(command gum style --foreground "$BLUE" "Lignes totales: $TOTAL_LINES")" \
            "$(command gum style --foreground "$BLUE" "Mots totaux: $WORD_COUNT")" \
            "$(command gum style --foreground "$BLUE" "Caractères totaux: $CHAR_COUNT")" >&2 

    else
        command gum style --foreground "$RED" --bold "❌ Erreur lors de la copie dans le presse-papiers." >&2 
        command gum style --foreground "$YELLOW" "Le contenu agrégé se trouve dans: $TEMP_FILE" >&2 
        command gum style --foreground "$YELLOW" "(Ce fichier ne sera pas supprimé automatiquement en cas d'échec de copie)." >&2
        trap - EXIT 
        exit 1
    fi
}

main "$@"
#!/bin/bash

# Script: Enhanced File Copier
# Auteur: [Nom Original/Utilisateur] (révisé et amélioré par une IA)
# Date de révision: 2024-03-14
# Version: 2.1
# Description:
# Ce script Bash interactif permet à l'utilisateur de sélectionner plusieurs fichiers
# via une interface utilisateur basée sur 'gum'. Le contenu concaténé des fichiers
# sélectionnés est ensuite copié dans le presse-papiers du système.
# L'utilisateur peut choisir parmi différents formats de sortie pour le contenu copié.
# Fonctionnalités clés :
#   - Interface utilisateur élégante avec 'gum'.
#   - Sélection de fichiers via les arguments de la ligne de commande ou un navigateur de fichiers.
#   - Détection et prévention des doublons de fichiers.
#   - Choix du format de sortie (Simple, Markdown, Numéroté, Compact).
#   - Copie multi-plateforme dans le presse-papiers (Linux, macOS, WSL).
#   - Aperçu optionnel du contenu copié.
#   - Affichage de statistiques sur le contenu copié.
# Dépendances:
#   - gum (https://github.com/charmbracelet/gum)
#   - Utilitaires de presse-papiers: xclip (Linux), pbcopy (macOS), clip.exe (WSL)
# Usage: ./copy_files_enhanced.sh [fichier1 fichier2 ...]

# Configuration des couleurs et styles
BLUE="#87CEEB"
GREEN="#98FB98"
YELLOW="#F0E68C"
RED="#FFB6C1"
PURPLE="#DDA0DD"

# Vérifier si gum est installé
if ! command -v gum >/dev/null 2>&1; then
    echo "❌ Erreur: Gum n'est pas installé."
    echo "Installez-le avec: brew install gum (ou voir https://github.com/charmbracelet/gum )"
    exit 1
fi

# Vérifier les utilitaires de presse-papiers
CLIPBOARD_CMD="" # Initialisation
if command -v xclip >/dev/null 2>&1; then
    CLIPBOARD_CMD="xclip -selection clipboard"
elif command -v pbcopy >/dev/null 2>&1; then
    CLIPBOARD_CMD="pbcopy"
elif command -v clip.exe >/dev/null 2>&1; then # WSL
    CLIPBOARD_CMD="clip.exe"
else
    gum style --foreground "$RED" --bold "❌ Aucun utilitaire de presse-papiers trouvé."
    gum style --foreground "$YELLOW" "Installez xclip (Linux), pbcopy (macOS), ou clip.exe (WSL)."
    exit 1
fi

# Fonction pour afficher le titre
show_header() {
    gum style --foreground "$PURPLE" --border double --align center --width 60 --margin "1 2" --padding "1 2" \
        "📁 COPIEUR DE FICHIERS MULTIPLES" \
        "Powered by Gum ✨"
}

# Fonction pour ajouter un fichier unique à la liste
# Arguments:
#   $1: Fichier à ajouter
#   $2: Nom de la variable tableau (nameref) où ajouter le fichier
# Retourne:
#   0 si le fichier a été ajouté
#   1 si le fichier est un doublon (et n'a pas été ajouté)
add_unique_file() {
    local file_to_add="$1"
    local -n files_array_ref="$2" # nameref vers l'array de fichiers

    # Résoudre le chemin absolu pour éviter les doublons de chemins relatifs/absolus
    # `realpath` peut échouer si le fichier n'existe pas, d'où le `|| echo`
    local abs_path_to_add
    abs_path_to_add=$(realpath "$file_to_add" 2>/dev/null || echo "$file_to_add")

    # Vérifier si le fichier n'est pas déjà dans la liste (en comparant les chemins absolus)
    for existing_file in "${files_array_ref[@]}"; do
        local existing_abs_path
        existing_abs_path=$(realpath "$existing_file" 2>/dev/null || echo "$existing_file")
        if [ "$abs_path_to_add" = "$existing_abs_path" ]; then
            gum style --foreground "$YELLOW" "⚠️  Fichier déjà sélectionné: $file_to_add"
            return 1 # Indique que le fichier n'a pas été ajouté (car doublon)
        fi
    done

    files_array_ref+=("$file_to_add") # Ajoute le fichier à l'array référencé
    return 0 # Indique que le fichier a été ajouté avec succès
}

# Fonction pour sélectionner des fichiers
# Arguments:
#   $@: Fichiers potentiels passés en arguments au script
# Sortie (stdout):
#   Liste des chemins de fichiers sélectionnés, un par ligne (pour mapfile)
select_files() {
    local files=() # Array local pour stocker les fichiers sélectionnés

    # Gérer les fichiers passés en arguments
    if [ $# -gt 0 ]; then
        gum style --foreground "$BLUE" "📂 Fichiers fournis en arguments:"
        local initial_files_from_args=()
        for arg_file in "$@"; do
            if [ -f "$arg_file" ]; then
                if add_unique_file "$arg_file" initial_files_from_args; then
                    gum style --foreground "$GREEN" "  ✓ $arg_file (valide)"
                else
                    # add_unique_file affiche déjà un message pour les doublons.
                    # On pourrait ajouter un style spécifique ici si nécessaire, mais le message de add_unique_file est clair.
                    # gum style --foreground "$YELLOW" "  ! $arg_file (doublon parmi les arguments, déjà notifié)"
                    : # No-op, message déjà géré
                fi
            else
                gum style --foreground "$RED" "  ✗ $arg_file (non trouvé ou pas un fichier)"
            fi
        done

        if [ ${#initial_files_from_args[@]} -gt 0 ]; then
            gum style --foreground "$BLUE" "Souhaitez-vous utiliser ces ${#initial_files_from_args[@]} fichier(s) valide(s) trouvés dans les arguments ?"
            if gum confirm --default=true "Utiliser ces fichiers ?"; then
                # Transfère les fichiers validés vers la liste principale 'files'
                files=("${initial_files_from_args[@]}")
                printf '%s\n' "${files[@]}" # Sortie pour mapfile dans main()
                return # Termine la sélection, utilise les fichiers des arguments
            else
                 gum style --foreground "$YELLOW" "ℹ️ Les fichiers des arguments ne seront pas utilisés. Passage à la sélection interactive."
            fi
        else
            gum style --foreground "$YELLOW" "ℹ️ Aucun fichier valide fourni en argument. Passage à la sélection interactive."
        fi
    fi

    # Sélection interactive de fichiers si aucun fichier argument n'est utilisé ou si l'utilisateur a refusé
    while true; do
        gum style --foreground "$BLUE" --bold "📁 Sélection de fichiers"

        local METHOD
        METHOD=$(gum choose --header "Comment voulez-vous sélectionner les fichiers ?" \
            "Navigateur de fichiers" \
            "Terminer la sélection")

        if [ -z "$METHOD" ]; then # gum choose annulé (Echap)
            gum style --foreground "$YELLOW" "⚠️ Sélection annulée. Terminer la sélection ?"
            if gum confirm "Oui, terminer" ; then
                break # Sortir de la boucle de sélection
            else
                continue # Re-afficher le menu de sélection
            fi
        fi

        case "$METHOD" in
            "Navigateur de fichiers")
                local selected_path
                selected_path=$(gum file --directory .) # L'utilisateur navigue et choisit un fichier
                
                if [ -n "$selected_path" ]; then # Si un chemin a été retourné (pas annulé)
                    if [ -f "$selected_path" ]; then
                        if add_unique_file "$selected_path" files; then
                            gum style --foreground "$GREEN" "✓ Ajouté: $selected_path"
                        fi
                    else
                        # Vérifie si c'est un répertoire pour un message plus précis
                        if [ -d "$selected_path" ]; then
                            gum style --foreground "$RED" "✗ '$selected_path' est un répertoire. Veuillez sélectionner un fichier."
                        else
                            gum style --foreground "$RED" "✗ '$selected_path' n'est pas un fichier valide."
                        fi
                    fi
                else
                    gum style --foreground "$YELLOW" "ℹ️ Aucune sélection de fichier depuis le navigateur."
                fi
                ;;
            
            "Terminer la sélection")
                if [ ${#files[@]} -eq 0 ]; then
                    gum style --foreground "$YELLOW" "⚠️ Aucun fichier n'a été sélectionné."
                    if ! gum confirm "Voulez-vous vraiment terminer sans sélectionner de fichiers ?"; then
                        continue # Retourne à la boucle de sélection
                    fi
                fi
                break # Sort de la boucle while
                ;;
            *)
                # Ce cas ne devrait pas être atteint avec gum choose mais par sécurité.
                gum style --foreground "$RED" "Option invalide."
                ;;
        esac

        if [ ${#files[@]} -gt 0 ]; then
            gum style --foreground "$BLUE" --bold "📋 Fichiers sélectionnés (${#files[@]}):"
            printf '%s\n' "${files[@]}" | gum style --foreground "$GREEN" --margin "0 2"
        else
            gum style --foreground "$YELLOW" "📋 Aucun fichier sélectionné pour le moment."
        fi
    done

    # Retourne la liste des fichiers (chaque fichier sur une nouvelle ligne)
    if [ ${#files[@]} -gt 0 ]; then
        printf '%s\n' "${files[@]}"
    fi
}

# Fonction pour choisir le format de sortie
# Retourne:
#   0: Simple (défaut)
#   1: Markdown
#   2: Numéroté
#   3: Compact
format_content() {
    local format_choice

    format_choice=$(gum choose --header "Choisissez le format de sortie:" \
        "Simple (avec séparateurs)" \
        "Markdown (avec blocs de code)" \
        "Numéroté (avec numéros de ligne)" \
        "Compact (sans séparateurs)")

    case "$format_choice" in
        "Markdown (avec blocs de code)")
            return 1
            ;;
        "Numéroté (avec numéros de ligne)")
            return 2
            ;;
        "Compact (sans séparateurs)")
            return 3
            ;;
        "Simple (avec séparateurs)" | *) # Cas par défaut ou si choix annulé
            return 0
            ;;
    esac
}

# Fonction principale
main() {
    show_header

    # Sélectionner les fichiers
    # mapfile lit chaque ligne de la sortie de select_files dans l'array selected_files
    local selected_files=() # Initialisation pour éviter les erreurs si select_files ne retourne rien
    mapfile -t selected_files < <(select_files "$@")

    if [ ${#selected_files[@]} -eq 0 ]; then
        gum style --foreground "$YELLOW" --bold "ℹ️  Aucun fichier sélectionné. Arrêt du script."
        exit 0
    fi

    # Choisir le format
    format_content # Appel sans argument
    local FORMAT_TYPE=$? # CORRECTION: Utiliser local pour FORMAT_TYPE

    # Fichier temporaire pour agréger le contenu
    local TEMP_FILE
    TEMP_FILE=$(mktemp)
    # Assure la suppression du fichier temporaire à la fin du script, sauf si explicitement annulé
    trap 'rm -f "$TEMP_FILE"' EXIT

    # Traitement des fichiers
    gum spin --spinner dot --title "Préparation des fichiers..." -- sleep 0.2 # Petite pause visuelle

    local FILES_PROCESSED=0
    local file_path # Variable pour la boucle

    for file_path in "${selected_files[@]}"; do
        # Vérifier à nouveau au cas où le fichier aurait été supprimé entre la sélection et le traitement
        if [ -f "$file_path" ]; then
            local filename
            filename=$(basename "$file_path") # Utilisé par plusieurs formats

            case $FORMAT_TYPE in
                1) # Markdown
                    local extension="${filename##*.}" # Extrait l'extension après le dernier '.'
                    
                    # AMÉLIORATION: Gestion des fichiers sans extension ou type .bashrc
                    if [[ "$extension" == "$filename" ]] || [[ -z "$extension" ]]; then # Pas d'extension (ex: 'Makefile') ou vide
                        extension="text" # Défaut si pas d'extension ou extension vide
                    elif [[ "$filename" == ".$extension" ]]; then # Fichier commençant par un point (ex: '.bashrc' -> 'bashrc')
                        extension="${filename#.}" # Enlève le point initial
                    fi
                    # Si l'extension est vide après traitement (ex: fichier nommé juste "."), fallback sur text
                    [[ -z "$extension" ]] && extension="text"


                    echo "\`\`\`${extension}" >> "$TEMP_FILE"
                    echo "// Fichier: $file_path" >> "$TEMP_FILE"
                    cat "$file_path" >> "$TEMP_FILE"
                    echo -e "\n\`\`\`\n" >> "$TEMP_FILE" # Assure un saut de ligne avant et après le bloc
                    ;;
                2) # Numéroté
                    echo "=== FICHIER: $file_path ===" >> "$TEMP_FILE"
                    nl -ba "$file_path" >> "$TEMP_FILE" # nl numérote les lignes
                    echo -e "\n" >> "$TEMP_FILE"
                    ;;
                3) # Compact
                    echo "// Fichier: $file_path" >> "$TEMP_FILE" # Commentaire pour indiquer l'origine
                    cat "$file_path" >> "$TEMP_FILE"
                    echo -e "\n" >> "$TEMP_FILE" # Petite séparation entre les contenus de fichiers
                    ;;
                *) # Simple (par défaut, FORMAT_TYPE 0)
                    echo "=== FICHIER: $file_path ===" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    cat "$file_path" >> "$TEMP_FILE"
                    echo -e "\n" >> "$TEMP_FILE"
                    echo "----------------------------------------" >> "$TEMP_FILE"
                    echo -e "\n" >> "$TEMP_FILE"
                    ;;
            esac
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
        else
             gum style --foreground "$RED" "⚠️ Fichier '$file_path' non trouvé ou inaccessible au moment du traitement. Ignoré."
        fi
    done

    if [ "$FILES_PROCESSED" -eq 0 ]; then
        gum style --foreground "$RED" --bold "❌ Aucun fichier n'a pu être traité. Vérifiez les chemins ou permissions."
        # Le trap EXIT s'occupera de rm $TEMP_FILE
        exit 1
    fi

    # Copier dans le presse-papiers avec spinner
    # Le `if` vérifie le code de sortie de la commande `gum spin ...` qui est le code de sortie de `bash -c ...`
    if gum spin --spinner globe --title "Copie dans le presse-papiers..." -- bash -c "cat '$TEMP_FILE' | $CLIPBOARD_CMD"; then
        gum style --foreground "$GREEN" --bold "✅ Succès!"
        gum style --foreground "$BLUE" "$FILES_PROCESSED fichier(s) traité(s) et contenu copié dans le presse-papiers."

        # AMÉLIORATION: Calculer les statistiques une seule fois
        # Utilisation de read pour éviter les espaces superflus de wc et l'appel à awk
        local TOTAL_LINES CHAR_COUNT WORD_COUNT
        read TOTAL_LINES _ < <(wc -l "$TEMP_FILE") # Lit la première valeur de wc -l
        read CHAR_COUNT _ < <(wc -c "$TEMP_FILE") # Lit la première valeur de wc -c
        read WORD_COUNT _ < <(wc -w "$TEMP_FILE") # Lit la première valeur de wc -w


        # Aperçu optionnel
        if gum confirm --default=false "Voir un aperçu du contenu (30 premières lignes) ?"; then
            gum style --foreground "$PURPLE" --border double --padding "1 2" --margin "1 0" "📄 APERÇU"
            # Utiliser sed pour afficher les N premières lignes
            sed -n '1,30p;31q' "$TEMP_FILE" | gum style --foreground "$BLUE" --margin "0 2" # 31q pour sortir après la 30e ligne si plus

            if [ "$TOTAL_LINES" -gt 30 ]; then
                gum style --foreground "$YELLOW" "... et $(($TOTAL_LINES - 30)) lignes supplémentaires."
            fi
            gum style --foreground "$GREEN" --bold "💾 Total: $TOTAL_LINES lignes copiées."
        fi

        # Afficher les statistiques
        gum join --vertical --align center \
            "$(gum style --foreground "$PURPLE" --bold "📊 STATISTIQUES")" \
            "$(gum style --foreground "$BLUE" "Fichiers traités: $FILES_PROCESSED")" \
            "$(gum style --foreground "$BLUE" "Lignes totales: $TOTAL_LINES")" \
            "$(gum style --foreground "$BLUE" "Mots totaux: $WORD_COUNT")" \
            "$(gum style --foreground "$BLUE" "Caractères totaux: $CHAR_COUNT")"

    else
        gum style --foreground "$RED" --bold "❌ Erreur lors de la copie dans le presse-papiers."
        gum style --foreground "$YELLOW" "Le contenu agrégé se trouve dans: $TEMP_FILE"
        gum style --foreground "$YELLOW" "(Ce fichier ne sera pas supprimé automatiquement en cas d'échec de copie)."
        trap - EXIT # Annule le trap pour ne pas supprimer le fichier temporaire
        exit 1
    fi
    # Le trap EXIT s'occupera de rm $TEMP_FILE en cas de succès
}

# Exécuter le script principal en passant tous les arguments reçus par le script
main "$@"
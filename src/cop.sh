#!/bin/bash

# Script interactif pour copier le contenu de plusieurs fichiers dans le presse-papiers
# Utilise Gum pour une interface utilisateur élégante
# Usage: ./copy_files.sh [fichiers...]

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
if command -v xclip >/dev/null 2>&1; then
    CLIPBOARD_CMD="xclip -selection clipboard"
elif command -v pbcopy >/dev/null 2>&1; then
    CLIPBOARD_CMD="pbcopy"
elif command -v clip.exe >/dev/null 2>&1; then
    CLIPBOARD_CMD="clip.exe"
else
    gum style --foreground "$RED" --bold "❌ Aucun utilitaire de presse-papiers trouvé"
    gum style --foreground "$YELLOW" "Installez xclip (Linux), utilisez macOS (pbcopy), ou WSL (clip.exe)"
    exit 1
fi

# Fonction pour afficher le titre
show_header() {
    gum style --foreground "$PURPLE" --border double --align center --width 60 --margin "1 2" --padding "1 2" \
        "📁 COPIEUR DE FICHIERS MULTIPLES" \
        "Powered by Gum ✨"
}

# Fonction pour ajouter un fichier unique à la liste
add_unique_file() {
    local file="$1"
    local -n files_ref="$2"

    # Résoudre le chemin absolu pour éviter les doublons de chemins relatifs/absolus
    local abs_path=$(realpath "$file" 2>/dev/null || echo "$file")

    # Vérifier si le fichier n'est pas déjà dans la liste
    for existing_file in "${files_ref[@]}"; do
        local existing_abs=$(realpath "$existing_file" 2>/dev/null || echo "$existing_file")
        if [ "$abs_path" = "$existing_abs" ]; then
            gum style --foreground "$YELLOW" "⚠️  Fichier déjà sélectionné: $file"
            return 1
        fi
    done

    files_ref+=("$file")
    return 0
}

# Fonction pour sélectionner des fichiers
select_files() {
    local files=()

    if [ $# -gt 0 ]; then
        # Si des fichiers sont passés en arguments, les proposer
        gum style --foreground "$BLUE" "📂 Fichiers fournis en arguments:"
        for file in "$@"; do
            if [ -f "$file" ]; then
                if add_unique_file "$file" files; then
                    gum style --foreground "$GREEN" "  ✓ $file"
                fi
            else
                gum style --foreground "$RED" "  ✗ $file (non trouvé)"
            fi
        done

        if [ ${#files[@]} -gt 0 ]; then
            if gum confirm --default=true "Utiliser ces fichiers ?"; then
                printf '%s\n' "${files[@]}"
                return
            fi
        fi
    fi

    # Sélection interactive de fichiers
    while true; do
        gum style --foreground "$BLUE" --bold "📁 Sélection de fichiers"

        METHOD=$(gum choose --header "Comment voulez-vous sélectionner les fichiers ?" \
            "Navigateur de fichiers" \
            "Filtre par extension" \
            "Entrée manuelle" \
            "Terminer la sélection")

        case "$METHOD" in
            "Navigateur de fichiers")
                FILE=$(gum file --directory .)
                if [ -n "$FILE" ] && [ -f "$FILE" ]; then
                    files+=("$FILE")
                    gum style --foreground "$GREEN" "✓ Ajouté: $FILE"
                fi
                ;;
            "Filtre par extension")
                EXT=$(gum input --placeholder "Extension (ex: js, py, txt)" --prompt "Extension: ")
                if [ -n "$EXT" ]; then
                    # Rechercher les fichiers avec cette extension
                    mapfile -t found_files < <(find . -name "*.${EXT}" -type f 2>/dev/null)
                    if [ ${#found_files[@]} -gt 0 ]; then
                        SELECTED=$(printf '%s\n' "${found_files[@]}" | gum choose --no-limit --header "Sélectionnez les fichiers *.${EXT}")
                        if [ -n "$SELECTED" ]; then
                            while IFS= read -r file; do
                                files+=("$file")
                                gum style --foreground "$GREEN" "✓ Ajouté: $file"
                            done <<< "$SELECTED"
                        fi
                    else
                        gum style --foreground "$YELLOW" "Aucun fichier *.${EXT} trouvé"
                    fi
                fi
                ;;
            "Entrée manuelle")
                FILE=$(gum input --placeholder "Chemin du fichier" --prompt "Fichier: ")
                if [ -n "$FILE" ]; then
                    if [ -f "$FILE" ]; then
                        files+=("$FILE")
                        gum style --foreground "$GREEN" "✓ Ajouté: $FILE"
                    else
                        gum style --foreground "$RED" "✗ Fichier non trouvé: $FILE"
                    fi
                fi
                ;;
            "Terminer la sélection")
                break
                ;;
        esac

        if [ ${#files[@]} -gt 0 ]; then
            gum style --foreground "$BLUE" --bold "📋 Fichiers sélectionnés (${#files[@]}):"
            printf '%s\n' "${files[@]}" | gum style --foreground "$GREEN" --margin "0 2"
        fi
    done

    printf '%s\n' "${files[@]}"
}

# Fonction pour formater le contenu
format_content() {
    local temp_file="$1"
    local format_choice

    format_choice=$(gum choose --header "Choisissez le format de sortie:" \
        "Simple (avec séparateurs)" \
        "Markdown (avec blocs de code)" \
        "Numéroté (avec numéros de ligne)" \
        "Compact (sans séparateurs)")

    case "$format_choice" in
        "Markdown (avec blocs de code)")
            return 1  # Signal pour format markdown
            ;;
        "Numéroté (avec numéros de ligne)")
            return 2  # Signal pour format numéroté
            ;;
        "Compact (sans séparateurs)")
            return 3  # Signal pour format compact
            ;;
        *)
            return 0  # Format simple par défaut
            ;;
    esac
}

# Fonction principale
main() {
    show_header

    # Sélectionner les fichiers
    mapfile -t selected_files < <(select_files "$@")

    if [ ${#selected_files[@]} -eq 0 ]; then
        gum style --foreground "$YELLOW" "⚠️  Aucun fichier sélectionné. Arrêt du script."
        exit 0
    fi

    # Choisir le format
    format_content ""
    FORMAT_TYPE=$?

    # Fichier temporaire
    TEMP_FILE=$(mktemp)
    trap 'rm -f "$TEMP_FILE"' EXIT

    # Traitement avec spinner
    gum spin --spinner dot --title "Traitement des fichiers..." -- sleep 1

    FILES_PROCESSED=0

    for file in "${selected_files[@]}"; do
        if [ -f "$file" ]; then
            case $FORMAT_TYPE in
                1) # Markdown
                    echo "\`\`\`$(basename "$file" | sed 's/.*\.//')" >> "$TEMP_FILE"
                    echo "// Fichier: $file" >> "$TEMP_FILE"
                    cat "$file" >> "$TEMP_FILE"
                    echo "\`\`\`" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    ;;
                2) # Numéroté
                    echo "=== FICHIER: $file ===" >> "$TEMP_FILE"
                    nl -ba "$file" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    ;;
                3) # Compact
                    echo "// $file" >> "$TEMP_FILE"
                    cat "$file" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    ;;
                *) # Simple
                    echo "=== FICHIER: $file ===" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    cat "$file" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    echo "----------------------------------------" >> "$TEMP_FILE"
                    echo "" >> "$TEMP_FILE"
                    ;;
            esac
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
        fi
    done

    # Copier dans le presse-papiers avec spinner
    if gum spin --spinner globe --title "Copie dans le presse-papiers..." -- bash -c "cat '$TEMP_FILE' | $CLIPBOARD_CMD"; then
        gum style --foreground "$GREEN" --bold "✅ Succès!"
        gum style --foreground "$BLUE" "$FILES_PROCESSED fichier(s) copié(s) dans le presse-papiers"

        # Aperçu optionnel
        if gum confirm --default=false "Voir un aperçu du contenu ?"; then
            gum style --foreground "$PURPLE" --border double --padding "1 2" --margin "1 0" "📄 APERÇU"
            head -30 "$TEMP_FILE" | gum style --foreground "$BLUE" --margin "0 2"

            TOTAL_LINES=$(wc -l < "$TEMP_FILE")
            if [ "$TOTAL_LINES" -gt 30 ]; then
                gum style --foreground "$YELLOW" "... ($(($TOTAL_LINES - 30)) lignes supplémentaires)"
            fi

            gum style --foreground "$GREEN" --bold "💾 Total: $TOTAL_LINES lignes copiées"
        fi

        # Statistiques
        CHAR_COUNT=$(wc -c < "$TEMP_FILE")
        WORD_COUNT=$(wc -w < "$TEMP_FILE")

        gum join --vertical \
            "$(gum style --foreground "$PURPLE" --bold "📊 STATISTIQUES")" \
            "$(gum style --foreground "$BLUE" "Fichiers: $FILES_PROCESSED")" \
            "$(gum style --foreground "$BLUE" "Lignes: $(wc -l < "$TEMP_FILE")")" \
            "$(gum style --foreground "$BLUE" "Mots: $WORD_COUNT")" \
            "$(gum style --foreground "$BLUE" "Caractères: $CHAR_COUNT")"

    else
        gum style --foreground "$RED" --bold "❌ Erreur lors de la copie dans le presse-papiers"
        exit 1
    fi
}

# Exécuter le script principal
main "$@"

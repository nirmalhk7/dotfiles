#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting dotfiles installation...${NC}"

# Define directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# 1. Create backup directory
echo -e "${YELLOW}Creating backup at ${BACKUP_DIR}${NC}"
mkdir -p "$BACKUP_DIR"

# 2. Files to symlink (Source in repo : Target in Home)
declare -A FILES_TO_LINK=(
    ["zsh/.zshrc"]="$HOME/.zshrc"
    ["git/.gitconfig"]="$HOME/.gitconfig"
)

for src in "${!FILES_TO_LINK[@]}"; do
    target="${FILES_TO_LINK[$src]}"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$BACKUP_DIR/"
    fi
    
    echo -e "${GREEN}Linking $src to $target${NC}"
    ln -sf "$DOTFILES_DIR/$src" "$target"
done

# 3. Handle Custom Zsh Theme
THEME_SRC="$DOTFILES_DIR/zsh/nirmalhk7.zsh-theme"
THEME_DST="$HOME/.zprezto/modules/prompt/functions/prompt_nirmalhk7_setup"

if [ -f "$THEME_SRC" ]; then
    if [ -d "$(dirname "$THEME_DST")" ]; then
        if [ -e "$THEME_DST" ] || [ -L "$THEME_DST" ]; then
             mv "$THEME_DST" "$BACKUP_DIR/"
        fi
        echo -e "${GREEN}Linking custom theme to Prezto...${NC}"
        ln -sf "$THEME_SRC" "$THEME_DST"
    else
        echo -e "${YELLOW}Warning: Prezto theme directory not found. Skipping theme link.${NC}"
    fi
fi

# 4. Cleanup temporary bridge files
if [ -L "$DOTFILES_DIR/nirmalhk7.zsh-theme" ]; then
    rm "$DOTFILES_DIR/nirmalhk7.zsh-theme"
fi
if [ -f "$DOTFILES_DIR/nirmalhk7.sh" ]; then
    rm "$DOTFILES_DIR/nirmalhk7.sh"
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${YELLOW}Action Required: Run 'source ~/.zshrc' or restart your terminal.${NC}"
echo -e "${BLUE}==========================================${NC}"

#!/bin/bash

if [ -n "$ZSH_VERSION" ]; then
    echo "Running in Zsh..."
    shell="zsh"
elif [ -n "$BASH_VERSION" ]; then
    echo "Running in Bash..."
    shell="bash"
else
    echo "This script should be run in Bash or Zsh."
    exit 1
fi

printf "\n========================================\n"
printf "(Anaconda/Miniconda) Removal Script\n"
printf "========================================\n\n"

read -p "Are you uninstalling Anaconda or Miniconda? (a/m): " version

if [[ "$version" == "a" ]]; then
    install_dir="$HOME/anaconda3"
    alt_install_dir="$HOME/opt/anaconda3"
    sudo_install_dir="/opt/anaconda3"
elif [[ "$version" == "m" ]]; then
    install_dir="$HOME/miniconda3"
    alt_install_dir="$HOME/opt/miniconda3"
    sudo_install_dir="/opt/miniconda3"
else
    echo "Invalid input. Please run the script again and choose 'a' for Anaconda or 'm' for Miniconda."
    exit 1
fi

# Safely remove file/dir
safe_remove() {
    if [ -e "$1" ]; then
        rm -rf "$1"
        printf "Removed $1\n"
    else
        printf "$1 does not exist, skipping...\n"
    fi
}

# Step 1: Deactivate Conda
printf "\n[Step 1] Removing conda initialization scripts...\n"
if command -v conda &> /dev/null; then
    conda activate
    conda init --reverse --all
    printf "Conda initialization scripts reversed.\n"
else
    printf "conda command not found, skipping deactivation.\n"
fi

# Remove Anaconda/Miniconda dirs
printf "\n[Step 2] Removing Anaconda/Miniconda directories...\n"
safe_remove "$install_dir"
safe_remove "$alt_install_dir"
sudo $shell -c "$(declare -f safe_remove); safe_remove '$sudo_install_dir'"

# Remove Conda-related files
printf "\n[Step 3] Removing Conda-related files...\n"
safe_remove "$HOME/.condarc"
safe_remove "$HOME/.conda"
safe_remove "$HOME/.continuum"

# Backup and remove Anaconda-related PATH entries
printf "\n[Step 4] Removing Anaconda/Miniconda from PATH...\n"
for file in "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.profile"; do
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if grep -q '# >>> conda initialize >>>' "$file"; then
                sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file"
                printf "Removed invasive conda PATH manipulation in $file\n"
            else
                printf "Conda PATH manipulation not found in $file, no update needed :)\n"
            fi
        else
            if grep -q '# >>> conda initialize >>>' "$file"; then
                sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$file"
                printf "Removed invasive conda PATH manipulation in $file\n"
            else
                printf "Conda PATH manipulation not found in $file, no update needed :)\n"
            fi
        fi
    else
        printf "$file does not exist, skipping...\n"
    fi
done

# Source the updated configuration files only if in the corresponding shell
printf "\n[Step 5] Sourcing updated configuration files...\n"
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bash_profile" ]; then source "$HOME/.bash_profile"; fi
    if [ -f "$HOME/.bashrc" ]; then source "$HOME/.bashrc"; fi
    if [ -f "$HOME/.profile" ]; then source "$HOME/.profile"; fi
elif [ -n "$ZSH_VERSION" ]; then
    if [ -f "$HOME/.zshrc" ]; then source "$HOME/.zshrc"; fi
    if [ -f "$HOME/.zprofile" ]; then source "$HOME/.zprofile"; fi
fi

# Remove the conda command
printf "\n[Step 6] Removing conda command...\n"
if command -v conda &> /dev/null; then
    conda clean --all --yes
    sudo $shell -c "$(declare -f safe_remove); safe_remove '/usr/local/bin/conda'"
    printf "Removed conda\n"
else
    printf "conda command not found, skipping...\n"
fi

# Remove Anaconda Navigator
printf "\n[Step 7] Removing Anaconda Navigator...\n"
safe_remove "$HOME/Library/Application Support/Anaconda"
safe_remove "$HOME/Library/Application Support/Anaconda Navigator"

# Remove Jupyter configurations
printf "\n[Step 8] Removing Jupyter configurations...\n"
safe_remove "$HOME/.jupyter"
safe_remove "$HOME/Library/Jupyter"

printf "\n================================================================================\n"
printf "(Anaconda/Miniconda) has been completely removed from your system. Congrats!\n"
printf "Please restart your terminal to apply all changes.\n"
printf "================================================================================\n"

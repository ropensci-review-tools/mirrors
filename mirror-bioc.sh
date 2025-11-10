#!/bin/bash

NC='\033[0m'
# RED='\033[0;31m' # red
GRN='\033[0;32m' # green, or 1;32m for light green
YEL='\033[0;33m'
ARR='\u2192' # right arrow
DASH='\u2014'

echo -e "${YEL}${DASH}${DASH}${ARR}  ${NC}Enter/Default: Stable releases${NC}"
echo -e "${YEL}${DASH}${DASH}${ARR}  ${NC}Anything else: Unstable dev versions${NC}"

doit() {
    echo -e -n "${YEL}Proceed to update $1 (y/n)?${NC} "
    read DOIT
    if [ "$DOIT" != "y" ]; then
        echo -e "${YEL}Stopping update${NC}"
        exit 0
    fi
}

echo -e -n "${YEL}Enter option:${NC} "
read OPT

if [[ -z "$OPT"  ]]; then
    doit "Stable, release versions of all Bioc repos"
else
    doit "Unstable, development versions of all Bioc repos"
fi

Rscript "mirror-bioc.R"

# Stuff to make this work in cron
PATH="/bin:/usr/bin:/usr/local/bin:$PATH"  #Provide the path
# cd "${0%/*}"       #Set working directory to location of this script

set -e  # stop script if error

JSON_FILE="bioc-packages.json"
REGISTRY_DIR="bioc"

mkdir -p "$REGISTRY_DIR"

if [[ -z "$OPT" ]]; then
    repos=$(jq -r '.[] | .url_bioc' "$JSON_FILE")
else
    repos=$(jq -r '.[] | .url' "$JSON_FILE")
fi

readarray -t repo_urls <<< "$repos"

# Clone each repository
for url in "${repo_urls[@]}"; do
    repo_name=$(basename "$url")

    if [[ -d "$REGISTRY_DIR/$repo_name" ]] && [[ -n $(find "$REGISTRY_DIR/$repo_name" -maxdepth 0 -mtime +7) ]]; then
        echo "Updating $url... as $REGISTRY_DIR/$repo_name"
        { cd "$REGISTRY_DIR/$repo_name"; git pull; cd ../..; } || { echo "Failed to enter directory $REGISTRY_DIR/$repo_name"; continue; }
    elif [[ ! -d "$REGISTRY_DIR/$repo_name" ]]; then
        if curl --output /dev/null --silent --head --fail "$url"; then
            echo "Cloning $url as $REGISTRY_DIR/$repo_name"
            git clone "$url" "$REGISTRY_DIR/$repo_name"
        else
            echo "URL $url can not be reached."
        fi
    else
        echo "Skipping $url, already up-to-date"
    fi

    # Update submodules if they exist
    if [[ -d "$REGISTRY_DIR/$repo_name/.git/modules" ]] && [[ -n $(find "$REGISTRY_DIR/$repo_name" -maxdepth 0 -mtime +7) ]]; then
        cd "$REGISTRY_DIR/$repo_name" || { echo "Failed to enter directory $REGISTRY_DIR/$repo_name"; continue; }
        git submodule update --init --recursive
    fi

    echo ""
done

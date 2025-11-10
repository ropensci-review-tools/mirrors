#!/bin/bash

Rscript "mirror-bioc.R"

# Stuff to make this work in cron
PATH="/bin:/usr/bin:/usr/local/bin:$PATH"  #Provide the path
# cd "${0%/*}"       #Set working directory to location of this script

set -e  # stop script if error

JSON_FILE="bioc-packages.json"
REGISTRY_DIR="bioc"

mkdir -p "$REGISTRY_DIR"

repos=$(jq -r '.[] | .url' "$JSON_FILE")

readarray -t repo_urls <<< "$repos"

# Clone each repository
for url in "${repo_urls[@]}"; do
    repo_name=$(basename "$url")

    if [ -d "$REGISTRY_DIR/$repo_name" ]; then
        echo "Updating $url... as $REGISTRY_DIR/$repo_name"
        { cd "$REGISTRY_DIR/$repo_name"; git pull; cd ../..; } || { echo "Failed to enter directory $REGISTRY_DIR/$repo_name"; continue; }
    else
        echo "Cloning $url as $REGISTRY_DIR/$repo_name"
        git clone "$url" "$REGISTRY_DIR/$repo_name"
    fi

    # Update submodules if they exist
    if [ -d "$REGISTRY_DIR/$repo_name/.git/modules" ]; then
        cd "$REGISTRY_DIR/$repo_name" || { echo "Failed to enter directory $REGISTRY_DIR/$repo_name"; continue; }
        git submodule update --init --recursive
    fi

    echo ""
done

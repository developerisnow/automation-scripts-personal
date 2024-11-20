#!/bin/bash

# Check if parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: sh renameFolders.sh --suffix <suffix> OR --prefix <prefix>"
    exit 1
fi

# Process based on flag type
case "$1" in
    --suffix)
        if [ -n "$2" ]; then
            # Loop through all directories in current path (depth 1)
            for dir in */; do
                if [ -d "$dir" ]; then
                    dirname=${dir%/}
                    if [[ ! "$dirname" == *"-$2" ]]; then
                        mv "$dirname" "$dirname-$2"
                    fi
                fi
            done
        fi
        ;;
    --prefix)
        if [ -n "$2" ]; then
            # Loop through all directories in current path (depth 1)
            for dir in */; do
                if [ -d "$dir" ]; then
                    dirname=${dir%/}
                    if [[ ! "$dirname" == "$2-"* ]]; then
                        mv "$dirname" "$2-$dirname"
                    fi
                fi
            done
        fi
        ;;
    *)
        echo "Usage: sh renameFolders.sh --suffix <suffix> OR --prefix <prefix>"
        exit 1
        ;;
esac
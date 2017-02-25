#!/bin/bash
set -e

# this script can be replaced by lddtree one pax-utils went stable

if [ "$#" -ne 2 ] ; then
    echo "need executable and dest"
fi

EXECUTABLE=$1
DEST_DIR=$2

if [ -e "$EXECUTABLE" ] && [ -f "$EXECUTABLE" ] && [ -e "$DEST_DIR" ] && [ -d "$DEST_DIR" ]; then
    if ! [ -e "$DEST_DIR$EXECUTABLE" ] ; then
        ldd "$EXECUTABLE" | sed 's/[^\/]*\/\(.*\) .*/\/\1/' | \
        while read library
        do
            echo "library: " $library
            bash $0 $library $DEST_DIR
        done
        echo "copying executable $EXECUTABLE"
        cp "$EXECUTABLE" "$DEST_DIR$EXECUTABLE"

    fi
fi


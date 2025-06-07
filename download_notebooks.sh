#!/bin/bash

ip=( "$(terraform output -raw driver_ip)" )

REMOTE_USER="debian"       
REMOTE_HOST=( "$(terraform output -raw driver_ip)" )
REMOTE_NOTEBOOK_DIR="~/notebooks"          # or ~/notebooks, /home/user, etc.
LOCAL_DEST="/home/pzero/python/pdd/zad2/notebooks"

# --- Execution ---


scp -i .ssh/id_ed25519 -r "$REMOTE_USER@$REMOTE_HOST:$REMOTE_NOTEBOOK_DIR/*.ipynb" "$LOCAL_DEST"

echo "Download complete. Notebooks saved to $LOCAL_DEST"


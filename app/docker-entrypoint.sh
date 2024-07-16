#!/bin/sh

# Path to your home.tmpl file
HOME_TMPL_PATH="/app/home.tmpl"

# Check if ADD_TARGET_BLANK is set to "true" and if target="_blank" is not already present
if [ "$ADD_TARGET_BLANK" = "true" ] && ! grep -q 'class="text-decoration-none text-secondary" target="_blank"' "$HOME_TMPL_PATH"; then
    sed -i 's/class="text-decoration-none text-secondary"/class="text-decoration-none text-secondary" target="_blank"/g' "$HOME_TMPL_PATH"
fi

nginx&
docker-gen -watch -include-stopped /app/home.tmpl /usr/share/nginx/html/index.html

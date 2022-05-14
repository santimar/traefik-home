#!/bin/sh

nginx&
docker-gen -watch -include-stopped /app/home.tmpl /usr/share/nginx/html/index.html

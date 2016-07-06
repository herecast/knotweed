#!/usr/bin/env bash

export RAILS_ROOT=/sphinx_shared
sphinx_db_path=/sphinx_shared/db/sphinx/
conf_file=/sphinx_shared/config/production.sphinx.conf
ip=$(ip addr list dev eth0 | awk '/inet / { gsub(/\/.*/, "", $2); print $2 }')

# wait for ts:configure in the other container to create the config file
# use grep to handle the case that the config file is "stale" and contains
# an IP for an old container
while ! grep -q "${ip}:9608" "$conf_file" 2>/dev/null; do
    sleep 1
done

shopt -s nullglob dotglob
db_files=("$sphinx_db_path"/*)

# index if this is the first time we have ran sphinx on this volume
if (( ${#db_files[@]} < 1 )); then
    /indexing/full_index.sh
    /indexing/delta_index.sh
fi

exec searchd --nodetach --config "$conf_file"

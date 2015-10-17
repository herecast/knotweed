#!/bin/bash
#
# Runs a full index and creates a temporary file while the index is running.
# Outputs to #{Rails.root}/log/cron.log.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$( cd ../.. && pwd)"
LOG_FILE="$RAILS_ROOT/log/cron.log"

exec touch "$RAILS_ROOT/tmp/indexing"
echo "$(date): beginning full index" >> $LOG_FILE
exec /usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf content_core business_location_core event_instance_core location_core publication_core --sighup-each --rotate >> $LOG_FILE
exec rm "$RAILS_ROOT/tmp/indexing"
exit 0

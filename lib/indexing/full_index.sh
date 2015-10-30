#!/bin/bash
#
# Runs a full index and creates a temporary file while the index is running.
# Outputs to #{Rails.root}/log/cron.log.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$SCRIPT_DIR/../.."
LOG_FILE="$RAILS_ROOT/log/cron.log"

touch $RAILS_ROOT/tmp/indexing.lock
echo "$(date): beginning full index" >> $LOG_FILE
/usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf content_core business_location_core event_instance_core location_core publication_core --sighup-each --rotate >> $LOG_FILE
rm $RAILS_ROOT/tmp/indexing.lock
exit 0

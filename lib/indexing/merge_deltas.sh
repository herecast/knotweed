#!/bin/bash
#
# Merges delta indices into main index. Does not run if
# the file $RAILS_ROOT/tmp/indexing is present because that
# is a mark that a full index is ongoing.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$SCRIPT_DIR/../.."
LOG_FILE="$RAILS_ROOT/log/cron.log"

if [ -f $RAILS_ROOT/tmp/indexing ]; then
  echo "$(date): Not merging because an indexer is in process. If you're sure it's not, remove $RAILS_ROOT/tmp/indexing" >> $LOG_FILE
  exit 1
else
  echo "$(date): Merging event instance delta index." >> $LOG_FILE
  /usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf --merge event_instance_core event_instance_delta --rotate >> $LOG_FILE
  echo "$(date): Merging content delta index." >> $LOG_FILE
  /usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf --merge content_core content_delta --rotate >> $LOG_FILE
  exit 0
fi

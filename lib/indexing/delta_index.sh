#!/bin/bash
#
# Rotates delta indices. This cron job runs every minute.
# Outputs to #{Rails.root}/log/cron.log.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$SCRIPT_DIR/../.."
LOG_FILE="$RAILS_ROOT/log/cron.log"

if [ -f $RAILS_ROOT/tmp/merging.lock ]; then
  echo "$(date): Skipping delta index because merging is in process. If you're sure it's not, remove $RAILS_ROOT/tmp/merging.lock" >> $LOG_FILE
  exit 1
else
  echo "$(date): indexing delta indices" >> $LOG_FILE
  /usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf content_delta event_instance_delta --rotate >> $LOG_FILE
  exit 0
fi

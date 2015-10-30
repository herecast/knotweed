#!/bin/bash
#
# Rotates delta indices. This cron job runs every minute.
# Outputs to #{Rails.root}/log/cron.log.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$SCRIPT_DIR/../.."
LOG_FILE="$RAILS_ROOT/log/cron.log"

echo "$(date): indexing delta indices" >> $LOG_FILE
/usr/bin/indexer -c $RAILS_ROOT/config/production.sphinx.conf content_delta event_instance_delta business_location_delta --rotate >> $LOG_FILE
exit 0

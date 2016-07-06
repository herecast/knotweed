#!/bin/bash
#
# Rotates delta indices. This cron job runs every minute.
# Outputs to #{Rails.root}/log/cron.log.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="${RAILS_ROOT:-$SCRIPT_DIR/../..}"
LOG_FILE="$RAILS_ROOT/log/cron.log"
INDEXTOOL_LOG="$RAILS_ROOT/log/indextool.log"
CONFIG_FILE="$RAILS_ROOT/config/production.sphinx.conf"

mkdir -p "$RAILS_ROOT/tmp"
mkdir -p "$RAILS_ROOT/log"

if [ -f $RAILS_ROOT/tmp/merging.lock ]; then
  echo "$(date): Skipping delta index because merging is in process. If you're sure it's not, remove $RAILS_ROOT/tmp/merging.lock" >> $LOG_FILE
  exit 1
elif [ -f $RAILS_ROOT/tmp/delta_indexing.lock ]; then
  echo "$(date): Skipping delta index because previous delta is still in process. If you're sure it's not, remove $RAILS_ROOT/tmp/delta_indexing.lock" >> $LOG_FILE
  exit 1
else
  echo "$(date): indexing delta indices" >> $LOG_FILE
  touch $RAILS_ROOT/tmp/delta_indexing.lock
  /usr/bin/indexer -c $CONFIG_FILE content_delta event_instance_delta business_location_delta business_profile_delta --rotate >> $LOG_FILE
  sleep 2
  echo "$(date): checking delta indices" >> $INDEXTOOL_LOG
  /usr/bin/indextool -c $CONFIG_FILE --check content_delta >> $INDEXTOOL_LOG
  /usr/bin/indextool -c $CONFIG_FILE --check event_instance_delta >> $INDEXTOOL_LOG
  /usr/bin/indextool -c $CONFIG_FILE --check business_location_delta >> $INDEXTOOL_LOG
  /usr/bin/indextool -c $CONFIG_FILE --check business_profile_delta >> $INDEXTOOL_LOG
  rm $RAILS_ROOT/tmp/delta_indexing.lock
  exit 0
fi

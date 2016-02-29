#!/bin/bash
#
# Merges delta indices into main index. Does not run if
# the file $RAILS_ROOT/tmp/indexing.lock is present because that
# is a mark that a full index is ongoing.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAILS_ROOT="$SCRIPT_DIR/../.."
LOG_FILE="$RAILS_ROOT/log/cron.log"
INDEXTOOL_LOG="$RAILS_ROOT/log/indextool.log"
CONFIG_FILE="$RAILS_ROOT/config/production.sphinx.conf"

if [ -f $RAILS_ROOT/tmp/indexing.lock ]; then
  echo "$(date): Not merging because an indexer is in process. If you're sure it's not, remove $RAILS_ROOT/tmp/indexing.lock" >> $LOG_FILE
  exit 1
else
  # touch immediately to prevent any other indexers from starting
  touch $RAILS_ROOT/tmp/merging.lock
  # wait for any pending deltas to complete before starting
  if [ -f $RAILS_ROOT/tmp/delta_indexing.lock ]; then
    echo "$(date): waiting up to 100 seconds for $RAILS_ROOT/tmp/delta_indexing.lock to clear" >> $LOG_FILE
  fi
  x=0
  while [ "$x" -lt 100 -a -e $RAILS_ROOT/tmp/delta_indexing.lock ]; do
    x=$((x+1))
    sleep 1 
  done
  # if indexing lock file is still present after waiting 100 seconds, exit without merging
  if [ -f $RAILS_ROOT/tmp/delta_indexing.lock ]; then
    echo "$(date): Not merging because delta index still in process after waiting 100 seconds. If you're sure it's not, remove $RAILS_ROOT/tmp/delta_indexing.lock" >> $LOG_FILE
    rm $RAILS_ROOT/tmp/merging.lock
    exit 1
  else
    echo "$(date): Merging event instance delta index." >> $LOG_FILE
    /usr/bin/indexer -c $CONFIG_FILE --merge event_instance_core event_instance_delta --rotate >> $LOG_FILE
    echo "$(date): Checking event_instance_core" >> $INDEXTOOL_LOG
    /usr/bin/indextool -c $CONFIG_FILE --check event_instance_core >> $INDEXTOOL_LOG
    echo "$(date): Merging content delta index." >> $LOG_FILE
    /usr/bin/indexer -c $CONFIG_FILE --merge content_core content_delta --rotate >> $LOG_FILE
    echo "$(date): Checking content_core" >> $INDEXTOOL_LOG
    /usr/bin/indextool -c $CONFIG_FILE --check content_core  >> $INDEXTOOL_LOG
    echo "$(date): Merging business_location delta index." >> $LOG_FILE
    /usr/bin/indexer -c $CONFIG_FILE --merge business_location_core business_location_delta --rotate >> $LOG_FILE
    echo "$(date): Checking business_location_core" >> $INDEXTOOL_LOG
    /usr/bin/indextool -c $CONFIG_FILE --check business_location_core >> $INDEXTOOL_LOG
    echo "$(date): Merging business_profile delta index." >> $LOG_FILE
    /usr/bin/indexer -c $CONFIG_FILE --merge business_profile_core business_profile_delta --rotate >> $LOG_FILE
    echo "$(date): Checking business_profile_core" >> $INDEXTOOL_LOG
    /usr/bin/indextool -c $CONFIG_FILE --check business_profile_core >> $INDEXTOOL_LOG
    rm $RAILS_ROOT/tmp/merging.lock
    exit 0
  fi
fi

#!/bin/bash

/root/run &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start /root/run: $status"
  exit $status
fi

/root/dropbox-whitelist-selective-sync.sh /dbox/Dropbox &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start /root/dropbox-whitelist-selective-sync.sh: $status"
  exit $status
fi

while sleep 60; do
  PID1=`pidof dropbox`
  PID2=`echo $(pgrep -f dropbox-whitelist-selective-sync.sh) | cut -d' ' -f1`

  if [ -z $PID1 -o -z $PID2 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done

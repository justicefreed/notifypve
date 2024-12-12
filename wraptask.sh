#!/bin/bash

TASKNAME="$1"
shift;
TASKCMD="$@"

LOGFILE=$(mktemp || "/dev/null")
trap 'rm -f -- "$LOGFILE"' EXIT

{
    echo "Starting Task: $TASKNAME"
    echo "Running Command: $TASKCMD"
    ${TASKCMD}
    RETVAL=$?
    echo "Task exited with code $RETVAL"
    exit $RETVAL
} |& ts '[%Y-%m-%d %H:%M:%S]' |& tee -a "$LOGFILE"
RETVAL=${PIPESTATUS[0]}

HOSTNAME=$(hostname)
if [ $RETVAL -ne 0 ]; then
    notifypve -e -f "$LOGFILE" "ERROR from $HOSTNAME - Task $TASKNAME Failed"
else
    notifypve -i -f "$LOGFILE" "INFO from $HOSTNAME - Task $TASKNAME Succeeded"
fi

rm -f -- "$LOGFILE"
trap - EXIT
exit 0

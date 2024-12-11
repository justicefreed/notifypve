#!/bin/bash

_TASKNAME="$1"
shift;
_TASKCMD="$@"

_LOGFILE=$(mktemp || "/dev/null")
trap 'rm -f -- "$_LOGFILE"' EXIT

echo "Starting Task: $_TASKNAME" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a "$_LOGFILE" 2>&1
echo "Running Command: $_TASKCMD" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a "$_LOGFILE" 2>&1

${_TASKCMD} | ts '[%Y-%m-%d %H:%M:%S]' | tee -a "$_LOGFILE" 2>&1
_RETVAL=$?

echo "Task exited with code $_RETVAL" | ts '[%Y-%m-%d %H:%M:%S]' | tee -a "$_LOGFILE" 2>&1


LOG="$(iconv -f ASCII -t UTF-8 $_LOGFILE)"

_HOSTNAME=$(hostname)
if [ $_RETVAL -ne 0 ]; then
    notifypve -e -m "$LOG" "ERROR from $_HOSTNAME - Task $_TASKNAME Failed"
else
    notifypve -i -m "$LOG" "INFO from $_HOSTNAME - Task $_TASKNAME Succeeded"
fi

rm -f -- "$_LOGFILE"
trap - EXIT
exit 0

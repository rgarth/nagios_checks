#!/usr/bin/env bash
# Author: Rob Garth <rgarth@linuxfoundation.org>
# Nagios Exit Codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

usage()
{
cat <<EOF
Check the number of open connections from a unique address
  Options:
    -e 	      Regex to filter netcat results for e.g. ':80\|:443'
    -p <type> Set protocol or family type (udp/tcp)
    -c        Critical threshold as an integer
    -w        Warning threshold as an integer
Usage: $0 -e ':80\|443' -p tcp -w 30 -c 60
EOF
}

argcheck() {
# if less than n argument
if [ $ARGC -lt $1 ]; then
  echo "Missing arguments! Use \`\`-h'' for help."
  exit 1
fi
}

# Define now to prevent expected number errors
OPTERR=0
PROTO=tcp
CRIT=80
WARN=50
ARGC=$#
REGEX=$PROTO

while getopts ":hc:p:w:e:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 0
      ;;
    p)
      PROTO="$OPTARG"
      ;;
    e)
      REGEX="$OPTARG"
      ;;
    c)
      CRIT="$OPTARG"
      ;;
    w)
      WARN="$OPTARG"
      ;;
    \?)
      ;;
  esac
done

read COUNT IP_ADDR <<< $( netstat --${PROTO} -n 2>/dev/null | grep "$REGEX" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -1 )
[ -z $COUNT ] && COUNT=0 && IP_ADDR="0.0.0.0"

if [ $COUNT -gt $CRIT ]; then
  echo "CRITICAL - $COUNT open $PROTO connections from $IP_ADDR | connections=$COUNT;$WARN;$CRIT"
  exit $CRITICAL
elif [ $COUNT -gt $WARN ]; then
  echo "WARNING - $COUNT open $PROTO connections from $IP_ADDR | connections=$COUNT;$WARN;$CRIT"
  exit $WARNING
else
  echo "OK - $COUNT open $PROTO connections from $IP_ADDR | connections=$COUNT;$WARN;$CRIT"
  exit $OK
fi

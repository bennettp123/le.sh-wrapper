#!/bin/bash

function usage {
  echo "Usage: $(basename $0) -f <config_file> [-d <letsencypt_dir>]" 
}

ERR=0

CONF_FILE_ARG=''
LEDIR_ARG=''
VERBOSE_ARG=''
while getopts 'vf:d:' opt; do
  case "$opt" in
  v) VERBOSE_ARG=1
     ;;
  f) CONF_FILE_ARG="$OPTARG"
     ;;
  d) LEDIR_ARG="$OPTARG"
     ;;
  *) usage >&2
     exit 1
     ;;
  esac
done

VERBOSE="${VERBOSE_ARG:-${VERBOSE:-0}}"
CONF_FILE="${CONF_FILE_ARG:-${CONF_FILE:-"$(dirname "$(perl -MCwd -le 'print Cwd::abs_path(shift)' "$0")")/do-le.conf"}}"

if [ ! -r "$CONF_FILE" ]; then
 ERR=1
 echo "Error reading config file $CONF_FILE" >&2
 echo "  (Hint: specify config file using: -f <conf_file>)" >&2
 usage >&2
 exit 1
fi

[ -r "$CONF_FILE" ] && . "$CONF_FILE"

LOGFILE="${LOGFILE:-$(mktemp)}"

function cleanup {
  # if there was an error, or if VERBOSE, print logfile to stdout. Otherwise, be quiet.
  if [ $ERR -gt 0 ] || [ $VERBOSE -gt 0 ]; then cat "${LOGFILE}" >&3 2>&1; fi
  rm -f "$LOGFILE"
}
trap cleanup EXIT

# send output to logfile and syslog
exec 3>&1 1> >(exec tee "$LOGFILE" >(exec logger -t "$(basename "$0")") >/dev/null) 2>&1

LEDIR="${LEDIR_ARG:-${LEDIR:-/opt/letsencrypt}}"
if [ ! -x "$LEDIR" ]; then
  ERR=1
  echo "Let's Encrypt basedir not found: $LEDIR" >&2
  echo "  (Hint: specify using -d <ledir> or LEDIR)" >&2
  usage >&2
  exit 1
fi

CF_DNS_SERVERS="$CF_DNS_SERVERS" \
  CF_EMAIL="$CF_EMAIL" \
  CF_KEY="$CF_KEY" \
  OCSP_RESPONSE_FILE="$OCSP_RESPONSE_FILE" \
  http_proxy="$http_proxy" \
  "${LEDIR}/letsencrypt.sh" --cron
ERR=$((ERR+$?))

find "${LEDIR}" -type f -exec chmod o-rwx '{}' \; -exec chmod g+r  '{}' \;
ERR=$((ERR+$?))
find "${LEDIR}" -type d -exec chmod o-rwx '{}' \; -exec chmod g+rx '{}' \;
ERR=$((ERR+$?))

"${LEDIR}/letsencrypt.sh" --cleanup
ERR=$((ERR+$?))

exit ${ERR}

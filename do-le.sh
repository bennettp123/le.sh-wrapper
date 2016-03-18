#!/bin/bash

CONF_FILE="${CONF_FILE:-"$(dirname "$(perl -MCwd -le 'print Cwd::abs_path(shift)' "$0")")/do-le.conf"}"
LOGFILE="${LOGFILE:-$(mktemp)}"
exec 3>&1 1>>"${LOGFILE}" 2>&1

ERR=0

CF_DNS_SERVERS="${CF_DNS_SERVERS:-"$(grep CF_DNS_SERVERS "${CONF_FILE}" | sed 's/^.*CF_DNS_SERVERS=//')"}"
CF_EMAIL="${CF_EMAIL:-"$(grep CF_EMAIL "${CONF_FILE}" | sed 's/^.*CF_EMAIL=//')"}"
CF_KEY="${CF_KEY:-"$(grep CF_KEY "${CONF_FILE}" | sed 's/^.*CF_KEY=//')"}"
LEDIR="${LEDIR:-"$(grep LEDIR "${CONF_FILE}" | sed 's/^.*LEDIR=//')"}"
OCSP_RESPONSE_FILE="${OCSP_RESPONSE_FILE:-"$(grep OCSP_RESPONSE_FILE "${CONF_FILE}" | sed 's/^.*OCSP_RESPONSE_FILE=//')"}"
http_proxy="${http_proxy:-"$(grep http_proxy "${CONF_FILE}" | sed 's/^.*http_proxy=//')"}"

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

if [ $ERR -gt 0 ]; then
    cat "${LOGFILE}" >&3
fi

rm -f "${LOGFILE}"

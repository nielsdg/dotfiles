#!/usr/bin/env bash
#
set -euo pipefail

# All logs will be tagged with this string
# You can filter with `journalctl -t $LOG_TAG`
LOG_TAG="INWX-DynDNS"

# INWX details
INWX_URL="https://dyndns.inwx.com/nic/update?myip="
INWX_USERNAME=""
INWX_PW=""

if [[ -z "$INWX_PW" ]]; then
	logger -t "$LOG_TAG" -p user.warning "You forgot to set up the password"
	exit 1
fi

logger -t "$LOG_TAG" "Updating INWX DynDNS entry"

logger -t "$LOG_TAG" "Fetching public IP address"
PUBLIC_IP="$(curl -s http://ipinfo.io/ip)"

OUTPUT=$(curl -k -s "${INWX_URL}${PUBLIC_IP}" --user "$INWX_USERNAME:$INWX_PW")
if [ "${OUTPUT}" == "badauth" ]; then
	logger -t "$LOG_TAG" -p user.warning "INWX responded with badauth. You should check if your username/token is correct!"
	exit 1
elif [ "${OUTPUT}" == "nochg" ]; then
	logger -t "$LOG_TAG" "INWX reports same address"
elif [ "${OUTPUT}" == "good" ]; then
	logger -t "$LOG_TAG" "INWX reports successful address change"
fi

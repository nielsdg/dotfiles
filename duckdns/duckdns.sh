#!/usr/bin/env bash

# All logs will be tagged with this string
# You can filter with `journalctl -t $LOG_TAG`
LOG_TAG="DuckDNS"

logger -t "$LOG_TAG" "Updating DuckDNS entries"
EXITCODE=0
for file in /etc/duckdns.d/*.cfg; do
	source "${file}"
	logger -t "$LOG_TAG" "Executing config file '${file}'"
	OUTPUT=$(curl -k -s "https://www.duckdns.org/update?domains=${duckdns_hostname}&token=${duckdns_token}&ip=")
	logger -t "$LOG_TAG" "${OUTPUT}"
	if [ "${OUTPUT}" == "KO" ]; then
		logger -t "$LOG_TAG" "You should check if your domain/token is correct because the server responded negatively!"
		EXITCODE=1
	fi
done

exit $EXITCODE

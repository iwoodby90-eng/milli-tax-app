#!/bin/bash
# Watchdog: if backend stops responding, restart it
while true; do
    sleep 30
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8001/api/health)
    if [ "$STATUS" != "200" ]; then
        echo "$(date -u +%FT%TZ): Backend unhealthy (status=$STATUS), restarting..." >&2
        sudo supervisorctl restart backend
        sleep 10
    fi
done

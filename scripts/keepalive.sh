#!/bin/bash
# Milli backend keepalive — hits /api/health every 4 minutes so supervisor
# and the k8s liveness probe stay warm. If the process crashed, supervisor
# will autorestart before the next probe.
while true; do
    curl -s -m 5 -o /dev/null http://localhost:8001/api/health || true
    sleep 240
done

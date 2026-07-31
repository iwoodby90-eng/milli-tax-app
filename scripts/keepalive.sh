#!/bin/bash
# Aggressive keep-alive: hits backend every 60 seconds
while true; do
    curl -s -o /dev/null --max-time 5 http://localhost:8001/api/health || true
    sleep 60
done

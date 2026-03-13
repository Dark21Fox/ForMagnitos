#!/bin/bash

# RAM
RAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/^Mem:/ {print $3}')

# SWAP
SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')

# Load Average (1 min)
LA=$(cat /proc/loadavg | awk '{print $1}')

# CPU usage (%)
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# DISK
DISK_INFO=""
DISK_DATA=$(df -h --output=source,size,used,pcent,target | grep '^/dev/sd')

while IFS= read -r line; do
    MOUNT=$(echo "$line" | awk '{print $5}')
    TOTAL=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line"  | awk '{print $3}')
    DEV=$(echo "$line"   | awk '{print $1}' | sed 's|/dev/||')

    DISK_INFO="${DISK_INFO}|DISK_${DEV}_MOUNT=${MOUNT},TOTAL=${TOTAL},USED=${USED}"
done <<EOF
$DISK_DATA
EOF

# Итоговая строка
RESULT="RAM_TOTAL=${RAM_TOTAL}MB|RAM_USED=${RAM_USED}MB|SWAP_USED=${SWAP_USED}MB|LA=${LA}|CPU=${CPU}%${DISK_INFO}"

echo "$RESULT"
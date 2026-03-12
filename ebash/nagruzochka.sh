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

# Итоговая строка
RESULT="RAM_TOTAL=${RAM_TOTAL}MB|RAM_USED=${RAM_USED}MB|SWAP_USED=${SWAP_USED}MB|LA=${LA}|CPU=${CPU}%"

echo "$RESULT"
```

**Пример вывода:**
```
RAM_TOTAL=15987MB|RAM_USED=4231MB|SWAP_USED=120MB|LA=0.42|CPU=3.2%
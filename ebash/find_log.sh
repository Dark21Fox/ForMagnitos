#!/bin/bash

LOG_DIR="${1:?Использование: $0 /path/to/logs}"
[[ -d "$LOG_DIR" ]] || { echo "Ошибка: '$LOG_DIR' не директория"; exit 1; }

human() { numfmt --to=iec-i --suffix=B "$1"; }

VAR_SIZE=$(df --output=size -B1 /var | tail -1 | tr -d ' ')
VARLOG_SIZE=$(du -sb /var/log 2>/dev/null | cut -f1)

mapfile -t FILES < <(find "$LOG_DIR" -type f -name "nginx.access.log*" | sort)

TOTAL=0
SIZES=()
for f in "${FILES[@]}"; do
    s=$(stat -c%s "$f")
    SIZES+=("$(human "$s")")
    (( TOTAL += s ))
done

echo "$(human "$VAR_SIZE") | $(human "$VARLOG_SIZE") | $(IFS=,; echo "${SIZES[*]}") | $(human "$TOTAL")"
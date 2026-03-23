#!/bin/bash

LOG_DIR="${1:?Использование: $0 /path/to/logs}"
[[ -d "$LOG_DIR" ]] || { echo "Ошибка: '$LOG_DIR' не директория"; exit 1; }

human() {
    local b=$1
    if   (( b >= 1073741824 )); then printf "%.1fGiB" "$(( b * 10 / 1073741824 ))e-1"
    elif (( b >= 1048576    )); then printf "%.1fMiB" "$(( b * 10 / 1048576 ))e-1"
    elif (( b >= 1024       )); then printf "%.1fKiB" "$(( b * 10 / 1024 ))e-1"
    else printf "%dB" "$b"
    fi
}

read -r VAR_SIZE VAR_FREE < <(df -Pk /var | awk 'NR==2 {print $2*1024, $4*1024}')
VARLOG_SIZE=$(du -sb /var/log 2>/dev/null | cut -f1)

mapfile -t FILES < <(find "$LOG_DIR" -type f -name "nginx.access.log*" | sort)

TOTAL=0
SIZES=()
for f in "${FILES[@]}"; do
    s=$(stat -c%s "$f")
    SIZES+=("$(human "$s")")
    (( TOTAL += s ))
done

echo "$(human "$VAR_SIZE") | $(human "$VAR_FREE") | $(human "$VARLOG_SIZE") | $(IFS=,; echo "${SIZES[*]}") | $(human "$TOTAL")"
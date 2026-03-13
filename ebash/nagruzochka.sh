#!/bin/bash

# RAM
RAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/^Mem:/ {print $3}')

# SWAP
SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')

# Load Average (1 min)
LA=$(awk '{print $1}' /proc/loadavg)

# CPU usage (%)
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# DISK — дефолтный df -h без --output
DF_RAW=$(df -h | grep '^/dev/sd')

DISK_INFO=$(echo "$DF_RAW" | awk '
    function to_gb(val,    num, unit) {
        gsub(",", ".", val)
        unit = substr(val, length(val), 1)
        num  = substr(val, 1, length(val)-1) + 0
        if (unit == "T") return num * 1024
        if (unit == "G") return num
        if (unit == "M") return num / 1024
        if (unit == "K") return num / 1024 / 1024
        return num
    }
    {
        # $1=device $2=size $3=used $4=avail $5=use% $6=mountpoint
        dev = $1
        gsub("/dev/", "", dev)
        gsub(/[0-9]+$/, "", dev)   # sda1 -> sda

        disk_total[dev] += to_gb($2)
        disk_used[dev]  += to_gb($3)
    }
    END {
        grand_total = 0
        grand_used  = 0
        result = ""

        for (disk in disk_total) {
            t   = disk_total[disk]
            u   = disk_used[disk]
            pct = (t > 0) ? int(u / t * 100) : 0
            grand_total += t
            grand_used  += u
            result = result sprintf("|DISK_%s_TOTAL=%.1fG,USED=%.1fG,PCT=%d%%", disk, t, u, pct)
        }

        grand_pct = (grand_total > 0) ? int(grand_used / grand_total * 100) : 0
        result = result sprintf("|DISKS_TOTAL=%.1fG,USED=%.1fG,PCT=%d%%", grand_total, grand_used, grand_pct)
        print result
    }
')

# Итоговая строка
RESULT="RAM_TOTAL=${RAM_TOTAL}MB|RAM_USED=${RAM_USED}MB|SWAP_USED=${SWAP_USED}MB|LA=${LA}|CPU=${CPU}%${DISK_INFO}"

echo "$RESULT"
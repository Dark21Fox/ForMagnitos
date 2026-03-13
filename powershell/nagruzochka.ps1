# RAM
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = $os.TotalVisibleMemorySize / 1MB
$freeRAM  = $os.FreePhysicalMemory / 1MB

# Кэш памяти (Standby list)
$memInfo  = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$cachedRAM = $memInfo.StandbyCacheNormalPriorityBytes / 1GB + 
             $memInfo.StandbyCacheCoreBytes / 1GB +
             $memInfo.StandbyCacheReserveBytes / 1GB

$usedRAM      = [math]::Round($totalRAM - $freeRAM, 2)
$ramUtil      = [math]::Round(($totalRAM - ($freeRAM + $cachedRAM)) / $totalRAM * 100, 2)
$totalRAM_GB  = [math]::Round($totalRAM, 2)

# SWAP
$pageFile  = Get-CimInstance Win32_PageFileUsage
$totalSwap = [math]::Round($pageFile.AllocatedBaseSize / 1KB, 2)
$usedSwap  = [math]::Round($pageFile.CurrentUsage / 1KB, 2)
$swapUtil  = if ($totalSwap -gt 0) { [math]::Round($usedSwap / $totalSwap * 100, 2) } else { 0 }

# CPU
$cpuUtil = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

# Диски
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total    = [math]::Round($_.Size / 1GB, 2)
    $free     = [math]::Round($_.FreeSpace / 1GB, 2)
    $used     = [math]::Round($total - $free, 2)
    $diskUtil = [math]::Round(($total - $free) / $total * 100, 2)
    "$($_.DeviceID) Total:${total}GB Used:${used}GB Free:${free}GB Util:${diskUtil}%"
}
$disksStr = $disks -join "; "

# Итоговая строка
$result = "RAM Total:${totalRAM_GB}GB Used:${usedRAM}GB Util:${ramUtil}%|SWAP Total:${totalSwap}GB Used:${usedSwap}GB Util:${swapUtil}%|CPU Util:${cpuUtil}%|DISKS: $disksStr"

Write-Output $result

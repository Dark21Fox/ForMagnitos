# RAM
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$usedRAM  = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)

# SWAP (PageFile)
$pageFile = Get-CimInstance Win32_PageFileUsage
$totalSwap = [math]::Round($pageFile.AllocatedBaseSize / 1KB, 2)
$usedSwap  = [math]::Round($pageFile.CurrentUsage / 1KB, 2)

# CPU
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

# Диски
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [math]::Round($_.Size / 1GB, 2)
    $used  = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
    "$($_.DeviceID) Total:${total}GB Used:${used}GB"
}
$disksStr = $disks -join "; "

# Итоговая строка
$result = "RAM Total:${totalRAM}GB Used:${usedRAM}GB|SWAP Total:${totalSwap}GB Used:${usedSwap}GB|CPU Load:${cpu}%|DISKS: $disksStr"

Write-Output $result
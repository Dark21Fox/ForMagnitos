$ErrorActionPreference = "Stop"

# Build list in format: "Port : Printer model" for all port types.
$PrinterPortModelList = @()
Get-Printer | ForEach-Object {
    $PrinterPortModelList += "{0} : {1}" -f $_.PortName, $_.Name
}

# Remove duplicates and build one final string.
$PrinterPortModelList = $PrinterPortModelList | Sort-Object -Unique
$PrinterPortModelListString = $PrinterPortModelList -join ", "

# Safe output string: special characters are escaped and treated as plain data.
$PrinterPortModelListStringSafe = $PrinterPortModelListString | ConvertTo-Json -Compress

Write-Output $PrinterPortModelListStringSafe

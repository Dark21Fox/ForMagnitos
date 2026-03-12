$FilePath = "C:\path\to\file.txt"
$OldUrl = "https://old.example"
$NewUrl = "https://new.example"

$content = Get-Content -LiteralPath $FilePath -Raw
$content = [regex]::Replace($content, [regex]::Escape($OldUrl), $NewUrl)
Set-Content -LiteralPath $FilePath -Value $content

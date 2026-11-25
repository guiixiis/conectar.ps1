[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" -Headers @{ "User-Agent" = "PowerShell" }
$url = ($release.assets | Where-Object { $_.name -like "*x86_64.exe" } | Select-Object -First 1).browser_download_url
$arquivo = "$env:TEMP\RustDesk_$(Get-Random).exe"

Invoke-WebRequest -Uri $url -OutFile $arquivo
Start-Process -FilePath $arquivo

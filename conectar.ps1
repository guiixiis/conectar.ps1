[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$arquivo = "$env:TEMP\AnyDesk_$(Get-Random).exe"

curl.exe -s -L "https://download.anydesk.com/AnyDesk.exe" -o $arquivo
if (Test-Path $arquivo) { Start-Process -FilePath $arquivo }

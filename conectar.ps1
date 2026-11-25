$ProgressPreference = 'SilentlyContinue'
$url = "https://download.anydesk.com/AnyDesk.exe"
$arquivo = "$env:TEMP\AnyDesk_$(Get-Random).exe"

Invoke-WebRequest -Uri $url -OutFile $arquivo
Start-Process -FilePath $arquivo

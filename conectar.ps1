$release = Invoke-RestMethod "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
$url = ($release.assets | Where-Object { $_.name -like "*x86_64.exe" } | Select-Object -First 1).browser_download_url
$arquivo = "$env:TEMP\RustDesk.exe"

Invoke-WebRequest -Uri $url -OutFile $arquivo
Start-Process -FilePath $arquivo

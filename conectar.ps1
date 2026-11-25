$url = "COLA_AQUI_O_LINK_COPIADO_DO_MESHCENTRAL"
$arquivo = "$env:TEMP\suporte.exe"

Invoke-WebRequest -Uri $url -OutFile $arquivo
Start-Process -FilePath $arquivo -ArgumentList "-connect"

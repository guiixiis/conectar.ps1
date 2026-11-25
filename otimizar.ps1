# ==============================================================================
# OTIMIZACAO COMPETITIVA WINDOWS 10 / 10 PRO / 11 / 11 PRO (NVIDIA & AMD)
# ==============================================================================

# 1. Verifica permissao de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERRO] Execute o PowerShell como Administrador!" -ForegroundColor Red
    Pause
    exit
}

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# Funcao auxiliar para gravar chaves de registro com seguranca
function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

# Deteccao automatica do ambiente
$os = Get-CimInstance Win32_OperatingSystem
$osName = $os.Caption
$isWin11 = ([int]$os.BuildNumber -ge 22000)
$isPro = ($osName -match "Pro|Enterprise|Education")
$gpus = (Get-CimInstance Win32_VideoController).Name -join " | "
$hasNvidia = ($gpus -match "NVIDIA")
$hasAmd = ($gpus -match "AMD|Radeon")
$isLaptop = ($null -ne (Get-CimInstance Win32_Battery))

# ==============================================================================
# MODULO 1: PONTO DE RESTAURACAO
# ==============================================================================
function New-SafeRestorePoint {
    Write-Host "`n[1/5] Criando Ponto de Restauracao de seguranca..." -ForegroundColor Cyan
    Enable-ComputerRestore -Drive "C:\"
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" "SystemRestorePointCreationFrequency" 0
    Checkpoint-Computer -Description "Pre-Otimizacao-Competitiva" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "  -> Ponto de restauracao solicitado com sucesso." -ForegroundColor Green
}

# ==============================================================================
# MODULO 2: ENERGIA, CPU E AGENDADOR (SCHEDULER)
# ==============================================================================
function Optimize-PowerAndCPU {
    Write-Host "`n[2/5] Otimizando Plano de Energia, CPU e Prioridade de Processos..." -ForegroundColor Cyan

    # Desbloqueia e ativa Desempenho Maximo (com fallback para Alto Desempenho)
    $ultOut = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($ultOut -match "([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})") {
        powercfg /setactive $Matches[1] | Out-Null
        Write-Host "  -> Plano 'Desempenho Maximo' ativado." -ForegroundColor Green
    } else {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
        Write-Host "  -> Plano 'Alto Desempenho' ativado." -ForegroundColor Green
    }

    # Desativa Suspensao Seletiva USB (evita micro-travamentos em mouse/teclado)
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    # Desativa economia de energia do PCI Express (evita quedas de clock da GPU)
    powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
    # Estado maximo da CPU em 100% na tomada
    powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100

    # Em Desktop: trava CPU minima em 100% e desativa hibernacao (em notebook preserva bateria/temperatura)
    if (-not $isLaptop) {
        powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
        powercfg /h off
        Write-Host "  -> Perfil Desktop: CPU 100% + Hibernacao desativada." -ForegroundColor Green
    } else {
        Write-Host "  -> Perfil Notebook: Protecao termica preservada (minimo dinamico)." -ForegroundColor Yellow
    }
    powercfg /setactive SCHEME_CURRENT | Out-Null

    # Win32PrioritySeparation = 38 (0x26): Melhor resposta para jogos em primeiro plano
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38

    # MMCSS: Prioridade maxima de CPU/GPU para jogos
    $mmcss = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-RegValue $mmcss "SystemResponsiveness" 10
    $gamesProfile = "$mmcss\Tasks\Games"
    Set-RegValue $gamesProfile "GPU Priority" 8
    Set-RegValue $gamesProfile "Priority" 6
    Set-RegValue $gamesProfile "Scheduling Category" "High" "String"
    Set-RegValue $gamesProfile "SFIO Priority" "High" "String"
    Set-RegValue $gamesProfile "Clock Rate" 10000

    Write-Host "  -> Scheduler e perfil MMCSS para jogos aplicados." -ForegroundColor Green
}

# ==============================================================================
# MODULO 3: JOGOS, WINDOWS 10/11 E GPU (NVIDIA & AMD)
# ==============================================================================
function Optimize-GamingAndGPU {
    Write-Host "`n[3/5] Otimizando subsistema de Jogos e Placa de Video..." -ForegroundColor Cyan

    # Ativa Modo de Jogo (Game Mode)
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1

    # Desativa Game DVR e gravacao em segundo plano (ganho direto em 1% Low)
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0

    # Ativa HAGS (Agendamento de GPU acelerado por hardware)
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2

    # Exclusivo Windows 11: Otimizacoes para jogos em modo janela (Flip Model)
    if ($isWin11) {
        Set-RegValue "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" "SwapEffectUpgradeEnable=1;" "String"
        Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
        Write-Host "  -> Ajustes especificos do Windows 11 aplicados." -ForegroundColor Green
    }

    # Ativa MSI Mode (Message Signaled Interrupts) na GPU PCIe (reduz latencia DPC)
    $videoDevices = Get-CimInstance Win32_VideoController | Where-Object { $_.PNPDeviceID -like "PCI\VEN_*" }
    foreach ($dev in $videoDevices) {
        $devBase = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.PNPDeviceID)\Device Parameters"
        if (Test-Path $devBase) {
            Set-RegValue "$devBase\Interrupt Management\MessageSignaledInterruptProperties" "MSISupported" 1
            Write-Host "  -> MSI Mode ativado em: $($dev.Name)" -ForegroundColor Green
        }
    }

    # Tweaks especificos NVIDIA
    if ($hasNvidia) {
        Get-ScheduledTask -TaskName "NvTmRep*","NvTmMon*" | Disable-ScheduledTask | Out-Null
        if (Get-Service "NvTelemetryContainer") {
            Stop-Service "NvTelemetryContainer" -Force
            Set-Service "NvTelemetryContainer" -StartupType Disabled
        }
        Write-Host "  -> Tweaks NVIDIA aplicados (telemetria desativada)." -ForegroundColor Green
    }

    # Tweaks especificos AMD (Desativa ULPS - elimina engasgos por queda de clock)
    if ($hasAmd) {
        Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath
            if ($null -ne $props.EnableUlps) {
                Set-ItemProperty -Path $_.PSPath -Name "EnableUlps" -Value 0 -Type DWord -Force
            }
            if ($null -ne $props.EnableUlps_NA) {
                Set-ItemProperty -Path $_.PSPath -Name "EnableUlps_NA" -Value "0" -Type String -Force
            }
        }
        Write-Host "  -> Tweaks AMD aplicados (ULPS desativado)." -ForegroundColor Green
    }
}

# ==============================================================================
# MODULO 4: REDE E LATENCIA (PING / JITTER)
# ==============================================================================
function Optimize-Network {
    Write-Host "`n[4/5] Otimizando Rede e Latencia..." -ForegroundColor Cyan

    # Remove limite de banda para pacotes multimidia (NetworkThrottlingIndex = FFFFFFFF)
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null

    # Desativa Algoritmo de Nagle e economia de energia nas placas de rede ativas
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($nic in $adapters) {
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($nic.InterfaceGuid)"
        if (Test-Path $tcpPath) {
            Set-RegValue $tcpPath "TcpAckFrequency" 1
            Set-RegValue $tcpPath "TCPNoDelay" 1
        }
        Disable-NetAdapterPowerManagement -Name $nic.Name
        Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword "*EEE" -RegistryValue 0
        Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword "GreenEthernet" -RegistryValue 0
        Write-Host "  -> Placa otimizada (Sem Nagle / Sem EEE): $($nic.Name)" -ForegroundColor Green
    }

    # Ajustes TCP globais seguros e limpeza de DNS
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    ipconfig /flushdns | Out-Null
    Write-Host "  -> Pilha TCP ajustada e cache DNS limpo." -ForegroundColor Green
}

# ==============================================================================
# MODULO 5: TELEMETRIA, PRO POLICIES, MOUSE 1:1 E LIMPEZA
# ==============================================================================
function Optimize-SystemAndCleanup {
    Write-Host "`n[5/5] Aplicando limpeza, Telemetria, Mouse 1:1 e Policies..." -ForegroundColor Cyan

    # Desativa Apps em Segundo Plano
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2

    # Desativa transparencia e acelera menus (mantem fontes nitidas e miniaturas)
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
    Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"

    # Mouse 1:1 (Remove aceleracao "Aprimorar precisao do ponteiro")
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"

    # Politicas avancadas para Windows 10 Pro / 11 Pro
    if ($isPro) {
        # Impede Windows Update de sobrescrever drivers NVIDIA/AMD otimizados
        Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" 1
        Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
        Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
        Write-Host "  -> Politicas Pro aplicadas (drivers protegidos + telemetria zero)." -ForegroundColor Green
    } else {
        Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 1
    }

    # Desativa apenas servicos de telemetria seguros (nao afeta jogos, impressora ou rede)
    $servicos = @("DiagTrack", "dmwappushservice", "WerSvc", "MapsBroker")
    foreach ($svc in $servicos) {
        if (Get-Service $svc) {
            Stop-Service $svc -Force
            Set-Service $svc -StartupType Disabled
        }
    }

    # Desativa tarefas agendadas de telemetria da Microsoft
    $tarefas = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    )
    foreach ($task in $tarefas) {
        schtasks /Change /TN $task /Disable 2>$null | Out-Null
    }

    # Otimizacao de sistema de arquivos NTFS e TRIM no SSD
    fsutil behavior set disablelastaccess 1 | Out-Null
    fsutil behavior set disable8dot3 1 | Out-Null
    Optimize-Volume -DriveLetter C -ReTrim

    # Limpeza segura de arquivos temporarios
    Remove-Item "$env:TEMP\*" -Recurse -Force
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
    Write-Host "  -> Temporarios limpos, NTFS ajustado e TRIM executado." -ForegroundColor Green
}

# ==============================================================================
# MENU INTERATIVO
# ==============================================================================
do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "        OTIMIZADOR COMPETITIVO WINDOWS (FPS / LATENCIA)   " -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Sistema : $osName"
    Write-Host " Edicao  : $(if ($isPro) {'Pro / Enterprise'} else {'Home'}) | $(if ($isLaptop) {'Notebook'} else {'Desktop'})"
    Write-Host " GPU     : $gpus"
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Otimizacao COMPLETA Recomendada (Ponto de Restauracao + Tudo)" -ForegroundColor Green
    Write-Host " [2] Apenas Energia, CPU e Scheduler (MMCSS)"
    Write-Host " [3] Apenas Jogos e GPU (Game Mode, Sem DVR, HAGS, MSI, NVIDIA/AMD)"
    Write-Host " [4] Apenas Rede e Latencia (Sem Nagle, Sem Throttling, Sem EEE)"
    Write-Host " [5] Apenas Telemetria, Mouse 1:1, Policies Pro e Limpeza"
    Write-Host " [6] Abrir Restauracao do Sistema (Reverter alteracoes)" -ForegroundColor Yellow
    Write-Host " [0] Sair" -ForegroundColor Red
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" {
            New-SafeRestorePoint
            Optimize-PowerAndCPU
            Optimize-GamingAndGPU
            Optimize-Network
            Optimize-SystemAndCleanup
            Write-Host "`n[CONCLUIDO] Otimizacao completa finalizada! Reinicie o PC para aplicar tudo." -ForegroundColor Green
            Pause
        }
        "2" { Optimize-PowerAndCPU; Pause }
        "3" { Optimize-GamingAndGPU; Pause }
        "4" { Optimize-Network; Pause }
        "5" { Optimize-SystemAndCleanup; Pause }
        "6" { Start-Process "rstrui.exe" }
        "0" { break }
        default { Write-Host "Opcao invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($op -ne "0")

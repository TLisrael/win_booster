function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

function Log-Event {
    param($Text)
    Add-Content -Path "$env:SystemDrive\WindowsOptimizer.log" -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Text"
}

function Progress-Update {
    param($Message, $Current, $Total)
    Write-Progress -Activity "Otimização do Sistema" -Status $Message -PercentComplete (($Current / $Total) * 100)
}

function Create-Restore {
    Checkpoint-Computer -Description "Otimizador Windows" -RestorePointType "MODIFY_SETTINGS" | Out-Null
    Log-Event "Ponto de restauração gerado."
}

function Backup-RegistryHive {
    $path = "$env:SystemDrive\RegBackup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    reg export HKLM "$path\HKLM.reg" /y
    reg export HKCU "$path\HKCU.reg" /y
    Log-Event "Backup do registro em $path."
}

function Service-StopDisable {
    param([string[]]$Names)
    foreach ($svc in $Names) {
        $obj = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($obj) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled
            Log-Event "Serviço $svc desativado."
        }
    }
}

function System-Cleanup {
    $folders = @(
        "$env:TEMP\*", "C:\Windows\Temp\*", 
        "C:\Windows\Prefetch\*", "C:\Windows\SoftwareDistribution\Download\*", 
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )
    foreach ($dir in $folders) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Log-Event "Limpeza: $dir."
    }
}

function Appx-RemoveBloat {
    $packages = @(
        "Microsoft.3DBuilder", "Microsoft.Xbox*", 
        "Microsoft.ZuneMusic", "Microsoft.MicrosoftSolitaireCollection", 
        "Microsoft.People", "Microsoft.Messaging", 
        "Microsoft.WindowsMaps", "Microsoft.BingWeather"
    )
    foreach ($pkg in $packages) {
        Get-AppxPackage -Name $pkg -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Log-Event "Removido pacote $pkg."
    }
}

function System-Optimize {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0
    powercfg /hibernate off
    Log-Event "Hibernação desabilitada."
}

function Verify-SystemFiles {
    Start-Process sfc.exe -ArgumentList "/scannow" -Wait -NoNewWindow
    Log-Event "SFC concluído."
}

function Repair-WindowsImage {
    Start-Process dism.exe -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
    Log-Event "DISM finalizado."
}

Clear-Host
Assert-Admin
Log-Event "Início da execução."

$totalTasks = 8
$step = 0

$step++; Progress-Update "Criando Ponto de Restauração" $step $totalTasks; Create-Restore
$step++; Progress-Update "Backup do Registro" $step $totalTasks; Backup-RegistryHive
$step++; Progress-Update "Desativando Serviços" $step $totalTasks; Service-StopDisable @("DiagTrack", "SysMain", "WSearch", "WMPNetworkSvc", "wuauserv", "RetailDemo", "Fax", "lfsvc", "icssvc")
$step++; Progress-Update "Limpando Sistema" $step $totalTasks; System-Cleanup
$step++; Progress-Update "Removendo Aplicativos Inúteis" $step $totalTasks; Appx-RemoveBloat
$step++; Progress-Update "Desabilitando Hibernação" $step $totalTasks; System-Optimize
$step++; Progress-Update "Executando Verificação SFC" $step $totalTasks; Verify-SystemFiles
$step++; Progress-Update "Executando DISM" $step $totalTasks; Repair-WindowsImage

Write-Progress -Activity "Concluído" -Completed
Log-Event "Execução finalizada."

Write-Host "`nOtimização concluída com sucesso." -ForegroundColor Green
$restart = Read-Host "Deseja reiniciar agora? (s/n)"
if ($restart -eq "s") { Restart-Computer }

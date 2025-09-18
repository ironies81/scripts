$patate = @"

|   Ping      |
|   Patate    |

Le script ne peut pas faire de ping vers une IP publique
si vous choisissez "resolution DNS continue : Y".

"@
Write-Host $patate

$useDns = Read-Host "Ping avec resolution DNS continue ? (Y/N)"
$dnsEnabled = $useDns.Trim().ToUpper() -eq "Y"

$useLogs = Read-Host "Ping avec logs ? (Y/N)"
$logsEnabled = $useLogs.Trim().ToUpper() -eq "Y"

if ($logsEnabled) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = "ping_log_$timestamp.txt"
    Add-Content -Path $logFile -Value "=== Debut du ping a $timestamp ==="
}

$inputValue = Read-Host "Entrez le nom d'hote ou l'adresse IP a pinger"
$host.UI.RawUI.WindowTitle = "Ping Continu - $($inputValue)"

# Verification si IP
$isIP = $inputValue -match '^(\d{1,3}\.){3}\d{1,3}$' -or $inputValue -match '^[a-fA-F0-9:]+$'
$resolvedIP = $inputValue

# Si pas d'IP et pas de DNS actif, resoudre une seule fois
if (-not $dnsEnabled -and -not $isIP) {
    try {
        $resolvedIP = (Resolve-DnsName $inputValue -Type A -ErrorAction Stop | Select-Object -First 1 -ExpandProperty IPAddress)
        Write-Host "Resolution effectuee : $inputValue => $resolvedIP" -ForegroundColor Cyan
    } catch {
        Write-Host "Echec de la resolution de $inputValue. Arret du script." -ForegroundColor Red
        exit
    }
}

if (-not $dnsEnabled) {
    Write-Host -NoNewline "[" -ForegroundColor Green
    Write-Host -NoNewline "$(Get-Date -Format "HH:mm:ss")" -ForegroundColor Green
    Write-Host -NoNewline "] " -ForegroundColor Green
    Write-Host "IP utilisee pour le ping : $resolvedIP" -ForegroundColor Yellow

    if ($logsEnabled) {
        Add-Content -Path $logFile -Value "[$(Get-Date -Format "HH:mm:ss")] IP utilisee pour le ping : $resolvedIP"
    }
}

$afficherInfo = $false
$compteur = 0
$intervalleFlush = 20
$intervalleLigneVide = 10

while ($true) {
    $heure = Get-Date -Format "HH:mm:ss"

    if ($dnsEnabled -and $compteur -ge $intervalleFlush) {
        Write-Host -NoNewline "[" -ForegroundColor Green
        Write-Host -NoNewline "$heure" -ForegroundColor Green
        Write-Host -NoNewline "] " -ForegroundColor Green
        Write-Host "Purge du cache DNS" -ForegroundColor DarkYellow

        if ($logsEnabled) {
            Add-Content -Path $logFile -Value "[$heure] Purge du cache DNS"
        }

        try {
            Clear-DnsClientCache
        } catch {
            Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -WindowStyle Hidden -Wait
        }

        $compteur = 0
    }

    if (-not $dnsEnabled -and $compteur -ge $intervalleLigneVide) {
        Write-Host ""
        $compteur = 0
    }

    if ($afficherInfo -and $dnsEnabled) {
        try {
            $ip = (Resolve-DnsName $inputValue -Type A -ErrorAction Stop | Select-Object -First 1 -ExpandProperty IPAddress)
            $msg = "$ip"
        } catch {
            $msg = "Impossible de resoudre l'adresse IP de $inputValue"
        }

        Write-Host -NoNewline "[" -ForegroundColor Green
        Write-Host -NoNewline "$heure" -ForegroundColor Green
        Write-Host -NoNewline "] " -ForegroundColor Green
        Write-Host "$msg" -ForegroundColor Yellow

        if ($logsEnabled) {
            Add-Content -Path $logFile -Value "[$heure] $msg"
        }

    } else {
        try {
            $result = Test-Connection -ComputerName $resolvedIP -Count 1 -ErrorAction Stop
            if ($result) {
                $tempsReponse = [math]::Round($result.ResponseTime)
                $msg = "Ping OK vers $resolvedIP (32 octets) - ${tempsReponse}ms"
                $color = "Green"
            } else {
                $msg = "Ping NOK vers $resolvedIP"
                $color = "Red"
            }
        } catch {
            $msg = "Erreur lors du ping de $resolvedIP"
            $color = "Red"
        }

        Write-Host -NoNewline "[" -ForegroundColor Green
        Write-Host -NoNewline "$heure" -ForegroundColor Green
        Write-Host -NoNewline "] " -ForegroundColor Green
        Write-Host "$msg" -ForegroundColor $color

        if ($logsEnabled) {
            Add-Content -Path $logFile -Value "[$heure] $msg"
        }
    }

    $afficherInfo = -not $afficherInfo
    $compteur++
    Start-Sleep -Milliseconds 100
}

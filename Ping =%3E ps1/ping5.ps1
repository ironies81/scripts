# Demande le nom d'hôte ou l'IP
$inputValue = Read-Host "Entrez le nom d'hote ou l'adresse IP à pinger"

# Titre de la console
$host.UI.RawUI.WindowTitle = "Ping Continu - $($inputValue)"

# Détermine si c'est une IP (v4 ou v6)
$isIP = $inputValue -match '^(\d{1,3}\.){3}\d{1,3}$' -or $inputValue -match '^[a-fA-F0-9:]+$'

# Variable pour alterner l'affichage
$afficherInfo = $false

# Compteur pour le flush DNS
$compteur = 0
$intervalleFlush = 100

while ($true) {
    $heure = Get-Date -Format "HH:mm:ss"

    # Toutes les 100 secondes, on flush le cache DNS
    if ($compteur -ge $intervalleFlush) {
        Write-Host -NoNewline "[" -ForegroundColor Green
        Write-Host -NoNewline "$heure" -ForegroundColor Green
        Write-Host -NoNewline "] " -ForegroundColor Green
        Write-Host "Purge du cache DNS (ipconfig /flushdns)..." -ForegroundColor DarkYellow
        # Utilise Clear-DnsClientCache si disponible, sinon ipconfig /flushdns
        try {
            Clear-DnsClientCache
        } catch {
            Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -WindowStyle Hidden -Wait
        }
        $compteur = 0
    }

    if ($afficherInfo) {
        if ($isIP) {
            # Résolution inverse : IP vers nom d'hôte
            try {
                $nomHote = ([System.Net.Dns]::GetHostEntry($inputValue)).HostName
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "Nom d'hôte pour $inputValue : $nomHote"
            } catch {
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "Impossible de résoudre le nom d'hôte pour $inputValue" -ForegroundColor Yellow
            }
        } else {
            # Résolution directe : nom d'hôte vers IP
            try {
                $ip = (Resolve-DnsName $inputValue -Type A -ErrorAction Stop | Select-Object -First 1 -ExpandProperty IPAddress)
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "IP de $inputValue : $ip"
            } catch {
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "Impossible de résoudre l'adresse IP de $inputValue" -ForegroundColor Yellow
            }
        }
    } else {
        # Effectue le ping
        $ping = Test-Connection -ComputerName $inputValue -Count 1 -Quiet
        if ($ping) {
            Write-Host -NoNewline "[" -ForegroundColor Green
            Write-Host -NoNewline "$heure" -ForegroundColor Green
            Write-Host -NoNewline "] " -ForegroundColor Green
            Write-Host "Ping OK vers $inputValue"
        } else {
            Write-Host -NoNewline "[" -ForegroundColor Green
            Write-Host -NoNewline "$heure" -ForegroundColor Green
            Write-Host -NoNewline "] " -ForegroundColor Green
            Write-Host "Ping NOK vers $inputValue" -ForegroundColor Red
        }
    }

    $afficherInfo = -not $afficherInfo
    $compteur++
    Start-Sleep -Seconds 1
}

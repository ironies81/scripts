# Demande le nom d'hote ou l'IP
$inputValue = Read-Host "Entrez le nom d'hote ou l'adresse IP a pinger"

# Titre de la console
$host.UI.RawUI.WindowTitle = "Ping Continu - $($inputValue)"

# Determine si c'est une IP (v4 ou v6)
$isIP = $inputValue -match '^(\d{1,3}\.){3}\d{1,3}$' -or $inputValue -match '^[a-fA-F0-9:]+$'

# Variable pour alterner l'affichage
$afficherInfo = $false

while ($true) {
    $heure = Get-Date -Format "HH:mm:ss"

    if ($afficherInfo) {
        if ($isIP) {
            # Resolution inverse : IP vers nom d'hote
            try {
                $nomHote = ([System.Net.Dns]::GetHostEntry($inputValue)).HostName
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "Nom d'hote pour $inputValue : $nomHote"
            } catch {
                Write-Host -NoNewline "[" -ForegroundColor Green
                Write-Host -NoNewline "$heure" -ForegroundColor Green
                Write-Host -NoNewline "] " -ForegroundColor Green
                Write-Host "Impossible de resoudre le nom d'hote pour $inputValue" -ForegroundColor Yellow
            }
        } else {
            # Resolution directe : nom d'hote vers IP
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
                Write-Host "Impossible de resoudre l'adresse IP de $inputValue" -ForegroundColor Yellow
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
    Start-Sleep -Seconds 1
}

# Demande le nom d'hôte
$hostname = Read-Host "Entrez le nom d'hote a pinger"

# Titre de la console
$host.UI.RawUI.WindowTitle = "Ping Continu - $($hostname)"

# Boucle infinie
while ($true) {
    # Effectue le ping
    $ping = Test-Connection -ComputerName $hostname -Count 1 -Quiet

    # Récupère l'heure
    $heure = Get-Date -Format "HH:mm:ss"

    # Affiche le résultat
    if ($ping) {
        Write-Host "[$heure] Ping OK vers $hostname"
    } else {
        Write-Host "[$heure] Ping NOK vers $hostname" -ForegroundColor Red
    }

    # Attend une seconde
    Start-Sleep -Seconds 1
}

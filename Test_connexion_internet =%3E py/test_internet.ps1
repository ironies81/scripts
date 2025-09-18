# Tester la connexion Internet
$internet = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet

if ($internet) {
    Write-Host "Internet OK" -ForegroundColor Green
} else {
    Write-Host "Internet NOK" -ForegroundColor Red
}

# Récupérer l'IP publique
$ip = Invoke-RestMethod -Uri "https://api.ipify.org"
Write-Host "IP public V4 : $ip"

# Résolution DNS
try {
    $dns = Resolve-DnsName google.fr
    Write-Host "Résolution nom Pub : OK"
} catch {
    Write-Host "Résolution nom Pub : Impossible"
}

# Pings
Write-Host "Ping 1.1.1.1"
Test-Connection 1.1.1.1 -Count 2

Write-Host "Ping 8.8.8.8"
Test-Connection 8.8.8.8 -Count 2

Write-Host "Ping google.com"
Test-Connection google.com -Count 2

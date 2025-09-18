# Vérifie l'exécution en tant qu'admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté avec des droits administrateur." -ForegroundColor Red
    exit
}

# Demande les informations de connexion
$domainName = Read-Host "Nom du domaine (ex : mondomaine.local)"
$domainUser = Read-Host "Nom d'utilisateur avec droits d'ajout (ex : MONDOMAINE\\adminjoin)"
$password = Read-Host "Mot de passe" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($domainUser, $password)

# Rejoindre à nouveau le domaine sans redémarrer immédiatement
try {
    Add-Computer -DomainName $domainName -Credential $cred -Force -ErrorAction Stop
    Write-Host "`n✅ Le PC a été reconnecté au domaine avec succès. Un redémarrage est requis." -ForegroundColor Green
    $reboot = Read-Host "Souhaitez-vous redémarrer maintenant ? (o/n)"
    if ($reboot -eq "o") {
        Restart-Computer
    } else {
        Write-Host "Redémarrez manuellement pour finaliser la réparation." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`n❌ Échec de la reconnexion au domaine : $_" -ForegroundColor Red
}

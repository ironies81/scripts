Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Élévation UAC si nécessaire ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

# --- Vérification de la présence du module Active Directory ---
$moduleAD = Get-Module -ListAvailable -Name ActiveDirectory
if (-not $moduleAD) {
    $message = @"
Le module Active Directory n'est pas installe. Veuillez suivre les etapes ci-dessous pour l'installer manuellement :

1. Verifier la presence du module :

   Dans PowerShell, lancez :
   
   Get-Module -ListAvailable ActiveDirectory
   

   Si rien ne s'affiche, le module n'est pas installe.

2. Installer le module Active Directory :

   Sur un controleur de domaine ou une machine avec les outils RSAT :
   Sur Windows 10/11, installez les RSAT (Remote Server Administration Tools) :

   Dans PowerShell, lancez :
   
   # Pour Windows 10/11 version 1809 ou ulterieure
   Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Add-WindowsCapability -Online
   

   Ou via les fonctionnalites Windows :
   Ouvrez "Parametres" > "Applications" > "Fonctionnalites facultatives" > "Ajouter une fonctionnalite" > "RSAT: Outils d’Administration de serveur distant Active Directory".

Sur Windows Server :
Active le role via Server Manager ou PowerShell

Dans PowerShell, lance :
Install-WindowsFeature RSAT-AD-PowerShell

Appuyer sur OK pour copier le texte

"@
# --- Affichage de la boîte de message et gestion du bouton "Copier" ---
    $result = [System.Windows.Forms.MessageBox]::Show($message, "Module manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

    # --- Si l'utilisateur clique sur "OK" (qui devient "Copier") ---
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # --- Copier le message dans le presse-papiers ---
        [System.Windows.Forms.Clipboard]::SetText($message)
    }

    exit 1
}

# --- Demande du nom du serveur AD ---
$nomServeur = Read-Host "Entrez le nom du serveur Active Directory"

# --- Importation du module Active Directory ---
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "Impossible d'importer le module Active Directory. Verifiez que le module est installe."
    exit 1
}

# --- Definir le chemin d'exportation et creer le dossier si necessaire ---
$cheminExport = "C:\temp"
if (!(Test-Path -Path $cheminExport)) {
    try {
        New-Item -ItemType Directory -Path $cheminExport -ErrorAction Stop
        Write-Host "Dossier $cheminExport cree avec succes."
    } catch {
        Write-Error "Impossible de creer le dossier $cheminExport. Verifiez les permissions."
        exit 1
    }
}

# --- Recuperer tous les ordinateurs de type workstation ---
try {
    $ordinateurs = Get-ADComputer -Server $nomServeur -Filter 'OperatingSystem -like "*Windows*" -and OperatingSystem -notlike "*Server*"' -Properties Name, OperatingSystem, LastLogonDate
} catch {
    Write-Error "Erreur lors de la recuperation des informations AD. Verifiez la connexion au domaine."
    exit 1
}

# --- Exporter les informations dans un fichier CSV ---
$cheminFichierCsv = Join-Path -Path $cheminExport -ChildPath "Workstations_AD.csv"

start C:\temp\

try {
    $ordinateurs | Select-Object Name, OperatingSystem, LastLogonDate | Export-Csv -Path $cheminFichierCsv -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Write-Host "Informations exportees avec succes vers : $cheminFichierCsv"
} catch {
    Write-Error "Erreur lors de l'exportation vers le fichier CSV."
    exit 1
}

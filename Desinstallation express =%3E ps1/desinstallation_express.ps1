# ================================
# Script de desinstallation native Windows avec execution forcée
# ================================

# Forcer l'execution du script sans modifier globalement la machine
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Vérifier si admin, sinon relancer avec UAC
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {

    $arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# --- Etape 1 : Recuperation des applis ---
$apps = @()

# 64 bits
$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps += Get-ItemProperty $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.UninstallString } |
        Select-Object DisplayName, UninstallString
}

# Suppression doublons
$apps = $apps | Sort-Object DisplayName -Unique

if ($apps.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Aucune application trouvee !")
    exit
}

# --- Etape 2 : Interface graphique ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Desinstallation Windows"
$form.Size = '500,600'
$form.StartPosition = "CenterScreen"

$checkedList = New-Object System.Windows.Forms.CheckedListBox
$checkedList.Dock = 'Fill'
$apps | ForEach-Object { $null = $checkedList.Items.Add($_.DisplayName) }
$form.Controls.Add($checkedList)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "Desinstaller"
$okButton.Dock = 'Bottom'
$form.Controls.Add($okButton)

$okButton.Add_Click({ $form.Tag = "OK"; $form.Close() })
$form.ShowDialog() | Out-Null
if ($form.Tag -ne "OK") { exit }

$selected = $checkedList.CheckedItems
if ($selected.Count -eq 0) { exit }

# --- Etape 3 : Desinstallation ---
$result = @()

foreach ($appName in $selected) {
    $app = $apps | Where-Object { $_.DisplayName -eq $appName }
    if ($null -eq $app) { continue }

    try {
        Write-Host "Desinstallation de $appName ..."
        $uninstallCmd = $app.UninstallString

        # nettoyage : enlever quotes et params parasites
        $exe, $args = $null
        if ($uninstallCmd -match '^"(.+?)"\s*(.*)') {
            $exe = $matches[1]
            $args = $matches[2]
        } else {
            $exe = $uninstallCmd
            $args = ""
        }

        # ajout /quiet ou /silent si possible
        if ($args -notmatch "/quiet" -and $args -notmatch "/silent") {
            $args += " /quiet /norestart"
        }

        $proc = Start-Process -FilePath $exe -ArgumentList $args -Wait -PassThru -ErrorAction Stop

        # Verification si encore present
        $stillHere = (Get-ItemProperty $regPaths -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq $appName }).Count -gt 0

        if ($stillHere) {
            $result += "[ECHEC] $appName"
        } else {
            $result += "[OK] $appName"
        }
    } catch {
        $result += "[ECHEC] $appName (Erreur: $_)"
    }
}

# --- Etape 4 : Rapport final ---
[System.Windows.Forms.MessageBox]::Show(($result -join "`n"), "Rapport desinstallations")
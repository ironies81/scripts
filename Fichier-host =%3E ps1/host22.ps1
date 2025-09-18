Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Solution hybride pour détecter le chemin du script ou EXE
$ScriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($ScriptPath)) {
    $ScriptPath = [System.Windows.Forms.Application]::ExecutablePath
}
$ScriptDir = Split-Path $ScriptPath

# Vérification des droits administrateur (adapté pour EXE)
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $IsAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ScriptPath
    $psi.Verb = "runas"
    try { [System.Diagnostics.Process]::Start($psi) | Out-Null }
    catch { [System.Windows.Forms.MessageBox]::Show("Impossible de relancer le script en administrateur. `$($_)","Erreur",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) }
    exit
}

# Création de la fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mise à jour du fichier hosts"
$form.Size = New-Object System.Drawing.Size(500,360)
$form.StartPosition = "CenterScreen"

# Label et textbox IP
$lblIP = New-Object System.Windows.Forms.Label
$lblIP.Text = "Adresse IP :"
$lblIP.Location = New-Object System.Drawing.Point(20,20)
$lblIP.AutoSize = $true
$form.Controls.Add($lblIP)

$txtIP = New-Object System.Windows.Forms.TextBox
$txtIP.Location = New-Object System.Drawing.Point(120,18)
$txtIP.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($txtIP)

# Label et textbox Hostname
$lblHost = New-Object System.Windows.Forms.Label
$lblHost.Text = "Nom d'hôte :"
$lblHost.Location = New-Object System.Drawing.Point(20,60)
$lblHost.AutoSize = $true
$form.Controls.Add($lblHost)

$txtHost = New-Object System.Windows.Forms.TextBox
$txtHost.Location = New-Object System.Drawing.Point(120,58)
$txtHost.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($txtHost)

# TextBox pour logs
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20,100)
$txtLog.Size = New-Object System.Drawing.Size(440,180)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# Bouton Ajouter
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Ajouter au hosts"
$btnAdd.Location = New-Object System.Drawing.Point(20,290)
$btnAdd.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($btnAdd)

# Bouton À propos
$btnAbout = New-Object System.Windows.Forms.Button
$btnAbout.Text = "À propos"
$btnAbout.Location = New-Object System.Drawing.Point(180,290)
$btnAbout.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($btnAbout)

# Bouton Quitter
$btnQuit = New-Object System.Windows.Forms.Button
$btnQuit.Text = "Quitter"
$btnQuit.Location = New-Object System.Drawing.Point(340,290)
$btnQuit.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($btnQuit)

# Action bouton Ajouter
$btnAdd.Add_Click({
    $ip = $txtIP.Text.Trim()
    $hostname = $txtHost.Text.Trim()
    if ([string]::IsNullOrEmpty($ip) -or [string]::IsNullOrEmpty($hostname)) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez renseigner l'adresse IP et le nom d'hôte.","Erreur",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $hostsEntry = "$ip`t$hostname"
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

    # Vérifier si la dernière ligne est vide
    $hostsContent = Get-Content $hostsPath -Raw
    if ($hostsContent -notmatch "(`r`n|\n)$") {
        $hostsEntry = "`r`n$hostsEntry"
    }

    try {
        Add-Content -Path $hostsPath -Value $hostsEntry -ErrorAction Stop
        $txtLog.AppendText("Entrée ajoutée au fichier hosts.`r`n")
    }
    catch {
        $txtLog.AppendText("Erreur lors de l'écriture dans le fichier hosts : $_`r`n")
        return
    }

    # Flush DNS
    Clear-DnsClientCache
    $txtLog.AppendText("Cache DNS vidé.`r`n")

    # Vérification
    $txtLog.AppendText("Vérification du fichier hosts :`r`n")
    $txtLog.AppendText((Get-Content $hostsPath | Select-String $hostname) -join "`r`n")
    
    # Confirmation
    $res = [System.Windows.Forms.MessageBox]::Show("Confirmez la mise à jour du hosts ?","Confirmation",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        $txtLog.AppendText("Mise à jour confirmée.`r`n")
    } else {
        $txtLog.AppendText("Annulation des modifications...`r`n")
        (Get-Content $hostsPath) | Where-Object { $_ -ne $hostsEntry.Trim() } | Set-Content $hostsPath
        $txtLog.AppendText("Entrée supprimée.`r`n")
    }
})

# Action bouton À propos
$btnAbout.Add_Click({
    $aboutText = @"
Script Hosts Updater
Version 1.0
Auteur : Guillaume Clavier 2025

Mail : ironies81@proton.me
Site : http://clavier.guillaume.free.fr/logiciels/

Description : Permet d'ajouter une entrée dans le fichier hosts avec interface graphique et flush DNS.
"@
    [System.Windows.Forms.MessageBox]::Show($aboutText,"À propos",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

# Action bouton Quitter
$btnQuit.Add_Click({ $form.Close() })

[void]$form.ShowDialog()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Création de la fenêtre
$form = New-Object System.Windows.Forms.Form
$form.Text = "Reset IP & DNS"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# Bouton Démarrer
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Démarrer"
$btnStart.Location = New-Object System.Drawing.Point(20,20)
$btnStart.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnStart)

# Zone de log
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.Location = New-Object System.Drawing.Point(20,60)
$txtLog.Size = New-Object System.Drawing.Size(540,280)
$txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# Fonction pour journaliser
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("$timestamp - $message`r`n")
}

# Action du bouton
$btnStart.Add_Click({
    $btnStart.Enabled = $false
    $txtLog.Clear()
    Write-Log "Début du processus réseau..."

    try {
        Write-Log "Exécution : ipconfig /release"
        ipconfig /release | ForEach-Object { Write-Log $_ }

        Write-Log "Exécution : ipconfig /renew"
        ipconfig /renew | ForEach-Object { Write-Log $_ }

        Write-Log "Exécution : ipconfig /flushdns"
        ipconfig /flushdns | ForEach-Object { Write-Log $_ }

        Write-Log "Processus terminé avec succès."
    } catch {
        Write-Log "Erreur : $_"
    }

    $btnStart.Enabled = $true
})

# Afficher la fenêtre
[void]$form.ShowDialog()

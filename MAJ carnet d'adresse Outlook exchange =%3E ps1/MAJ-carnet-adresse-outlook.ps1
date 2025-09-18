Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Solution hybride : detection chemin script/exe ---
if ($MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptDir = Split-Path -Parent ([System.Windows.Forms.Application]::ExecutablePath)
}

# --- Fenetre principale ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mise a jour carnet d'adresse Outlook"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# --- Bouton ---
$buttonUpdate = New-Object System.Windows.Forms.Button
$buttonUpdate.Text = "Mise a jour carnet d'adresse local"
$buttonUpdate.Location = New-Object System.Drawing.Point(20,20)
$buttonUpdate.Size = New-Object System.Drawing.Size(250,30)
$form.Controls.Add($buttonUpdate)

# --- Barre de progression ---
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,60)
$progressBar.Size = New-Object System.Drawing.Size(540,25)
$form.Controls.Add($progressBar)

# --- Zone de log ---
$textBoxLog = New-Object System.Windows.Forms.TextBox
$textBoxLog.Multiline = $true
$textBoxLog.ScrollBars = "Vertical"
$textBoxLog.Location = New-Object System.Drawing.Point(20,100)
$textBoxLog.Size = New-Object System.Drawing.Size(540,220)
$textBoxLog.ReadOnly = $true
$form.Controls.Add($textBoxLog)

# --- Fonction pour ecrire dans le log ---
function Write-Log($message) {
    $textBoxLog.AppendText("$(Get-Date -Format 'HH:mm:ss') - $message`r`n")
    $textBoxLog.ScrollToCaret()
}

# --- Action du bouton ---
$buttonUpdate.Add_Click({
    try {
        Write-Log "Connexion a Outlook..."
        $Outlook   = New-Object -ComObject Outlook.Application
        $Namespace = $Outlook.GetNamespace("MAPI")

        $Groups = $Namespace.SyncObjects
        if ($Groups.Count -eq 0) {
            Write-Log "Aucun groupe d'envoi/recevoir trouve."
            return
        }

        $progressBar.Value = 0
$progressBar.Maximum = $Groups.Count

foreach ($Group in $Groups) {
    Write-Log "Synchronisation de: $($Group.Name)"
    try {
        $Group.Start()
        Start-Sleep -Seconds 2  # petit delai pour la synchro
        Write-Log " -> Terminee pour $($Group.Name)"
    } catch {
        Write-Log " -> Erreur sur $($Group.Name) : $_"
    }
    $progressBar.Value += 1   # une seule incrementation
}

        Write-Log "Mise a jour du carnet d'adresse terminee."
    }
    catch {
        Write-Log "Erreur: $_"
    }
})

# --- Afficher la fenetre ---
[void]$form.ShowDialog()
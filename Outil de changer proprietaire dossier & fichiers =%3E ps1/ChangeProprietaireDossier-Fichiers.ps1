# Auto-elevation hybride (ps1 + exe)
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $proc = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($proc -like "*.exe") {
        Start-Process $proc -Verb RunAs
    } else {
        Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Recupere l'utilisateur courant (UAC)
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Cree la fenetre
$form = New-Object Windows.Forms.Form
$form.Text = "Changement de proprietaire de dossier"
$form.Size = New-Object Drawing.Size(600, 420)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# Label utilisateur
$userLabel = New-Object Windows.Forms.Label
$userLabel.Text = "Compte utilise pour le proprietaire : $currentUser"
$userLabel.Location = New-Object Drawing.Point(10, 10)
$userLabel.AutoSize = $true
$form.Controls.Add($userLabel)

# Label chemin
$label = New-Object Windows.Forms.Label
$label.Text = "Selectionne un dossier :"
$label.Location = New-Object Drawing.Point(10, 40)
$label.AutoSize = $true
$form.Controls.Add($label)

# Textbox chemin
$textBox = New-Object Windows.Forms.TextBox
$textBox.Size = New-Object Drawing.Size(400, 20)
$textBox.Location = New-Object Drawing.Point(10, 70)
$form.Controls.Add($textBox)

# Bouton parcourir
$browseButton = New-Object Windows.Forms.Button
$browseButton.Text = "Parcourir"
$browseButton.Location = New-Object Drawing.Point(420, 68)
$form.Controls.Add($browseButton)

# Checkbox confirmation
$confirmCheckbox = New-Object Windows.Forms.CheckBox
$confirmCheckbox.Text = "Oui, utiliser ce compte comme proprietaire"
$confirmCheckbox.Location = New-Object Drawing.Point(10, 100)
$confirmCheckbox.AutoSize = $true
$form.Controls.Add($confirmCheckbox)

# Checkbox fichiers
$fileCheckbox = New-Object Windows.Forms.CheckBox
$fileCheckbox.Text = "Inclure les fichiers"
$fileCheckbox.Location = New-Object Drawing.Point(250, 100)
$fileCheckbox.AutoSize = $true
$fileCheckbox.Checked = $true
$form.Controls.Add($fileCheckbox)

# Checkbox dossiers
$folderCheckbox = New-Object Windows.Forms.CheckBox
$folderCheckbox.Text = "Inclure les dossiers"
$folderCheckbox.Location = New-Object Drawing.Point(400, 100)
$folderCheckbox.AutoSize = $true
$folderCheckbox.Checked = $true
$form.Controls.Add($folderCheckbox)

# Bouton modifier
$changeButton = New-Object Windows.Forms.Button
$changeButton.Text = "Modifier le proprietaire"
$changeButton.Location = New-Object Drawing.Point(10, 130)
$changeButton.Width = 200
$changeButton.Enabled = $false
$form.Controls.Add($changeButton)

# Zone de log
$logBox = New-Object Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$logBox.Size = New-Object Drawing.Size(560, 220)
$logBox.Location = New-Object Drawing.Point(10, 170)
$form.Controls.Add($logBox)

# Parcourir dossier
$browseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderDialog.ShowDialog() -eq "OK") {
        $textBox.Text = $folderDialog.SelectedPath
    }
})

# Activer bouton modifier si checkbox coche
$confirmCheckbox.Add_CheckedChanged({
    $changeButton.Enabled = $confirmCheckbox.Checked
})

# Fonction changement proprietaire recursive
function Set-OwnershipRecursive {
    param (
        [string]$Path,
        [bool]$IncludeFiles,
        [bool]$IncludeFolders
    )

    $Owner = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $logBox.AppendText("Nouveau proprietaire : $Owner`r`n")

    $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    $items += Get-Item -Path $Path -Force

    foreach ($item in $items) {
        # Filtrage fichiers/dossiers
        if ($item.PSIsContainer -and -not $IncludeFolders) { continue }
        if (-not $item.PSIsContainer -and -not $IncludeFiles) { continue }

        try {
            $acl = Get-Acl $item.FullName
            $acl.SetOwner([System.Security.Principal.NTAccount]$Owner)
            Set-Acl -Path $item.FullName -AclObject $acl -ErrorAction Stop
            $logBox.AppendText("OK : $($item.FullName)`r`n")
        } catch {
            $logBox.AppendText("Erreur : $($item.FullName) - $($_.Exception.Message)`r`n")
        }
    }
}

# Action bouton modifier
$changeButton.Add_Click({
    $folderPath = $textBox.Text.Trim()

    if (-not (Test-Path $folderPath)) {
        $logBox.AppendText("Chemin invalide.`r`n")
        return
    }

    $changeButton.Enabled = $false
    $logBox.AppendText("Demarrage du changement de proprietaire...`r`n")

    Set-OwnershipRecursive -Path $folderPath `
        -IncludeFiles $fileCheckbox.Checked `
        -IncludeFolders $folderCheckbox.Checked

    $logBox.AppendText("Termine.`r`n")
    $changeButton.Enabled = $true
})

# Afficher la fenetre
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
# Chargement des assemblies WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Recuperer le chemin du dossier reel (compatible ps1 et exe)
if ($MyInvocation.MyCommand.Path) {
    $CurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $CurrentPath = Split-Path -Parent ([System.Windows.Forms.Application]::ExecutablePath)
}

# Fonction pour charger les scripts d'un dossier
function Load-Scripts($path) {
    $listBox.Items.Clear()
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter *.ps1 | ForEach-Object {
            $listBox.Items.Add($_.FullName) | Out-Null
        }
    }
}

# Creer la fenetre
$form = New-Object System.Windows.Forms.Form
$form.Text = "Lanceur de Scripts PowerShell"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# Bouton Parcourir
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Parcourir..."
$btnBrowse.Location = New-Object System.Drawing.Point(10,10)
$btnBrowse.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnBrowse)

# Liste des scripts
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,50)
$listBox.Size = New-Object System.Drawing.Size(560,250)
$form.Controls.Add($listBox)

# Bouton Executer
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Executer"
$btnRun.Location = New-Object System.Drawing.Point(10,320)
$btnRun.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnRun)

# Bouton Quitter
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Quitter"
$btnExit.Location = New-Object System.Drawing.Point(470,320)
$btnExit.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnExit)

# Charger les scripts du dossier courant
Load-Scripts $CurrentPath

# Action bouton Parcourir
$btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-Scripts $folderBrowser.SelectedPath
    }
})

# Action bouton Executer
$btnRun.Add_Click({
    if ($listBox.SelectedItem) {
        $scriptPath = $listBox.SelectedItem.ToString()
        try {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
            [System.Windows.Forms.MessageBox]::Show("Script lance : `n$scriptPath","Execution")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'execution du script.","Erreur")
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez selectionner un script.","Information")
    }
})

# Action bouton Quitter
$btnExit.Add_Click({
    $form.Close()
})

# Afficher la fenetre
[void]$form.ShowDialog()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Fenetre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "Nettoyeur Excel - Verrous (~$)"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"

# Bouton selection dossier
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Choisir un dossier"
$btnBrowse.Size = New-Object System.Drawing.Size(150,30)
$btnBrowse.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($btnBrowse)

# Label dossier
$lblPath = New-Object System.Windows.Forms.Label
$lblPath.AutoSize = $true
$lblPath.Location = New-Object System.Drawing.Point(170,15)
$lblPath.Text = ""
$form.Controls.Add($lblPath)

# Liste des fichiers trouvés
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(460,250)
$listBox.Location = New-Object System.Drawing.Point(10,50)
$form.Controls.Add($listBox)

# Bouton de suppression
$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = "Supprimer les fichiers de verrouillage"
$btnDelete.Size = New-Object System.Drawing.Size(460,30)
$btnDelete.Location = New-Object System.Drawing.Point(10,310)
$form.Controls.Add($btnDelete)

# Navigateur de dossier
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

# Action : Choisir un dossier
$btnBrowse.Add_Click({
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $lblPath.Text = $folderBrowser.SelectedPath
        $listBox.Items.Clear()
        $files = Get-ChildItem -Path $folderBrowser.SelectedPath -Filter "~$*" -Force -File -ErrorAction SilentlyContinue
        if ($files.Count -eq 0) {
            $listBox.Items.Add("Aucun fichier de verrouillage trouvé.")
        } else {
            $files | ForEach-Object { $listBox.Items.Add($_.FullName) }
        }
    }
})

# Action : Supprimer les fichiers listés
$btnDelete.Add_Click({
    foreach ($item in $listBox.Items) {
        if (Test-Path $item -PathType Leaf) {
            try {
                Remove-Item $item -Force
                $listBox.Items.Remove($item)
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Erreur lors de la suppression de : `n$item", "Erreur", "OK", "Error")
            }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Nettoyage terminé.", "Succès", "OK", "Information")
})

# Afficher la fenêtre
[void]$form.ShowDialog()

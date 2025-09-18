Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Création de la fenêtre ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Scan de Dossier et de fichiers"
$form.Size = New-Object System.Drawing.Size(580, 400)
$form.StartPosition = "CenterScreen"

# === Label principal ===
$label = New-Object System.Windows.Forms.Label
$label.Text = "Choisissez un dossier à scanner :"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($label)

# === Bouton Parcourir ===
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Parcourir"
$browseButton.Size = New-Object System.Drawing.Size(100, 30)
$browseButton.Location = New-Object System.Drawing.Point(20, 50)
$form.Controls.Add($browseButton)

# === Case à cocher pour activer le filtre date ===
$dateCheckbox = New-Object System.Windows.Forms.CheckBox
$dateCheckbox.Text = "Filtrer à partir d'une date"
$dateCheckbox.AutoSize = $true
$dateCheckbox.Location = New-Object System.Drawing.Point(140, 55)
$form.Controls.Add($dateCheckbox)

# === Contrôle de date ===
$datePicker = New-Object System.Windows.Forms.DateTimePicker
$datePicker.Format = 'Short'
$datePicker.Enabled = $false
$datePicker.Location = New-Object System.Drawing.Point(300, 52)
$form.Controls.Add($datePicker)

$dateCheckbox.Add_CheckedChanged({
    $datePicker.Enabled = $dateCheckbox.Checked
})

# === Labels de sortie ===

# Simple Scan
$simpleLabel = New-Object System.Windows.Forms.Label
$simpleLabel.Text = "Simple Scan :"
$simpleLabel.AutoSize = $true
$simpleLabel.MaximumSize = New-Object System.Drawing.Size(630, 0)
$simpleLabel.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($simpleLabel)

$simpleCount = New-Object System.Windows.Forms.Label
$simpleCount.Text = ""
$simpleCount.AutoSize = $true
$simpleCount.Location = New-Object System.Drawing.Point(40, 125)
$form.Controls.Add($simpleCount)

# Expert Scan
$expertLabel = New-Object System.Windows.Forms.Label
$expertLabel.Text = "Expert Scan :"
$expertLabel.AutoSize = $true
$expertLabel.MaximumSize = New-Object System.Drawing.Size(630, 0)
$expertLabel.Location = New-Object System.Drawing.Point(20, 160)
$form.Controls.Add($expertLabel)

$expertCount = New-Object System.Windows.Forms.Label
$expertCount.Text = ""
$expertCount.AutoSize = $true
$expertCount.Location = New-Object System.Drawing.Point(40, 185)
$form.Controls.Add($expertCount)

# Files Scan
$fileLabel = New-Object System.Windows.Forms.Label
$fileLabel.Text = "Fichiers trouvés :"
$fileLabel.AutoSize = $true
$fileLabel.MaximumSize = New-Object System.Drawing.Size(630, 0)
$fileLabel.Location = New-Object System.Drawing.Point(20, 220)
$form.Controls.Add($fileLabel)

$fileCount = New-Object System.Windows.Forms.Label
$fileCount.Text = ""
$fileCount.AutoSize = $true
$fileCount.Location = New-Object System.Drawing.Point(40, 245)
$form.Controls.Add($fileCount)

# === Bouton Ouvrir le dossier ===
$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "Ouvrir le dossier"
$openFolderButton.Size = New-Object System.Drawing.Size(150, 30)
$openFolderButton.Location = New-Object System.Drawing.Point(20, 290)
$openFolderButton.Enabled = $false
$form.Controls.Add($openFolderButton)

# === Action bouton Parcourir ===
$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $selectedPath = $folderBrowser.SelectedPath
        $folderName = Split-Path $selectedPath -Leaf

        $outputDir = "C:\temps"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory | Out-Null
        }

        $simpleCsv = Join-Path $outputDir "$folderName`_simple-scan.csv"
        $expertCsv = Join-Path $outputDir "$folderName`_expert-scan.csv"
        $filesCsv  = Join-Path $outputDir "$folderName`_files-scan.csv"

        $filterDateEnabled = $dateCheckbox.Checked
        $filterDate = $datePicker.Value

        # === Simple Scan ===
        $simpleDirs = Get-ChildItem -Path $selectedPath -Directory
        if ($filterDateEnabled) {
            $simpleDirs = $simpleDirs | Where-Object { $_.LastWriteTime -ge $filterDate }
        }
        $simpleDirs | Select-Object FullName | Export-Csv -Path $simpleCsv -NoTypeInformation -Encoding UTF8
        $simpleLabel.Text = "Simple Scan : $simpleCsv"
        $simpleCount.Text = "Nombre de dossiers : " + ($simpleDirs.Count)

        # === Expert Scan ===
        $expertDirs = Get-ChildItem -Path $selectedPath -Directory -Recurse
        if ($filterDateEnabled) {
            $expertDirs = $expertDirs | Where-Object { $_.LastWriteTime -ge $filterDate }
        }
        $expertDirs | Select-Object FullName | Export-Csv -Path $expertCsv -NoTypeInformation -Encoding UTF8
        $expertLabel.Text = "Expert Scan : $expertCsv"
        $expertCount.Text = "Nombre de dossiers : " + ($expertDirs.Count)

        # === Files Scan ===
        $files = Get-ChildItem -Path $selectedPath -File -Recurse
        if ($filterDateEnabled) {
            $files = $files | Where-Object { $_.LastWriteTime -ge $filterDate }
        }
        $files | Select-Object FullName | Export-Csv -Path $filesCsv -NoTypeInformation -Encoding UTF8
        $fileLabel.Text = "Fichiers trouvés : $filesCsv"
        $fileCount.Text = "Nombre de fichiers : " + ($files.Count)

        # === Activer bouton d’ouverture
        $openFolderButton.Enabled = $true
    }
})

# === Action bouton Ouvrir le dossier ===
$openFolderButton.Add_Click({
    Start-Process "explorer.exe" "C:\temps"
})

# === Affichage de la fenêtre ===
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

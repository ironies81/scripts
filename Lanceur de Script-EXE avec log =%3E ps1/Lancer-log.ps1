Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---- Fenêtre principale ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Lanceur de Script/EXE sans interaction et avec affichage des logs"
$form.Size = '620,430'
$form.StartPosition = "CenterScreen"

# Activer le bouton d'aide
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.HelpButton = $true

# Evénement au clic sur le ?
$form.Add_HelpButtonClicked({
    [System.Windows.Forms.MessageBox]::Show(
        "Outil créé par Guillaume Clavier - 2025`r`nPour toute remarque: ironies81@proton.me",
        "À propos",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

# ---- Contrôles utilisateur ----
$labelFile = New-Object System.Windows.Forms.Label
$labelFile.Text = "Chemin du script ou exe :"
$labelFile.Location = '10,15'
$labelFile.Size = '180,20'

$textFile = New-Object System.Windows.Forms.TextBox
$textFile.Location = '200,13'
$textFile.Size = '320,22'

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Parcourir"
$btnBrowse.Location = '530,13'
$btnBrowse.Size = '65,22'

$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "Relancer toutes les 5 minutes"
$chkAuto.Location = '10,45'
$chkAuto.Size = '200,22'

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Exécuter"
$btnRun.Location = '220,45'
$btnRun.Size = '110,28'

# ---- Zone de log améliorée ----
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = '10,85'
$txtLog.Size = '585,300'
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtLog.BackColor = [System.Drawing.Color]::Black
$txtLog.ForeColor = [System.Drawing.Color]::White

# ---- Timer relance ----
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300000 #5 minutes

# ---- OpenFileDialog ----
$openFile = New-Object System.Windows.Forms.OpenFileDialog
$openFile.Filter = "Scripts / Executables (*.ps1;*.bat;*.cmd;*.exe)|*.ps1;*.bat;*.cmd;*.exe|Tous les fichiers|*.*"

# Fonction : ajouter texte coloré
function Append-ColoredText([string]$text, [System.Drawing.Color]$color) {
    $txtLog.SelectionColor = $color
    $txtLog.AppendText($text)
    $txtLog.SelectionColor = $txtLog.ForeColor
}

# Fonction principale d'exécution
function Run-SelectedFile {
    $txtLog.Clear()
    $path = $textFile.Text
    if (-not (Test-Path $path)) {
        Append-ColoredText "Fichier introuvable : $path`r`n" ([System.Drawing.Color]::Red)
        return
    }
    Append-ColoredText "Veuillez patienter durant l'exécution de : $path`r`n" ([System.Drawing.Color]::Gold)

    try {
        if ($path -match "\.ps1$") {
            $output = powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$path" 2>&1
        } else {
            $output = & "$path" 2>&1
        }

        foreach ($line in $output) {
            if ($line -match "^Speedtest by Ookla")           { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::DeepSkyBlue) }
            elseif ($line -match "^Server:")                  { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Cyan) }
            elseif ($line -match "^ISP:")                     { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Cyan) }
            elseif ($line -match "Idle Latency")              { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Gray) }
            elseif ($line -match "^Download")                 { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Lime) }
            elseif ($line -match "Upload")                    { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Orange) }
            elseif ($line -match "Packet Loss|Erreur")        { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::Red) }
            elseif ($line -match "Result URL")                { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::MediumPurple) }
            else                                              { Append-ColoredText "$line`r`n" ([System.Drawing.Color]::White) }
        }
    } catch {
        Append-ColoredText "Erreur lors de l'exécution : $_`r`n" ([System.Drawing.Color]::Red)
    }
    Append-ColoredText "-- Fin d'exécution --`r`n" ([System.Drawing.Color]::Gold)

    if ($chkAuto.Checked) {
        Append-ColoredText "Relance programmée toutes les 5 minutes.`r`n" ([System.Drawing.Color]::DeepSkyBlue)
    }
}

$btnBrowse.Add_Click({
    if ($openFile.ShowDialog() -eq "OK") {
        $textFile.Text = $openFile.FileName
    }
})

$btnRun.Add_Click({
    Run-SelectedFile
    if ($chkAuto.Checked)     { $timer.Start() }
    else                      { $timer.Stop() }
})

$timer.Add_Tick({ Run-SelectedFile })

$form.Controls.Add($labelFile)
$form.Controls.Add($textFile)
$form.Controls.Add($btnBrowse)
$form.Controls.Add($chkAuto)
$form.Controls.Add($btnRun)
$form.Controls.Add($txtLog)

$form.Add_FormClosing({ $timer.Stop() })
[void]$form.ShowDialog()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions

# === CONFIGURATION ===
$installFolder = "C:\_install"
$configPath = Join-Path $installFolder "config_script_launcher.json"
$logFile = Join-Path $installFolder "log_execution.txt"

if (-not (Test-Path $installFolder)) {
    New-Item -ItemType Directory -Path $installFolder | Out-Null
}

# === CHARGER CONFIG ===
$config = @{
    LastPath = ""
    AutoStart = $false
    Loop = $false
}
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Output "❌ Erreur chargement config. Valeurs par défaut utilisées."
    }
}

# === UI ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Lanceur de scripts avec répétition"
$form.Size = New-Object System.Drawing.Size(600, 480)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# === Label chemin ===
$labelPath = New-Object System.Windows.Forms.Label
$labelPath.Text = "Dossier des scripts :"
$labelPath.Location = New-Object System.Drawing.Point(10, 20)
$labelPath.Size = New-Object System.Drawing.Size(130, 20)
$form.Controls.Add($labelPath)

# === TextBox chemin
$textBoxPath = New-Object System.Windows.Forms.TextBox
$textBoxPath.Location = New-Object System.Drawing.Point(150, 18)
$textBoxPath.Size = New-Object System.Drawing.Size(320, 20)
$textBoxPath.Text = $config.LastPath
$form.Controls.Add($textBoxPath)

# === Bouton Parcourir
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Parcourir"
$btnBrowse.Location = New-Object System.Drawing.Point(480, 16)
$btnBrowse.Size = New-Object System.Drawing.Size(80, 24)
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $textBoxPath.Text = $dialog.SelectedPath
    }
})
$form.Controls.Add($btnBrowse)

# === CheckBox Boucle infinie
$chkLoop = New-Object System.Windows.Forms.CheckBox
$chkLoop.Text = "Exécuter en boucle infinie"
$chkLoop.Location = New-Object System.Drawing.Point(150, 50)
$chkLoop.Size = New-Object System.Drawing.Size(200, 20)
$chkLoop.Checked = [bool]$config.Loop
$form.Controls.Add($chkLoop)

# === CheckBox Auto Start
$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "Auto Start au lancement"
$chkAuto.Location = New-Object System.Drawing.Point(150, 70)
$chkAuto.Size = New-Object System.Drawing.Size(200, 20)
$chkAuto.Checked = [bool]$config.AutoStart
$form.Controls.Add($chkAuto)

# === Bouton Lancer
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Lancer l'exécution"
$btnStart.Location = New-Object System.Drawing.Point(380, 60)
$btnStart.Size = New-Object System.Drawing.Size(180, 30)
$form.Controls.Add($btnStart)

# === Zone log
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(10, 110)
$logBox.Size = New-Object System.Drawing.Size(560, 320)
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

# === Fonction log
function Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $msg"
    $logBox.AppendText("$line`r`n")
    $logBox.ScrollToCaret()
    Add-Content -Path $logFile -Value $line
}

# === Sauvegarde config
function Save-Config {
    $config.LastPath = $textBoxPath.Text
    $config.Loop = $chkLoop.Checked
    $config.AutoStart = $chkAuto.Checked
    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8
}

# === Variable de blocage d'exécution multiple
$scriptEnCours = $false

# === Exécution des scripts
function Execute-Scripts($folder, $loopMode) {
    do {
        $scripts = Get-ChildItem -Path $folder -File | Where-Object { $_.Extension -in ".ps1", ".bat" } | Sort-Object Name
        if ($scripts.Count -eq 0) {
            Log "Aucun script trouvé dans : $folder"
            break
        }

        foreach ($script in $scripts) {
            Log "Démarrage : $($script.Name)"
            try {
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = if ($script.Extension -eq ".bat") { $script.FullName } else { "powershell.exe" }
                $psi.Arguments = if ($script.Extension -eq ".bat") { "" } else { "-ExecutionPolicy Bypass -File `"$($script.FullName)`"" }
                $psi.UseShellExecute = $false
                $psi.CreateNoWindow = $true

                $process = [System.Diagnostics.Process]::Start($psi)
                while (-not $process.HasExited) {
                    Start-Sleep -Milliseconds 200
                    [System.Windows.Forms.Application]::DoEvents()
                }

                Log "Terminé : $($script.Name)"
            }
            catch {
                Log "Erreur : $($_.Exception.Message)"
            }
        }

        if (-not $loopMode) { break }
        Log "Redémarrage de la boucle..."
    } while ($loopMode)
}

# === Action bouton Lancer
$btnStart.Add_Click({
    if ($scriptEnCours) {
        [System.Windows.Forms.MessageBox]::Show("Un job est déjà en cours.", "Info", 'OK', 'Information')
        return
    }

    $path = $textBoxPath.Text
    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Dossier invalide.", "Erreur", 'OK', 'Error')
        return
    }

    Save-Config
    $logBox.Clear()
    Clear-Content -Path $logFile -ErrorAction SilentlyContinue

    $scriptEnCours = $true
    try {
        Execute-Scripts -folder $path -loopMode $chkLoop.Checked
    } finally {
        $scriptEnCours = $false
    }
})

# === Auto Start dès l'affichage
$form.Add_Shown({
    if ($config.AutoStart -and (Test-Path $config.LastPath)) {
        $textBoxPath.Text = $config.LastPath
        $chkLoop.Checked = [bool]$config.Loop
        $chkAuto.Checked = [bool]$config.AutoStart

        $logBox.Clear()
        Clear-Content -Path $logFile -ErrorAction SilentlyContinue

        $scriptEnCours = $true
        try {
            Execute-Scripts -folder $config.LastPath -loopMode $config.Loop
        } finally {
            $scriptEnCours = $false
        }
    }
})

# === Lancer l'interface
[System.Windows.Forms.Application]::Run($form)

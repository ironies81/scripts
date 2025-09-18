Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Icône ---
$iconPath = "$PSScriptRoot\_install\AutoPower\battery.ico"  # Mets ici le chemin de ton icone téléchargée
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
$notifyIcon.Visible = $true
$notifyIcon.Text = "AutoPower"

# --- GUID des plans d'alimentation ---
$powerSaver   = "a1841308-3541-4fab-bc81-f71556f20b4a" # Economie d'energie
$highPerf     = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" # Performances max

# --- Etat actuel ---
$global:lastPowerSource = $null
$global:lastPowerPlan   = $null

# --- Menu contextuel ---
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$quitMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$quitMenu.Text = "Quitter"
$quitMenu.Add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})
$contextMenu.Items.Add($quitMenu) | Out-Null

$notifyIcon.ContextMenuStrip = $contextMenu

# --- Fonction pour appliquer un plan ---
function Set-PowerPlan($planGuid, $planName) {
    try {
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive $planGuid" -WindowStyle Hidden -Wait
        if ($global:lastPowerPlan -ne $planName) {
            $notifyIcon.ShowBalloonTip(3000, "AutoPower", "Mode changé : $planName", [System.Windows.Forms.ToolTipIcon]::Info)
            $global:lastPowerPlan = $planName
        }
    } catch {
        $notifyIcon.ShowBalloonTip(3000, "Erreur AutoPower", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
    }
}

# --- Timer pour vérifier l'état batterie/secteur ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000  # toutes les 5 secondes
$timer.Add_Tick({
    $powerStatus = [System.Windows.Forms.SystemInformation]::PowerStatus
    $isPlugged = $powerStatus.PowerLineStatus -eq "Online"

    if ($isPlugged -and $global:lastPowerSource -ne "Secteur") {
        Set-PowerPlan $highPerf "Performances maximales"
        $global:lastPowerSource = "Secteur"
    }
    elseif (-not $isPlugged -and $global:lastPowerSource -ne "Batterie") {
        Set-PowerPlan $powerSaver "Economie d'énergie"
        $global:lastPowerSource = "Batterie"
    }
})

$timer.Start()

# --- Boucle de l'appli ---
[System.Windows.Forms.Application]::Run()
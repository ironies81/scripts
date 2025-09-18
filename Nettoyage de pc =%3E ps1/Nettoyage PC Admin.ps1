Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Detection du chemin du script (compatible PS1 et EXE) ---
try {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} catch {
    $ScriptRoot = Split-Path -Parent ([System.Windows.Forms.Application]::ExecutablePath)
}

# --- Elevation de privileges si necessaire ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Le script va se relancer avec les droits administrateur.", "Elevation requise", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Fonction d'ecriture dans la fenetre de log ---
function Write-Log($message, [System.Drawing.Color]$color = [System.Drawing.Color]::Black) {
    $richTextBox.SelectionColor = $color
    $richTextBox.AppendText("$message`r`n")
    $richTextBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# --- Nettoyage principal ---
function Start-Cleanup {
    $btnRun.Enabled = $false
    Write-Log "=== Debut du nettoyage ===" ([System.Drawing.Color]::Blue)

    # 1. Desactivation hibernation
    Write-Log "[1] Desactivation hibernation..."
    powercfg -h off | Out-Null

    # 2. Cleanmgr options
    Write-Log "[2] Configuration nettoyage disque..."
    $cleanmgrKeys = @(
        'Active Setup Temp Folders','BranchCache','Content Indexer Cleaner','Device Driver Packages',
        'Downloaded Program Files','GameNewsFiles','GameStatisticsFiles','GameUpdateFiles',
        'Internet Cache Files','Memory Dump Files','Offline Pages Files','Old ChkDsk Files',
        'Previous Installations','Recycle Bin','Service Pack Cleanup','Setup Log Files',
        'System error memory dump files','System error minidump files','Temporary Files',
        'Temporary Setup Files','Temporary Sync Files','Thumbnail Cache','Update Cleanup',
        'Upgrade Discarded Files','User file versions','Windows Defender',
        'Windows Error Reporting Archive Files','Windows Error Reporting Queue Files',
        'Windows Error Reporting System Archive Files','Windows Error Reporting System Queue Files',
        'Windows ESD installation files','Windows Upgrade Log Files'
    )
    foreach ($key in $cleanmgrKeys) {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$key"
        if (Test-Path $regPath) {
            New-ItemProperty -Path $regPath -Name StateFlags0001 -Value 1 -PropertyType DWord -Force | Out-Null
        }
    }

    # 3. Lancer cleanmgr
    Write-Log "[3] Nettoyage disque (cleanmgr)..."
    Start-Process -FilePath cleanmgr.exe -ArgumentList '/sagerun:1' -Wait

    # 4. Gestion du pagefile.sys
    Write-Log "[4] Verification RAM / pagefile.sys..."
    $pagefileUsage = Get-CimInstance -ClassName Win32_PageFileUsage
    $totalRAMGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    Write-Log "RAM detectee : $totalRAMGB Go"
    if ($pagefileUsage) {
        if ($totalRAMGB -gt 16) {
            Write-Log "Plus de 16 Go RAM -> suppression du pagefile.sys" ([System.Drawing.Color]::DarkOrange)
            $computerSystem = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
            $computerSystem.AutomaticManagedPagefile = $false
            $computerSystem.Put() | Out-Null
            $pagefileSettings = Get-WmiObject -Query "Select * From Win32_PageFileSetting"
            foreach ($setting in $pagefileSettings) { $setting.Delete() | Out-Null }
            Write-Log "Pagefile.sys desactive (redemarrage requis)" ([System.Drawing.Color]::Red)
        } else {
            Write-Log "Moins de 16 Go RAM -> pagefile.sys conserve" ([System.Drawing.Color]::Green)
        }
    }

    # 5. Dism clean
    Write-Log "[5] Nettoyage composants..."
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    Dism.exe /Online /Cleanup-Image /SPSuperseded | Out-Null

    # 6. Suppression fichiers temporaires
    Write-Log "[6] Suppression fichiers temporaires..."
    Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # 7. Windows Update cache
    Write-Log "[7] Nettoyage cache Windows Update..."
    Stop-Service -Name wuauserv -Force
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv

    # 8. Suppression Windows.old
    Write-Log "[8] Suppression Windows.old si present..."
    if (Test-Path "C:\Windows.old") {
        Remove-Item -Path "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Windows.old supprime" ([System.Drawing.Color]::DarkOrange)
    } else {
        Write-Log "Aucun Windows.old detecte"
    }

    # 9. Suppression caches et prefetch
    Write-Log "[9] Nettoyage cache Edge/IE/Prefetch..."
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "=== Fin du nettoyage ===" ([System.Drawing.Color]::Blue)
    $btnRun.Enabled = $true
}

# --- Fenetre principale ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Outil de Nettoyage Windows"
$form.Width = 400
$form.Height = 300
$form.StartPosition = "CenterScreen"

# Zone de log
$richTextBox = New-Object System.Windows.Forms.RichTextBox
$richTextBox.Dock = "Fill"
$richTextBox.ReadOnly = $true
$form.Controls.Add($richTextBox)

# Bouton lancer
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Lancer le nettoyage"
$btnRun.Dock = "Bottom"
$btnRun.Height = 40
$btnRun.Add_Click({ Start-Cleanup })
$form.Controls.Add($btnRun)

# Menu
$menu = New-Object System.Windows.Forms.MenuStrip
$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Fichier")
$quitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Quitter")
$quitItem.add_Click({ $form.Close() })
$fileMenu.DropDownItems.Add($quitItem)
$menu.Items.Add($fileMenu)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Aide")
$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem("A propos")
$aboutItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Outil de Nettoyage Windows`nContact : ironies81@proton.me`nSite : http://clavier.guillaume.free.fr/logiciels/", "A propos", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$helpMenu.DropDownItems.Add($aboutItem)
$menu.Items.Add($helpMenu)

[void]$form.ShowDialog()
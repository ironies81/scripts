# WinForms Domain Rejoin Tool - compatible ps1 et exe
# Avec liens clicables soulignes dans "A propos"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----- CONFIG A PROPOS -----
$AboutEmail = "ironies81@proton.me"
$AboutSite  = "http://clavier.guillaume.free.fr/logiciels/"

# ----- DETECTION DU CHEMIN DE SCRIPT / EXE (hybride) -----
$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptPath)) {
    try {
        $entry = [System.Reflection.Assembly]::GetEntryAssembly()
        if ($entry -ne $null) {
            $scriptPath = $entry.Location
        } else {
            $scriptPath = (Get-Process -Id $PID).MainModule.FileName
        }
    } catch {
        $scriptPath = (Get-Process -Id $PID).MainModule.FileName
    }
}

# ----- FONCTION: verifier si on est admin -----
function Test-IsAdmin {
    $wi = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = New-Object System.Security.Principal.WindowsPrincipal($wi)
    return $wp.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ----- FONCTION: relancer avec UAC -----
function Ensure-RunAsAdmin {
    param([string]$PathToRun)
    if (-not (Test-IsAdmin)) {
        if ($PathToRun -and (Test-Path $PathToRun)) {
            if ($PathToRun.ToLower().EndsWith(".ps1")) {
                $pwsh = $PSHOME + "\powershell.exe"
                $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PathToRun`""
                Start-Process -FilePath $pwsh -ArgumentList $arg -Verb RunAs
                return $true
            } else {
                Start-Process -FilePath $PathToRun -Verb RunAs
                return $true
            }
        } else {
            $pwsh = $PSHOME + "\powershell.exe"
            $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            Start-Process -FilePath $pwsh -ArgumentList $arg -Verb RunAs
            return $true
        }
    }
    return $false
}

# ----- Elevation si necessaire -----
if (-not (Test-IsAdmin)) {
    $res = [System.Windows.Forms.MessageBox]::Show("Le programme doit etre execute en mode administrateur.`nVoulez-vous relancer avec UAC ?","Demande de droits","YesNo","Question")
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        $ok = Ensure-RunAsAdmin -PathToRun $scriptPath
        if ($ok) { exit }
    }
}

# ----- Fenetre principale -----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Connecter / Reconnecter au domaine"
$form.Size = New-Object System.Drawing.Size(620,420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# ----- MenuStrip -----
$menu = New-Object System.Windows.Forms.MenuStrip
$menuItemFile = New-Object System.Windows.Forms.ToolStripMenuItem("Fichier")
$menuItemQuit = New-Object System.Windows.Forms.ToolStripMenuItem("Quitter")
$menuItemHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Aide")
$menuItemAbout = New-Object System.Windows.Forms.ToolStripMenuItem("A propos")

$menuItemFile.DropDownItems.Add($menuItemQuit) | Out-Null
$menuItemHelp.DropDownItems.Add($menuItemAbout) | Out-Null
$menu.Items.AddRange(@($menuItemFile, $menuItemHelp)) | Out-Null
$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

$menuItemQuit.Add_Click({ $form.Close() })

# ----- Fenetre A propos -----
$menuItemAbout.Add_Click({
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "A propos"
    $aboutForm.Size = New-Object System.Drawing.Size(400,200)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = "FixedDialog"
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false

    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "Pour plus d'informations :"
    $lblInfo.AutoSize = $true
    $lblInfo.Location = New-Object System.Drawing.Point(20,20)
    $aboutForm.Controls.Add($lblInfo)

    # Lien Mail
    $linkMail = New-Object System.Windows.Forms.LinkLabel
    $linkMail.Text = $AboutEmail
    $linkMail.Location = New-Object System.Drawing.Point(20,50)
    $linkMail.AutoSize = $true
    $linkMail.LinkColor = [System.Drawing.Color]::Blue
    $linkMail.ActiveLinkColor = [System.Drawing.Color]::Red
    $linkMail.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,[System.Drawing.FontStyle]::Underline)
    $linkMail.Add_Click({ Start-Process "mailto:$AboutEmail" })
    $aboutForm.Controls.Add($linkMail)

    # Lien Site
    $linkSite = New-Object System.Windows.Forms.LinkLabel
    $linkSite.Text = $AboutSite
    $linkSite.Location = New-Object System.Drawing.Point(20,80)
    $linkSite.AutoSize = $true
    $linkSite.LinkColor = [System.Drawing.Color]::Blue
    $linkSite.ActiveLinkColor = [System.Drawing.Color]::Red
    $linkSite.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,[System.Drawing.FontStyle]::Underline)
    $linkSite.Add_Click({ Start-Process $AboutSite })
    $aboutForm.Controls.Add($linkSite)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "Fermer"
    $btnOK.Location = New-Object System.Drawing.Point(280,120)
    $btnOK.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($btnOK)

    $aboutForm.ShowDialog() | Out-Null
})

# ----- Labels et TextBoxes -----
$lblDomain = New-Object System.Windows.Forms.Label
$lblDomain.Text = "Nom du domaine (ex: mondomaine.local)"
$lblDomain.AutoSize = $true
$lblDomain.Location = New-Object System.Drawing.Point(20,40)
$form.Controls.Add($lblDomain)

$txtDomain = New-Object System.Windows.Forms.TextBox
$txtDomain.Location = New-Object System.Drawing.Point(20,60)
$txtDomain.Size = New-Object System.Drawing.Size(420,22)
$form.Controls.Add($txtDomain)

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Nom d'utilisateur (ex: MONDOMAINE\\adminjoin)"
$lblUser.AutoSize = $true
$lblUser.Location = New-Object System.Drawing.Point(20,95)
$form.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(20,115)
$txtUser.Size = New-Object System.Drawing.Size(420,22)
$form.Controls.Add($txtUser)

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Mot de passe"
$lblPass.AutoSize = $true
$lblPass.Location = New-Object System.Drawing.Point(20,150)
$form.Controls.Add($lblPass)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(20,170)
$txtPass.Size = New-Object System.Drawing.Size(420,22)
$txtPass.UseSystemPasswordChar = $true
$form.Controls.Add($txtPass)

# ----- Boutons -----
$btnJoin = New-Object System.Windows.Forms.Button
$btnJoin.Text = "Connecter / Reconnecter au domaine"
$btnJoin.Location = New-Object System.Drawing.Point(460,60)
$btnJoin.Size = New-Object System.Drawing.Size(140,40)
$form.Controls.Add($btnJoin)

$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = "Redemarrer maintenant"
$btnRestart.Location = New-Object System.Drawing.Point(460,100)
$btnRestart.Size = New-Object System.Drawing.Size(140,40)
$form.Controls.Add($btnRestart)

# ----- Zone log -----
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Logs"
$lblLog.AutoSize = $true
$lblLog.Location = New-Object System.Drawing.Point(20,205)
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20,225)
$txtLog.Size = New-Object System.Drawing.Size(560,140)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

# ----- Helper: ecrire dans le log -----
function Write-Log {
    param([string]$Text, [switch]$Error)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $Text"
    $txtLog.AppendText($line + [Environment]::NewLine)
    if ($Error) { Write-Host $line -ForegroundColor Red } else { Write-Host $line }
}

# ----- Handler: Bouton Reconnecter -----
$btnJoin.Add_Click({
    $domain = $txtDomain.Text.Trim()
    $user   = $txtUser.Text.Trim()
    $pass   = $txtPass.Text

    if ([string]::IsNullOrEmpty($domain) -or [string]::IsNullOrEmpty($user) -or [string]::IsNullOrEmpty($pass)) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez remplir domaine, utilisateur et mot de passe.","Erreur","OK","Warning") | Out-Null
        return
    }

    try {
        $secure = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred   = New-Object System.Management.Automation.PSCredential($user, $secure)
    } catch {
        Write-Log "Erreur conversion mot de passe: $_" -Error
        return
    }

    Write-Log "Tentative de reconnexion au domaine $domain avec l'utilisateur $user..."
    try {
        Add-Computer -DomainName $domain -Credential $cred -Force -ErrorAction Stop
        Write-Log "✅ Le PC a ete reconnecte au domaine avec succes. Un redemarrage est requis."
        $reboot = [System.Windows.Forms.MessageBox]::Show("Le PC a ete reconnecte au domaine.`nRedemarrer maintenant ?","Succes","YesNo","Question")
        if ($reboot -eq [System.Windows.Forms.DialogResult]::Yes) {
            Restart-Computer -Force
        }
    } catch {
        Write-Log "❌ Echec de la reconnexion au domaine : $_" -Error
        [System.Windows.Forms.MessageBox]::Show("Echec de la reconnexion au domaine.`nVoir les logs.","Erreur","OK","Error") | Out-Null
    }
})

# ----- Handler: Redemarrer -----
$btnRestart.Add_Click({
    $res = [System.Windows.Forms.MessageBox]::Show("Voulez-vous redemarrer le PC maintenant ?","Redemarrage","YesNo","Question")
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        Restart-Computer -Force
    }
})

# ----- Lancer -----
$form.Add_Shown({ $txtDomain.Focus() })
[void] $form.ShowDialog()
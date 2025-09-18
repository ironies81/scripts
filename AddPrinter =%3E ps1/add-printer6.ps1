# Chargement des assemblages Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Vérification des privilèges administrateur
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    [System.Windows.Forms.MessageBox]::Show("Veuillez exécuter l'application en tant qu'administrateur.") | Out-Null
    Exit
}

# Fenêtre pour entrer le nom du serveur
$inputForm = New-Object System.Windows.Forms.Form
$inputForm.Text = "Serveur d'impression"
$inputForm.Size = New-Object System.Drawing.Size(300,150)
$inputForm.StartPosition = "CenterScreen"
$inputForm.Topmost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Serveur d'impression (nom ou IP) :"
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(260,20)
$inputForm.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,50)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$inputForm.Controls.Add($textBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(100,80)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Add_Click({
    $script:printerServer = $textBox.Text.Trim()
    $inputForm.Close()
})
$inputForm.Controls.Add($okButton)

$inputForm.AcceptButton = $okButton
$inputForm.ShowDialog() | Out-Null

if ([string]::IsNullOrEmpty($script:printerServer)) {
    [System.Windows.Forms.MessageBox]::Show("Aucun serveur d'impression spécifié. L'application va se terminer.") | Out-Null
    Exit
}

# Récupération des imprimantes avec timeout
function Get-AvailablePrinters {
    try {
        $params = @{
            ClassName    = 'Win32_Printer'
            ComputerName = $script:printerServer
            ErrorAction  = 'Stop'
        }
        
        $printers = Get-CimInstance @params | 
                    Where-Object { $_.Shared -eq $true -and $_.ShareName } |
                    Sort-Object ShareName
        
        return $printers
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur de connexion au serveur: $_") | Out-Null
        return @()
    }
}

# Vérification existence imprimante
function Test-PrinterInstalled {
    param ([string]$printerName)
    try {
        $existing = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
        return ($null -ne $existing)
    } catch {
        return $false
    }
}

# Installation avec option défaut
function Install-Printer {
    param ([string]$printerName)
    
    $printerPath = "\\$script:printerServer\$printerName"
    try {
        if (Test-PrinterInstalled -printerName $printerName) {
            $msg = "L'imprimante existe déjà !`nVoulez-vous la réinstaller ?"
            $result = [System.Windows.Forms.MessageBox]::Show($msg, "Confirmation", 4)
            if ($result -ne 'Yes') { return 'Ignoré' }
        }
        
        Add-Printer -ConnectionName $printerPath -ErrorAction Stop
        
        $msg = "Définir comme imprimante par défaut ?"
        $defaultResult = [System.Windows.Forms.MessageBox]::Show($msg, "Par défaut", 4)
        
        if ($defaultResult -eq 'Yes') {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter($printerPath)
        }
        
        return 'Succès'
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur d'installation : $_") | Out-Null
        return 'Échec'
    }
}

# Désinstallation
function Uninstall-Printer {
    param ([string]$printerName)
    try {
        # Recherche l'imprimante par son nom d'affichage
        $printer = Get-Printer | Where-Object {$_.Name -eq $printerName}
        if ($printer) {
            # Désinstalle l'imprimante en utilisant le nom correct
            Remove-Printer -Name $printer.Name -ErrorAction Stop
            return $true
        } else {
            [System.Windows.Forms.MessageBox]::Show("L'imprimante '$printerName' n'a pas été trouvée.") | Out-Null
            return $false
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur de désinstallation : $_") | Out-Null
        return $false
    }
}

# Actualisation liste installée
function Update-InstalledList {
    $listInstalled.Items.Clear()
    try {
        # Récupère toutes les imprimantes installées localement
        Get-Printer | ForEach-Object {
            # Affiche toutes les imprimantes installées localement
            $listInstalled.Items.Add($_.Name) | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur lors de la récupération des imprimantes installées: $_") | Out-Null
    }
}

# Interface utilisateur avancée
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestion des imprimantes - $script:printerServer"
$form.Size = New-Object System.Drawing.Size(800,500)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# Panneaux
$gbAvailable = New-Object System.Windows.Forms.GroupBox
$gbAvailable.Text = "Imprimantes disponibles ($script:printerServer)"
$gbAvailable.Location = New-Object System.Drawing.Point(10,10)
$gbAvailable.Size = New-Object System.Drawing.Size(380,400)

$gbInstalled = New-Object System.Windows.Forms.GroupBox
$gbInstalled.Text = "Imprimantes installées"
$gbInstalled.Location = New-Object System.Drawing.Point(400,10)
$gbInstalled.Size = New-Object System.Drawing.Size(380,400)

# Listes
$listAvailable = New-Object System.Windows.Forms.ListBox
$listAvailable.Location = New-Object System.Drawing.Point(10,20)
$listAvailable.Size = New-Object System.Drawing.Size(360,300)

$listInstalled = New-Object System.Windows.Forms.ListBox
$listInstalled.Location = New-Object System.Drawing.Point(10,20)
$listInstalled.Size = New-Object System.Drawing.Size(360,300)

# Boutons
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Installer"
$btnInstall.Location = New-Object System.Drawing.Point(10,330)
$btnInstall.Size = New-Object System.Drawing.Size(170,30)

$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "Désinstaller"
$btnUninstall.Location = New-Object System.Drawing.Point(190,330)
$btnUninstall.Size = New-Object System.Drawing.Size(170,30)

$btnRefreshInstalled = New-Object System.Windows.Forms.Button
$btnRefreshInstalled.Text = "Actualiser"
$btnRefreshInstalled.Location = New-Object System.Drawing.Point(10,370)
$btnRefreshInstalled.Size = New-Object System.Drawing.Size(170,30)

# Événements
$btnInstall.Add_Click({
    if ($listAvailable.SelectedItem) {
        $result = Install-Printer -printerName $listAvailable.SelectedItem
        if ($result -eq 'Succès') { Update-InstalledList }
    }
})

$btnUninstall.Add_Click({
    if ($listInstalled.SelectedItem) {
        if ([System.Windows.Forms.MessageBox]::Show("Confirmer la désinstallation ?", "Confirmation", 4) -eq 'Yes') {
            $result = Uninstall-Printer -printerName $listInstalled.SelectedItem
            if ($result) { Update-InstalledList }
        }
    }
})

$btnRefreshInstalled.Add_Click({ Update-InstalledList })

# Assemblage UI
$gbAvailable.Controls.AddRange(@($listAvailable, $btnInstall))
$gbInstalled.Controls.AddRange(@($listInstalled, $btnUninstall, $btnRefreshInstalled))
$form.Controls.AddRange(@($gbAvailable, $gbInstalled))

# Chargement initial
$printers = Get-AvailablePrinters
if ($printers.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Aucune imprimante disponible") | Out-Null
    Exit
}

foreach ($printer in $printers) {
    $listAvailable.Items.Add($printer.ShareName) | Out-Null
}
Update-InstalledList

$form.ShowDialog() | Out-Null

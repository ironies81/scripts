Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Création de la fenêtre ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Date et Heure"
$form.Size = New-Object System.Drawing.Size(350,170)
$form.StartPosition = "CenterScreen"

# Label Date
$labelDate = New-Object System.Windows.Forms.Label
$labelDate.Location = New-Object System.Drawing.Point(20,20)
$labelDate.Size = New-Object System.Drawing.Size(300,30)
$labelDate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelDate)

# Label Heure
$labelHeure = New-Object System.Windows.Forms.Label
$labelHeure.Location = New-Object System.Drawing.Point(20,50)
$labelHeure.Size = New-Object System.Drawing.Size(300,30)
$labelHeure.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelHeure)

# Bouton Quitter
$buttonQuitter = New-Object System.Windows.Forms.Button
$buttonQuitter.Text = "Quitter"
$buttonQuitter.Location = New-Object System.Drawing.Point(120,90)
$buttonQuitter.Size = New-Object System.Drawing.Size(100,30)
$buttonQuitter.Add_Click({ $form.Close() })
$form.Controls.Add($buttonQuitter)

# --- Timer pour actualisation ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 # 1 seconde
$timer.Add_Tick({
    $labelDate.Text = "Date : $(Get-Date -Format 'dddd d MMMM yyyy')"
    $labelHeure.Text = "Heure : $(Get-Date -Format 'HH:mm:ss')"
})
$timer.Start()

# Initialisation affichage
$labelDate.Text = "Date : $(Get-Date -Format 'dddd d MMMM yyyy')"
$labelHeure.Text = "Heure : $(Get-Date -Format 'HH:mm:ss')"

# Affichage de la fenêtre
[void]$form.ShowDialog()

Add-Type -AssemblyName System.Windows.Forms

# Fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestion des impressions"
$form.Size = New-Object System.Drawing.Size(600,400)

# Liste des imprimantes
$comboPrinters = New-Object System.Windows.Forms.ComboBox
$comboPrinters.Location = '10,10'
$comboPrinters.Width = 400
$comboPrinters.DropDownStyle = 'DropDownList'
$printers = Get-Printer | Select-Object -ExpandProperty Name
$comboPrinters.Items.AddRange($printers)
$form.Controls.Add($comboPrinters)

# Liste des documents en attente
$listJobs = New-Object System.Windows.Forms.ListBox
$listJobs.Location = '10,50'
$listJobs.Size = New-Object System.Drawing.Size(560,250)
$form.Controls.Add($listJobs)

# Bouton Rafraîchir
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Rafraîchir"
$btnRefresh.Location = '420,10'
$form.Controls.Add($btnRefresh)

# Bouton Pause
$btnPause = New-Object System.Windows.Forms.Button
$btnPause.Text = "Mettre en pause"
$btnPause.Location = '120,320'
$btnPause.Size = New-Object System.Drawing.Size(120,30)
$btnPause.BackColor = 'LightGray'
$form.Controls.Add($btnPause)

# Bouton Libérer la file
$btnRelease = New-Object System.Windows.Forms.Button
$btnRelease.Text = "Libérer la file"
$btnRelease.Location = '10,320'
$btnRelease.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnRelease)

# Variable d'état pause
$printerPaused = $false

function Refresh-Jobs {
    $listJobs.Items.Clear()
    $printer = $comboPrinters.SelectedItem
    if ($printer) {
        try {
            $jobs = Get-PrintJob -PrinterName $printer
            foreach ($job in $jobs) {
                $listJobs.Items.Add("[$($job.JobId)] $($job.DocumentName) - $($job.JobStatus)")
            }
        } catch {
            $listJobs.Items.Add("Aucun travail d'impression ou accès refusé.")
        }
    }
}

function UpdatePauseButton {
    $printer = $comboPrinters.SelectedItem
    if ($printer) {
        try {
            $printerObj = Get-CimInstance -ClassName Win32_Printer -Filter "Name = '$printer'"
            # PrinterStatus 7 = Paused
            if ($printerObj.PrinterStatus -eq 7) {
                $btnPause.BackColor = 'OrangeRed'
                $btnPause.Text = "Sortir de la pause"
                $printerPaused = $true
            } else {
                $btnPause.BackColor = 'LightGray'
                $btnPause.Text = "Mettre en pause"
                $printerPaused = $false
            }
        } catch {
            $btnPause.BackColor = 'Gray'
            $btnPause.Text = "Erreur"
            $printerPaused = $false
        }
    }
}

$btnRefresh.Add_Click({ Refresh-Jobs })
$comboPrinters.Add_SelectedIndexChanged({ UpdatePauseButton; Refresh-Jobs })

$btnPause.Add_Click({
    $printer = $comboPrinters.SelectedItem
    if ($printer) {
        try {
            if (-not $printerPaused) {
                # Mettre en pause
                Get-CimInstance -ClassName Win32_Printer -Filter "Name = '$printer'" | Invoke-CimMethod -MethodName Pause
            } else {
                # Sortir de la pause
                Get-CimInstance -ClassName Win32_Printer -Filter "Name = '$printer'" | Invoke-CimMethod -MethodName Resume
            }
            Start-Sleep -Milliseconds 500
            UpdatePauseButton
            Refresh-Jobs
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors du changement d'état de l'imprimante.")
        }
    }
})

$btnRelease.Add_Click({
    $printer = $comboPrinters.SelectedItem
    if ($printer) {
        try {
            Get-CimInstance -ClassName Win32_Printer -Filter "Name = '$printer'" | Invoke-CimMethod -MethodName Resume
            Start-Sleep -Milliseconds 500
            UpdatePauseButton
            Refresh-Jobs
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de la reprise de l'imprimante.")
        }
    }
})

# Actualisation automatique toutes les 5 secondes
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({ Refresh-Jobs; UpdatePauseButton })
$timer.Start()

$form.Add_Shown({
    if ($comboPrinters.Items.Count -gt 0) {
        $comboPrinters.SelectedIndex = 0
    }
    UpdatePauseButton
    Refresh-Jobs
})

[void]$form.ShowDialog()

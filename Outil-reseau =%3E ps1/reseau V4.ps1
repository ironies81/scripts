# Script: NetworkTools.ps1
# Description: Application portable pour gerer les parametres reseau avec interface graphique
# Auteur: Clavier Guillaume
# Date: 18/04/2025

# Charger l'assembly Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Menu {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Menu Reseau"
    $form.Size = New-Object Drawing.Size(320, 500)
    $form.StartPosition = "CenterScreen"

    $btn1 = New-Object Windows.Forms.Button
    $btn1.Text = "1. Afficher la configuration IP (ipconfig /all)"
    $btn1.SetBounds(20, 20, 260, 40)
    $btn1.Add_Click({ Show-IpConfigAll })

    $btn2 = New-Object Windows.Forms.Button
    $btn2.Text = "2. Ipconfig /release /renew (toutes les cartes)"
    $btn2.SetBounds(20, 70, 260, 40)
    $btn2.Add_Click({ ReleaseRenewIP })

    $btn3 = New-Object Windows.Forms.Button
    $btn3.Text = "3. Flushdns"
    $btn3.SetBounds(20, 120, 260, 40)
    $btn3.Add_Click({ FlushDNS })

    $btn4 = New-Object Windows.Forms.Button
    $btn4.Text = "4. Modifier IP (admin seulement)"
    $btn4.SetBounds(20, 170, 260, 40)
    $btn4.BackColor = 'LightGreen'
    $btn4.Add_Click({ ModifyIP })

    $btn5 = New-Object Windows.Forms.Button
    $btn5.Text = "5. Activer DHCP (admin seulement)"
    $btn5.SetBounds(20, 220, 260, 40)
    $btn5.BackColor = 'LightGreen'
    $btn5.Add_Click({ Enable-DHCP })
	
	$btn6 = New-Object Windows.Forms.Button
	$btn6.Text = "6. Ping -t vers une adresse"
	$btn6.SetBounds(20, 270, 260, 40)
	$btn6.Add_Click({ Launch-PingWindow })
	
	$btn7 = New-Object Windows.Forms.Button
	$btn7.Text = "7. Traceroute vers une adresse"
	$btn7.SetBounds(20, 320, 260, 40)
	$btn7.Add_Click({ Launch-TracerouteWindow })
	
	$btn8 = New-Object Windows.Forms.Button
	$btn8.Text = "8. Resolution DNS d'un nom"
	$btn8.SetBounds(20, 370, 260, 40)
	$btn8.Add_Click({ Launch-DNSResolverWindow })

	$btnQuit = New-Object Windows.Forms.Button
	$btnQuit.Text = "Quitter"
	$btnQuit.SetBounds(20, 420, 260, 20)
	$btnQuit.BackColor = '#FFCC99'  # Orange pastel
	$btnQuit.Add_Click({ $form.Close() })

	$label = New-Object System.Windows.Forms.Label
	$label.Text = "Outils Reseau - Clavier G."
	$label.AutoSize = $true
	$label.Location = New-Object System.Drawing.Point(10, 445)
	$form.Controls.Add($label)
	
    $form.Controls.AddRange(@($btn1, $btn2, $btn3, $btn4, $btn5, $btn6, $btn7, $btn8, $btnQuit))
    $form.ShowDialog() | Out-Null
}

function Show-IpConfigAll {
    try {
        $form = New-Object Windows.Forms.Form
        $form.Text = "Detail des cartes reseaux"
        $form.Size = New-Object Drawing.Size(750, 320)
        $form.StartPosition = "CenterScreen"

        $grid = New-Object Windows.Forms.DataGridView
        $grid.Size = New-Object Drawing.Size(720, 200)
        $grid.Location = New-Object Drawing.Point(10,10)
        $grid.ReadOnly = $true
        $grid.AllowUserToAddRows = $false
        $grid.AllowUserToDeleteRows = $false
        $grid.AutoSizeColumnsMode = "AllCells"

        $grid.Columns.Add("InterfaceAlias", "Carte")
        $grid.Columns.Add("IPv4", "Adresse IPv4")
        $grid.Columns.Add("Mask", "Masque")
        $grid.Columns.Add("Gateway", "Passerelle")
        $grid.Columns.Add("DNS", "DNS")

        function Refresh-Grid {
            $grid.Rows.Clear()
            $info = Get-NetIPConfiguration
            foreach ($i in $info) {
                $dns = $i.DnsServer.ServerAddresses -join ", "
                $ipv4 = $i.IPv4Address.IPAddress
                $mask = $i.IPv4Address.PrefixLength
                $gateway = $i.IPv4DefaultGateway.NextHop
                $grid.Rows.Add($i.InterfaceAlias, $ipv4, $mask, $gateway, $dns)
            }
        }

        Refresh-Grid

        $btnExport = New-Object Windows.Forms.Button
        $btnExport.Text = "Exporter en CSV"
        $btnExport.SetBounds(10, 220, 150, 30)
        $btnExport.Add_Click({
            if (-not (Test-Path "C:\temp")) { New-Item -Path "C:\" -Name "temp" -ItemType Directory | Out-Null }
            $info = Get-NetIPConfiguration
            $info | Select-Object InterfaceAlias,@{Name="IPv4";Expression={$_.IPv4Address.IPAddress}},@{Name="Mask";Expression={$_.IPv4Address.PrefixLength}},@{Name="Gateway";Expression={$_.IPv4DefaultGateway.NextHop}},@{Name="DNS";Expression={$_.DNSServer.ServerAddresses -join ", "}} | Export-Csv "C:\temp\ipconfig_export.csv" -NoTypeInformation -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("Exporte vers C:\temp\ipconfig_export.csv", "Export CSV", "OK", "Information")
        })

        $btnRefresh = New-Object Windows.Forms.Button
        $btnRefresh.Text = "Rafraîchir"
        $btnRefresh.SetBounds(170, 220, 150, 30)
        $btnRefresh.Add_Click({ Refresh-Grid })

        $btnOK = New-Object Windows.Forms.Button
        $btnOK.Text = "OK"
        $btnOK.SetBounds(530, 220, 150, 30)
        $btnOK.Add_Click({ $form.Close() })

        $form.Controls.AddRange(@($grid, $btnExport, $btnRefresh, $btnOK))
        $form.ShowDialog()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'affichage des infos reseaux : $_")
    }
}

function ReleaseRenewIP {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Renouvellement IP..."
    $form.Size = New-Object Drawing.Size(300,100)
    $form.StartPosition = "CenterScreen"

    $label = New-Object Windows.Forms.Label
    $label.Text = "Renouvellement en cours..."
    $label.AutoSize = $true
    $label.Dock = "Fill"
    $form.Controls.Add($label)
    $form.Show()

    Start-Sleep -Milliseconds 500
    ipconfig /release | Out-Null
    Start-Sleep -Seconds 2
    ipconfig /renew | Out-Null
    Start-Sleep -Seconds 2
    $form.Close()

    Show-IpConfigAll
}

function FlushDNS {
    ipconfig /flushdns | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Cache DNS vide.", "FlushDNS", "OK", "Information")
}

function ModifyIP {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $form = New-Object Windows.Forms.Form
    $form.Text = "Modifier l'adresse IP"
    $form.Size = New-Object Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"

    $combo = New-Object Windows.Forms.ComboBox
    $combo.DropDownStyle = "DropDownList"
    $combo.Width = 350
    $combo.Left = 20
    $combo.Top = 20
    $adapters | ForEach-Object { $combo.Items.Add($_.Name) }
    $form.Controls.Add($combo)

    $labels = @("IP Adresse", "Masque (CIDR)", "Passerelle", "DNS1", "DNS2")
    $textBoxes = @()
    for ($i=0; $i -lt $labels.Length; $i++) {
        $lbl = New-Object Windows.Forms.Label
        $lbl.Text = $labels[$i]
        $lbl.SetBounds(20, 60 + ($i * 30), 120, 20)
        $form.Controls.Add($lbl)

        $tb = New-Object Windows.Forms.TextBox
        $tb.SetBounds(150, 60 + ($i * 30), 200, 20)
        $textBoxes += $tb
        $form.Controls.Add($tb)
    }

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "Valider"
    $btnOK.SetBounds(20, 230, 330, 30)
    $btnOK.Add_Click({
        $adapter = $combo.SelectedItem
        if ($adapter) {
            $ip = $textBoxes[0].Text
            $mask = $textBoxes[1].Text
            $gw = $textBoxes[2].Text
            $dns1 = $textBoxes[3].Text
            $dns2 = $textBoxes[4].Text

            Try {
                New-NetIPAddress -InterfaceAlias $adapter -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw -ErrorAction Stop
                Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses $dns1,$dns2 -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Configuration appliquee a $adapter", "Succes", "OK", "Information")
            } Catch {
                [System.Windows.Forms.MessageBox]::Show("Erreur: $_", "Erreur", "OK", "Error")
            }
        }
        $form.Close()
    })

    $form.Controls.Add($btnOK)
    $form.ShowDialog() | Out-Null
}

function Enable-DHCP {
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $adapterNames = $adapters | Select-Object -ExpandProperty Name

        $form = New-Object Windows.Forms.Form
        $form.Text = "Activer le DHCP"
        $form.Size = New-Object Drawing.Size(400,150)
        $form.StartPosition = "CenterScreen"

        $label = New-Object Windows.Forms.Label
        $label.Text = "Selectionnez la carte reseau :"
        $label.AutoSize = $true
        $label.Top = 20
        $label.Left = 10

        $comboBox = New-Object Windows.Forms.ComboBox
        $comboBox.Width = 350
        $comboBox.Left = 10
        $comboBox.Top = 50
        $comboBox.DropDownStyle = 'DropDownList'
        $comboBox.Items.AddRange($adapterNames)

        $okButton = New-Object Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Top = 90
        $okButton.Left = 150
        $okButton.Add_Click({
            $form.Tag = $comboBox.SelectedItem
            $form.Close()
        })

        $form.Controls.AddRange(@($label, $comboBox, $okButton))
        $form.ShowDialog() | Out-Null

        $selected = $form.Tag
        if (-not $selected) { return }

        Set-NetIPInterface -InterfaceAlias $selected -Dhcp Enabled -ErrorAction SilentlyContinue
        Set-DnsClientServerAddress -InterfaceAlias $selected -ResetServerAddresses -ErrorAction SilentlyContinue

        Get-NetIPAddress -InterfaceAlias $selected -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
            Where-Object { $_.PrefixOrigin -ne 'Dhcp' } |
            Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

        $routes = Get-NetRoute -InterfaceAlias $selected | Where-Object {
            $_.DestinationPrefix -eq "0.0.0.0/0" -and $_.NextHop -ne "0.0.0.0"
        }
        foreach ($route in $routes) {
            Remove-NetRoute -InterfaceAlias $selected -DestinationPrefix $route.DestinationPrefix -NextHop $route.NextHop -Confirm:$false -ErrorAction SilentlyContinue
        }

        ipconfig /release | Out-Null
        Start-Sleep -Seconds 2
        ipconfig /renew | Out-Null
        Start-Sleep -Seconds 2
        ipconfig /flushdns | Out-Null

        [System.Windows.Forms.MessageBox]::Show("DHCP active et configuration reseau reinitialisee.", "DHCP", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur lors de la configuration DHCP : $_", "Erreur", "OK", "Error")
    }
}

function Launch-PingWindow {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Ping -t"
    $form.Size = New-Object Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"

    $label = New-Object Windows.Forms.Label
    $label.Text = "Adresse IP ou nom a pinguer :"
    $label.SetBounds(10, 20, 360, 20)

    $textbox = New-Object Windows.Forms.TextBox
    $textbox.SetBounds(10, 50, 360, 25)

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "Lancer Ping -t"
    $btnOK.SetBounds(10, 85, 120, 30)
    $btnOK.Add_Click({
        $address = $textbox.Text.Trim()
        if (![string]::IsNullOrWhiteSpace($address)) {
            Start-Process powershell -ArgumentList "-NoExit", "-Command ping -t $address"
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Veuillez entrer une adresse valide.", "Erreur", "OK", "Error")
        }
    })

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "Annuler"
    $btnCancel.SetBounds(250, 85, 120, 30)
    $btnCancel.Add_Click({ $form.Close() })

    $form.Controls.AddRange(@($label, $textbox, $btnOK, $btnCancel))
    $form.ShowDialog()
}

function Launch-TracerouteWindow {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Traceroute"
    $form.Size = New-Object Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"

    $label = New-Object Windows.Forms.Label
    $label.Text = "Adresse IP ou nom a tracer :"
    $label.SetBounds(10, 20, 360, 20)

    $textbox = New-Object Windows.Forms.TextBox
    $textbox.SetBounds(10, 50, 360, 25)

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "Lancer Traceroute"
    $btnOK.SetBounds(10, 85, 150, 30)
    $btnOK.Add_Click({
        $address = $textbox.Text.Trim()
        if (![string]::IsNullOrWhiteSpace($address)) {
            Start-Process powershell -ArgumentList "-NoExit", "-Command tracert $address"
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Veuillez entrer une adresse valide.", "Erreur", "OK", "Error")
        }
    })

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "Annuler"
    $btnCancel.SetBounds(220, 85, 120, 30)
    $btnCancel.Add_Click({ $form.Close() })

    $form.Controls.AddRange(@($label, $textbox, $btnOK, $btnCancel))
    $form.ShowDialog()
}

function Launch-DNSResolverWindow {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Resolution DNS"
    $form.Size = New-Object Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"

    $label = New-Object Windows.Forms.Label
    $label.Text = "Nom de domaine a resoudre :"
    $label.SetBounds(10, 20, 360, 20)

    $textbox = New-Object Windows.Forms.TextBox
    $textbox.SetBounds(10, 50, 360, 25)

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "Resoudre"
    $btnOK.SetBounds(10, 85, 150, 30)
    $btnOK.Add_Click({
        $domain = $textbox.Text.Trim()
        if (![string]::IsNullOrWhiteSpace($domain)) {
            Start-Process powershell -ArgumentList "-NoExit", "-Command nslookup $domain"
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Veuillez entrer un nom de domaine valide.", "Erreur", "OK", "Error")
        }
    })

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "Annuler"
    $btnCancel.SetBounds(220, 85, 120, 30)
    $btnCancel.Add_Click({ $form.Close() })

    $form.Controls.AddRange(@($label, $textbox, $btnOK, $btnCancel))
    $form.ShowDialog()
}

Show-Menu
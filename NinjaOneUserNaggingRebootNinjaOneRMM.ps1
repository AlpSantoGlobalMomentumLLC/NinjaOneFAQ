# NinjaOne The User nagging-restart script with GUI and delay
# https://www.linkedin.com/in/axellenz/
# https://github.com/AlpSantoGlobalMomentumLLC/NinjaOneFAQ
# Beschreibung: https://ninjaonefaq.dcms.site/post/NinjaOne-de-User-Nerv-Neustart-Skript-mit-GUI-und-Aufschub
# Description AutoTranslated: https://translated.turbopages.org/proxy_u/de-en.en.8e5adcd6-647fb1db-de268456-74722d776562/https/ninjaonefaq.dcms.site/post/NinjaOne-de-User-Nerv-Neustart-Skript-mit-GUI-und-Aufschub
# It is inspired from different other solutions. 
# Das Skript "the new german End user nagging reboot script with GUI and postpone options" erstellt ein GUI-Fenster mit einer Nachricht vom IT-Helpdesk.
# Die Nachricht informiert den Benutzer darüber, dass ein Neustart des Systems erforderlich ist, um die Installation von Windows-Updates abzuschließen. 
# Das GUI enthält drei Schaltflächen: "Jetzt neu starten", "4 Std. Aufschub" und "8 Std. Aufschub". Wenn der Benutzer auf die Schaltfläche "Jetzt neu starten" klickt, wird der Neustart sofort durchgeführt.
# Wenn der Benutzer auf "4 Std. Aufschub" klickt, wird der Neustart um 4 Stunden verschoben, und wenn der Benutzer auf "8 Std. Aufschub" klickt, wird der Neustart um 8 Stunden verschoben. 
# Das GUI enthält auch einen Timer, der die verbleibende Zeit bis zum Neustart anzeigt. Wenn die Zeit abgelaufen ist, wird der Neustart automatisch durchgeführt. Das Skript verwendet den Befehl "schtasks.exe" zum Erstellen und Löschen von geplanten Aufgaben und
# den Befehl "shutdown" zum Ausführen des Neustarts.

# Axel Christian Lenz 
# https://www.linkedin.com/in/axellenz/
# Run it in the User Session!

Function Create-GetSchedTime {
    Param( $SchedTime )
    $script:StartTime = (Get-Date).AddSeconds($TotalTime)
    $RestartDate = ((get-date).AddSeconds($TotalTime)).AddMinutes(-1)

    $RDate = Get-Date $RestartDate -Format 'dd/MM/yyyy'
    $RTime = Get-Date $RestartDate -Format 'HH:mm'

    return @{
        StartTime = $script:StartTime
        RestartDate = $RestartDate
        RDate = $RDate
        RTime = $RTime
    }
    #& C:\Windows\System32\schtasks.exe /delete /tn "Post Maintenance Restart" /f
    & C:\Windows\System32\schtasks.exe /create /sc once /tn "Post Maintenance Restart" /tr "'C:\Windows\system32\cmd.exe' /c shutdown /r /t 400" /SD $RDate /ST $RTime /f
}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName( "Microsoft.VisualBasic") | Out-Null

$Title = "Nachricht vom Alixon IT-Helpdesk - Aktion erforderlich"
$Message = "Um die Installation von Windows-Updates abzuschließen, ist ein Neustart des Systems unerlässlich. Eine einfache Herunterfahrt genügt nicht. Bitte führen Sie einen Neustart durch."
$Button1Text = "Jetzt neu starten"
$Button2Text = "6 Std. Aufschub"
$Button3Text = "8 Std. Aufschub"

$FormColor = 'White'
$Form = $null
$Button1 = $null
$Button2 = $null
$Label = $null
$TextBox = $null
$Result = $null

$timerUpdate = New-Object 'System.Windows.Forms.Timer'
$TotalTime = 14400 #in seconds

Create-GetSchedTime -SchedTime $TotalTime
#Create-GetSchedTime -SchedTime $TotalTime

$timerUpdate_Tick={
    # Define countdown timer
    [TimeSpan]$span = $script:StartTime - (Get-Date)

    # Update the display
    $hours = "{0:00}" -f $span.Hours
    $mins = "{0:00}" -f $span.Minutes
    $secs = "{0:00}" -f $span.Seconds
    $labelTime.Text = "{0}:{1}:{2}" -f $hours, $mins, $secs

    $timerUpdate.Start()

    if ($span.TotalSeconds -le 0) {
        $timerUpdate.Stop()
        & C:\Windows\System32\schtasks.exe /delete /tn "Post Maintenance Restart" /f
        shutdown /r /t 0
    }
}

$Form_StoreValues_Closing= {
    #Store the control values
}

$Form_Cleanup_FormClosed= {
    #Remove all event handlers from the controls
    try {
        $Form.remove_Load($Form_Load)
        $timerUpdate.remove_Tick($timerUpdate_Tick)
        #$Form.remove_Load($Form_StateCorrection_Load)
        $Form.remove_Closing($Form_StoreValues_Closing)
        $Form.remove_FormClosed($Form_Cleanup_FormClosed)
    } catch [Exception] {
    }
}

# Form
$Form = New-Object -TypeName System.Windows.Forms.Form
$Form.Text = $Title
$Form.Size = New-Object -TypeName System.Drawing.Size(500,220) # Erhöhen der Formulargröße
$Form.StartPosition = "CenterScreen"
$Form.ControlBox = $False
$Form.Topmost = $true
$Form.KeyPreview = $true
$Form.ShowInTaskbar = $False
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $False
$Form.MinimizeBox = $False
$Form.BackColor = $FormColor

$Icon = [system.drawing.icon]::ExtractAssociatedIcon("c:\Windows\System32\UserAccountControlSettings.exe")
$Form.Icon = $Icon

# Button One (Reboot/Shutdown Now)
$Button1 = New-Object -TypeName System.Windows.Forms.Button
$Button1.Size = New-Object -TypeName System.Drawing.Size(150,40) # Erhöhen der Button-Größe
$Button1.Location = New-Object -TypeName System.Drawing.Size(20,140) # Verschieben des Buttons nach rechts
$Button1.Text = $Button1Text
$Button1.Font = 'Tahoma, 10pt'
$Button1.Add_Click({
    & C:\Windows\System32\schtasks.exe /delete /tn "Post Maintenance Restart" /f
    shutdown /r /t 0
    $Form.Close()
})
$Form.Controls.Add($Button1)

# Button Two (Postpone for 4 Hours)
$Button2 = New-Object -TypeName System.Windows.Forms.Button
$Button2.Size = New-Object -TypeName System.Drawing.Size(150,40) # Erhöhen der Button-Größe
$Button2.Location = New-Object -TypeName System.Drawing.Size(175,140) # Zentrieren des Buttons
$Button2.Text = $Button2Text
$Button2.Font = 'Tahoma, 10pt'
$Button2.Add_Click({
    $Button2.Enabled = $False
    $timerUpdate.Stop()
    $TotalTime = 21600
    #$TotalTime = 120
    Create-GetSchedTime -SchedTime $TotalTime
    $timerUpdate.add_Tick($timerUpdate_Tick)
    $timerUpdate.Start()
})
$Form.Controls.Add($Button2)

# Button Three (Postpone for 8 Hours)
$Button3 = New-Object -TypeName System.Windows.Forms.Button
$Button3.Size = New-Object -TypeName System.Drawing.Size(150,40) # Erhöhen der Button-Größe
$Button3.Location = New-Object -TypeName System.Drawing.Size(330,140) # Verschieben des Buttons nach links
$Button3.Text = $Button3Text
$Button3.Font = 'Tahoma, 10pt'
$Button3.Add_Click({
    $Button3.Enabled = $False
    $timerUpdate.Stop()
    $TotalTime = 28800
    #$TotalTime = 120
    Create-GetSchedTime -SchedTime $TotalTime
    $timerUpdate.add_Tick($timerUpdate_Tick)
    $timerUpdate.Start()
})
$Form.Controls.Add($Button3)

# Label
$Label = New-Object -TypeName System.Windows.Forms.Label
$Label.Size = New-Object -TypeName System.Drawing.Size(475,60)
$Label.Location = New-Object -TypeName System.Drawing.Size(10,10)
$Label.Text = $Message
$Label.Font = 'Tahoma, 10pt'
$Form.Controls.Add($Label)

# Label2
$Label2 = New-Object -TypeName System.Windows.Forms.Label
$Label2.Size = New-Object -TypeName System.Drawing.Size(355,30)
$Label2.Location = New-Object -TypeName System.Drawing.Size(10,100)
$Label2.Text = $Message2
$label2.Font = 'Tahoma, 10pt'
$Form.Controls.Add($Label2)

# labelTime
$labelTime = New-Object 'System.Windows.Forms.Label'
$labelTime.AutoSize = $True
$labelTime.Font = 'Arial, 26pt, style=Bold'
$labelTime.Location = '200, 60' # Setzen Sie den Timer in die Mitte des Fensters
$labelTime.Name = 'labelTime'
$labelTime.Size = '43, 15'
$labelTime.TextAlign = 'MiddleCenter'
$labelTime.ForeColor = '242, 103, 34'
$Form.Controls.Add($labelTime)

# Start the timer
$timerUpdate.add_Tick($timerUpdate_Tick)
$timerUpdate.Start()

# Show
$Form.Add_Shown({$Form.Activate()})
# Clean up the control events
$Form.add_FormClosed($Form_Cleanup_FormClosed)
# Store the control values when the form is closing
$Form.add_Closing($Form_StoreValues_Closing)
# Show the Form
$Form.ShowDialog() | Out-Null

B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	Private rm As RingtoneManager
End Sub

Sub Globals
	Private colorPrimary As Int = Colors.RGB(255, 107, 53)
	Private colorWhite As Int = Colors.White
	Private colorBackground As Int = Colors.RGB(248, 249, 250)
	Private colorRed As Int = Colors.RGB(220, 53, 69)
	Private sv As ScrollView
	Private lblCurrentSound As Label
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.Color = colorBackground
	CreateUI
End Sub

Sub CreateUI
	Dim pnlHeader As Panel
	pnlHeader.Initialize("")
	pnlHeader.Color = colorPrimary
	Activity.AddView(pnlHeader, 0, 0, 100%x, 90dip)

	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = "Settings"
	lblTitle.TextColor = colorWhite
	lblTitle.TextSize = 20
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	pnlHeader.AddView(lblTitle, 20dip, 15dip, 200dip, 35dip)

	Dim lblSubtitle As Label
	lblSubtitle.Initialize("")
	lblSubtitle.Text = "Manager: " & Main.userEmail
	lblSubtitle.TextColor = colorWhite
	lblSubtitle.TextSize = 13
	pnlHeader.AddView(lblSubtitle, 20dip, 52dip, 250dip, 30dip)

	Dim btnHome As Button
	btnHome.Initialize("btnHome")
	btnHome.Gravity = Gravity.CENTER
	btnHome.Text = "🏠"
	btnHome.TextSize = 40
	btnHome.TextColor = Colors.Black
	btnHome.Color = Colors.Transparent
	Activity.AddView(btnHome, 20dip, 100%y - 90dip, 100%x - 40dip, 70dip)

	sv.Initialize(0)
	Activity.AddView(sv, 0, 90dip, 100%x, 100%y - 180dip)

	Dim yPos As Int = 15dip

	' ACCOUNT section
	Dim lblSection1 As Label
	lblSection1.Initialize("")
	lblSection1.Text = "ACCOUNT"
	lblSection1.TextSize = 13
	lblSection1.Typeface = Typeface.DEFAULT_BOLD
	lblSection1.TextColor = Colors.RGB(136, 136, 136)
	sv.Panel.AddView(lblSection1, 25dip, yPos, 200dip, 20dip)
	yPos = yPos + 30dip
	CreateMenuItem("🔐", "Change Password", yPos, "btnChangePassword")
	yPos = yPos + 65dip

	' MANAGEMENT section
	Dim lblSection2 As Label
	lblSection2.Initialize("")
	lblSection2.Text = "MANAGEMENT"
	lblSection2.TextSize = 13
	lblSection2.Typeface = Typeface.DEFAULT_BOLD
	lblSection2.TextColor = Colors.RGB(136, 136, 136)
	sv.Panel.AddView(lblSection2, 25dip, yPos, 200dip, 20dip)
	yPos = yPos + 30dip
	CreateMenuItem("⛑", "Helmet Assignments", yPos, "btnAssignments")
	yPos = yPos + 65dip
	CreateMenuItem("👥", "Worker Database", yPos, "btnWorkers")
	yPos = yPos + 65dip

	' SYSTEM section
	Dim lblSection3 As Label
	lblSection3.Initialize("")
	lblSection3.Text = "SYSTEM"
	lblSection3.TextSize = 13
	lblSection3.Typeface = Typeface.DEFAULT_BOLD
	lblSection3.TextColor = Colors.RGB(136, 136, 136)
	sv.Panel.AddView(lblSection3, 25dip, yPos, 200dip, 20dip)
	yPos = yPos + 30dip
	CreateMenuItem("⚙", "Alert Thresholds", yPos, "btnAlerts")
	yPos = yPos + 65dip
	CreateMenuItem("ℹ", "About", yPos, "btnAbout")
	yPos = yPos + 65dip

	' ALARM SOUND section
	Dim lblSection4 As Label
	lblSection4.Initialize("")
	lblSection4.Text = "ALARM"
	lblSection4.TextSize = 13
	lblSection4.Typeface = Typeface.DEFAULT_BOLD
	lblSection4.TextColor = Colors.RGB(136, 136, 136)
	sv.Panel.AddView(lblSection4, 25dip, yPos, 200dip, 20dip)
	yPos = yPos + 30dip

	' Alarm sound picker panel
	Dim pnlSound As Panel
	pnlSound.Initialize("")
	pnlSound.Color = colorWhite
	sv.Panel.AddView(pnlSound, 15dip, yPos, 100%x - 30dip, 75dip)

	Dim pnlIconBg As Panel
	pnlIconBg.Initialize("")
	pnlIconBg.Color = colorPrimary
	pnlSound.AddView(pnlIconBg, 15dip, 17dip, 40dip, 40dip)

	Dim lblSoundIcon As Label
	lblSoundIcon.Initialize("")
	lblSoundIcon.Text = "🔔"
	lblSoundIcon.TextSize = 20
	lblSoundIcon.Gravity = Gravity.CENTER
	pnlIconBg.AddView(lblSoundIcon, 0, 0, 40dip, 40dip)

	Dim lblSoundTitle As Label
	lblSoundTitle.Initialize("")
	lblSoundTitle.Text = "Alarm Sound"
	lblSoundTitle.TextSize = 15
	lblSoundTitle.Typeface = Typeface.DEFAULT_BOLD
	lblSoundTitle.TextColor = Colors.RGB(51, 51, 51)
	pnlSound.AddView(lblSoundTitle, 70dip, 10dip, 220dip, 22dip)

	lblCurrentSound.Initialize("")
	lblCurrentSound.TextSize = 12
	lblCurrentSound.TextColor = Colors.RGB(136, 136, 136)
	pnlSound.AddView(lblCurrentSound, 70dip, 34dip, 220dip, 20dip)
	UpdateSoundLabel

	Dim btnPickSound As Button
	btnPickSound.Initialize("btnPickSound")
	btnPickSound.Text = "Change"
	btnPickSound.TextSize = 12
	btnPickSound.TextColor = colorPrimary
	btnPickSound.Color = Colors.Transparent
	pnlSound.AddView(btnPickSound, 100%x - 100dip, 20dip, 75dip, 35dip)

	yPos = yPos + 90dip

	' Logout button
	Dim btnLogout As Button
	btnLogout.Initialize("btnLogout")
	btnLogout.Text = "Logout"
	btnLogout.TextSize = 16
	btnLogout.Typeface = Typeface.DEFAULT_BOLD
	btnLogout.TextColor = colorWhite
	btnLogout.Color = colorRed
	sv.Panel.AddView(btnLogout, 15dip, yPos, 100%x - 30dip, 60dip)

	yPos = yPos + 80dip
	sv.Panel.Height = yPos
End Sub

Sub UpdateSoundLabel
	If File.Exists(File.DirInternal, "alarm_sound_name.txt") Then
		lblCurrentSound.Text = File.ReadString(File.DirInternal, "alarm_sound_name.txt")
	Else
		lblCurrentSound.Text = "Default notification sound"
	End If
End Sub

Sub CreateMenuItem(icon As String, text As String, y As Int, eventName As String)
	Dim pnlItem As Panel
	pnlItem.Initialize(eventName)
	pnlItem.Color = Colors.White
	sv.Panel.AddView(pnlItem, 15dip, y, 100%x - 30dip, 55dip)

	Dim pnlIconBg As Panel
	pnlIconBg.Initialize("")
	pnlIconBg.Color = colorPrimary
	pnlItem.AddView(pnlIconBg, 15dip, 10dip, 40dip, 40dip)

	Dim lblIcon As Label
	lblIcon.Initialize("")
	lblIcon.Text = icon
	lblIcon.TextSize = 20
	lblIcon.Gravity = Gravity.CENTER
	pnlIconBg.AddView(lblIcon, 0, 0, 40dip, 40dip)

	Dim lblText As Label
	lblText.Initialize("")
	lblText.Text = text
	lblText.TextSize = 15
	lblText.Typeface = Typeface.DEFAULT_BOLD
	lblText.TextColor = Colors.RGB(51, 51, 51)
	pnlItem.AddView(lblText, 70dip, 18dip, 220dip, 25dip)

	Dim lblArrow As Label
	lblArrow.Initialize("")
	lblArrow.Text = "›"
	lblArrow.TextSize = 24
	lblArrow.TextColor = Colors.RGB(200, 200, 200)
	pnlItem.AddView(lblArrow, pnlItem.Width - 40dip, 15dip, 30dip, 30dip)
End Sub

Sub btnPickSound_Click
	rm.ShowRingtonePicker("rm", rm.TYPE_NOTIFICATION, True, _
		IIf(File.Exists(File.DirInternal, "alarm_sound_uri.txt"), _
		File.ReadString(File.DirInternal, "alarm_sound_uri.txt"), ""))
End Sub

Sub rm_PickerResult(Success As Boolean, Uri As String)
	If Success Then
		If Uri = "" Then
			File.Delete(File.DirInternal, "alarm_sound_uri.txt")
			File.Delete(File.DirInternal, "alarm_sound_name.txt")
			ToastMessageShow("Using default notification sound", False)
		Else
			File.WriteString(File.DirInternal, "alarm_sound_uri.txt", Uri)
			Dim parts() As String = Regex.Split("/", Uri)
			Dim soundName As String = parts(parts.Length - 1)
			File.WriteString(File.DirInternal, "alarm_sound_name.txt", soundName)
			ToastMessageShow("Alarm sound saved", False)
		End If
		UpdateSoundLabel
	End If
End Sub

Sub btnChangePassword_Click
	StartActivity(ChangePasswordActivity)
End Sub

Sub btnAssignments_Click
	StartActivity(HelmetAssignmentsActivity)
End Sub

Sub btnWorkers_Click
	StartActivity(WorkerDatabaseActivity)
End Sub

Sub btnAlerts_Click
	StartActivity(ThresholdActivity)
End Sub

Sub btnAbout_Click
	Msgbox("Construction Helmet IoT" & CRLF & "Version 1.0" & CRLF & CRLF & "Real-time safety monitoring" & CRLF & CRLF & "Alarm: repeats every 30 seconds" & CRLF & "Snooze: silences for 5 minutes", "About")
End Sub

Sub btnLogout_Click
	Dim result As Int = Msgbox2("Are you sure you want to logout?", "Logout", "Yes", "", "No", Null)
	If result = DialogResponse.POSITIVE Then
		File.Delete(File.DirInternal, "login.txt")
		File.Delete(File.DirInternal, "email.txt")
		File.Delete(File.DirInternal, "token.txt")
		File.Delete(File.DirInternal, "userid.txt")
		ToastMessageShow("Logged out successfully", False)
		StartActivity(LoginActivity)
		ExitApplication
	End If
End Sub

Sub btnHome_Click
	StartActivity(Main)
	ExitApplication
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause(UserClosed As Boolean)

End Sub

B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
'Code module
'Threshold Settings Activity
'Allows manager to set temperature and G-force alert thresholds

#Region  Project Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	Private colorPrimary As Int = 0xFFFF6B35
	Private colorWhite As Int = Colors.White
End Sub

Sub Globals
	Private edtTempThreshold As EditText
	Private edtGForceThreshold As EditText
	Private btnSave As Button
	Private lblTempCurrent As Label
	Private lblGForceCurrent As Label
End Sub

Sub Activity_Create(FirstTime As Boolean)
	' Create UI in code - no layout file needed
	CreateUI
	LoadCurrentThresholds
End Sub

Sub CreateUI
	' STANDARD HEADER - 90dip
	Dim pnlHeader As Panel
	pnlHeader.Initialize("")
	pnlHeader.Color = colorPrimary
	Activity.AddView(pnlHeader, 0, 0, 100%x, 90dip)
	
	' STANDARD BACK BUTTON - 60x60, 15 from top, 36pt, white, centered
	Dim btnBack As Button
	btnBack.Initialize("btnBack")
	btnBack.Gravity = Gravity.CENTER
	btnBack.Text = "←"
	btnBack.TextSize = 36
	btnBack.TextColor = colorWhite
	btnBack.Color = Colors.Transparent
	pnlHeader.AddView(btnBack, 10dip, 15dip, 60dip, 60dip)
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = "Alert Thresholds"
	lblTitle.TextColor = colorWhite
	lblTitle.TextSize = 20
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.Gravity = Gravity.CENTER
	pnlHeader.AddView(lblTitle, 80dip, 25dip, 100%x - 90dip, 40dip)
	
	' STANDARD HOME BUTTON - 70dip tall, 40pt icon, black, centered
	Dim btnHome As Button
	btnHome.Initialize("btnHome")
	btnHome.Gravity = Gravity.CENTER
	btnHome.Text = "🏠"
	btnHome.TextSize = 40
	btnHome.TextColor = Colors.Black
	btnHome.Color = Colors.Transparent
	Activity.AddView(btnHome, 20dip, 100%y - 90dip, 100%x - 40dip, 70dip)
	
	' Content area
	Dim yPos As Int = 110dip
	
	' Temperature Threshold Section
	Dim lblTempSection As Label
	lblTempSection.Initialize("")
	lblTempSection.Text = "TEMPERATURE ALERT"
	lblTempSection.TextSize = 13
	lblTempSection.Typeface = Typeface.DEFAULT_BOLD
	lblTempSection.TextColor = Colors.RGB(100, 100, 100)
	Activity.AddView(lblTempSection, 20dip, yPos, 250dip, 25dip)
	
	yPos = yPos + 30dip
	
	Dim lblTempLabel As Label
	lblTempLabel.Initialize("")
	lblTempLabel.Text = "Alert when temperature exceeds (°C):"
	lblTempLabel.TextSize = 14
	lblTempLabel.TextColor = Colors.RGB(51, 51, 51)
	Activity.AddView(lblTempLabel, 20dip, yPos, 100%x - 40dip, 25dip)
	
	yPos = yPos + 30dip
	
	edtTempThreshold.Initialize("edtTempThreshold")
	edtTempThreshold.Hint = "e.g., 35"
	edtTempThreshold.InputType = edtTempThreshold.INPUT_TYPE_DECIMAL_NUMBERS
	edtTempThreshold.TextSize = 16
	edtTempThreshold.Color = colorWhite
	Activity.AddView(edtTempThreshold, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 60dip
	
	lblTempCurrent.Initialize("")
	lblTempCurrent.Text = "Current setting: Loading..."
	lblTempCurrent.TextSize = 12
	lblTempCurrent.TextColor = Colors.RGB(100, 100, 100)
	Activity.AddView(lblTempCurrent, 20dip, yPos, 100%x - 40dip, 25dip)
	
	yPos = yPos + 40dip
	
	' G-Force Threshold Section
	Dim lblGForceSection As Label
	lblGForceSection.Initialize("")
	lblGForceSection.Text = "FALL DETECTION (G-FORCE)"
	lblGForceSection.TextSize = 13
	lblGForceSection.Typeface = Typeface.DEFAULT_BOLD
	lblGForceSection.TextColor = Colors.RGB(100, 100, 100)
	Activity.AddView(lblGForceSection, 20dip, yPos, 250dip, 25dip)
	
	yPos = yPos + 30dip
	
	Dim lblGForceLabel As Label
	lblGForceLabel.Initialize("")
	lblGForceLabel.Text = "Alert when G-force exceeds (G):"
	lblGForceLabel.TextSize = 14
	lblGForceLabel.TextColor = Colors.RGB(51, 51, 51)
	Activity.AddView(lblGForceLabel, 20dip, yPos, 100%x - 40dip, 25dip)
	
	yPos = yPos + 30dip
	
	edtGForceThreshold.Initialize("edtGForceThreshold")
	edtGForceThreshold.Hint = "e.g., 2.5"
	edtGForceThreshold.InputType = edtGForceThreshold.INPUT_TYPE_DECIMAL_NUMBERS
	edtGForceThreshold.TextSize = 16
	edtGForceThreshold.Color = colorWhite
	Activity.AddView(edtGForceThreshold, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 60dip
	
	lblGForceCurrent.Initialize("")
	lblGForceCurrent.Text = "Current setting: Loading..."
	lblGForceCurrent.TextSize = 12
	lblGForceCurrent.TextColor = Colors.RGB(100, 100, 100)
	Activity.AddView(lblGForceCurrent, 20dip, yPos, 100%x - 40dip, 25dip)
	
	yPos = yPos + 50dip
	
	' Info text
	Dim lblInfo As Label
	lblInfo.Initialize("")
	lblInfo.Text = "💡 Recommended: Temp = 35°C, G-Force = 2.5G (fall detection)"
	lblInfo.TextSize = 12
	lblInfo.TextColor = Colors.RGB(150, 150, 150)
	Activity.AddView(lblInfo, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 70dip
	
	' Save button
	btnSave.Initialize("btnSave")
	btnSave.Text = "Save Thresholds"
	btnSave.TextSize = 16
	btnSave.Typeface = Typeface.DEFAULT_BOLD
	btnSave.TextColor = colorWhite
	btnSave.Color = colorPrimary
	Activity.AddView(btnSave, 20dip, yPos, 100%x - 40dip, 60dip)
End Sub

Sub LoadCurrentThresholds
	' Load from Firebase /settings/thresholds
	Dim job As HttpJob
	job.Initialize("get_thresholds", Me)
	job.Download(Main.FIREBASE_URL & "/settings/thresholds.json")
End Sub

Sub JobDone(job As HttpJob)
	If job.Success Then
		Select job.JobName
			Case "get_thresholds"
				Try
					If job.GetString <> "null" And job.GetString.Length > 0 Then
						Dim parser As JSONParser
						parser.Initialize(job.GetString)
						Dim root As Map = parser.NextObject
						
						If root.ContainsKey("temperature") Then
							Dim temp As Double = root.Get("temperature")
							edtTempThreshold.Text = temp
							lblTempCurrent.Text = "Current setting: " & temp & "°C"
						Else
							edtTempThreshold.Text = "35"
							lblTempCurrent.Text = "Current setting: Not set (default 35°C)"
						End If
						
						If root.ContainsKey("gforce") Then
							Dim gforce As Double = root.Get("gforce")
							edtGForceThreshold.Text = gforce
							lblGForceCurrent.Text = "Current setting: " & gforce & "G"
						Else
							edtGForceThreshold.Text = "2.5"
							lblGForceCurrent.Text = "Current setting: Not set (default 2.5G)"
						End If
					Else
						' No thresholds set yet - use defaults
						edtTempThreshold.Text = "35"
						edtGForceThreshold.Text = "2.5"
						lblTempCurrent.Text = "Current setting: Not set (default 35°C)"
						lblGForceCurrent.Text = "Current setting: Not set (default 2.5G)"
					End If
				Catch
					Log("Error parsing thresholds: " & LastException.Message)
					ToastMessageShow("Error loading thresholds", False)
				End Try
				
			Case "save_thresholds"
				ToastMessageShow("Thresholds saved successfully!", False)
				LoadCurrentThresholds ' Reload to confirm
		End Select
	Else
		Log("Job error: " & job.ErrorMessage)
		ToastMessageShow("Connection error", False)
	End If
	job.Release
End Sub

Sub btnSave_Click
	' Validate inputs
	If edtTempThreshold.Text.Trim = "" Then
		ToastMessageShow("Please enter temperature threshold", False)
		Return
	End If
	
	If edtGForceThreshold.Text.Trim = "" Then
		ToastMessageShow("Please enter G-force threshold", False)
		Return
	End If
	
	Dim tempValue As Double
	Dim gforceValue As Double
	
	Try
		tempValue = edtTempThreshold.Text
		gforceValue = edtGForceThreshold.Text
	Catch
		ToastMessageShow("Please enter valid numbers", False)
		Return
	End Try
	
	' Basic validation
	If tempValue < 20 Or tempValue > 60 Then
		ToastMessageShow("Temperature must be between 20-60°C", False)
		Return
	End If
	
	If gforceValue < 1.5 Or gforceValue > 10 Then
		ToastMessageShow("G-force must be between 1.5-10G", False)
		Return
	End If
	
	' Save to Firebase
	Dim json As JSONGenerator
	Dim m As Map
	m.Initialize
	m.Put("temperature", tempValue)
	m.Put("gforce", gforceValue)
	json.Initialize(m)
	
	Dim job As HttpJob
	job.Initialize("save_thresholds", Me)
	job.PutString(Main.FIREBASE_URL & "/settings/thresholds.json", json.ToString)
	job.GetRequest.SetContentType("application/json")
End Sub

Sub btnBack_Click
	Activity.Finish
End Sub

Sub btnHome_Click
	' Go back to Main screen and close all other activities
	StartActivity(Main)
	ExitApplication
End Sub

Sub Activity_Resume
End Sub

Sub Activity_Pause(UserClosed As Boolean)
End Sub

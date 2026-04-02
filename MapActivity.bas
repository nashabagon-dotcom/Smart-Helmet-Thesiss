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

End Sub

Sub Globals
	Private colorPrimary As Int = Colors.RGB(255, 107, 53)
	Private colorWhite As Int = Colors.White
	Private colorBackground As Int = Colors.RGB(248, 249, 250)
	Private colorRed As Int = Colors.RGB(220, 53, 69)
	Private colorOrange As Int = Colors.RGB(255, 152, 0)
	Private colorGreen As Int = Colors.RGB(76, 175, 80)

	Private pnlHeader As Panel
	Private lblWorkerName As Label
	Private lblHelmetId As Label
	Private lblStatus As Label
	Private btnBack As Button
	Private btnHome As Button
	Private btnViewMap As Button
	Private btnNavigate As Button
	Private btnShare As Button
	Private pnlInfo As Panel
	Private lblCoords As Label
	Private lblSatellites As Label
	Private lblTemp As Label
	Private lblHumidity As Label
	Private lblGForce As Label
	Private lblFallen As Label
	Private lblLastUpdate As Label

	Private mTimer As Timer
	Private mHelmetId As String
	Private mWorkerName As String
	Private mLat As Double
	Private mLng As Double
	Private mSatellites As Int
	Private mValid As Boolean
	Private mTemp As Double
	Private mHumidity As Double
	Private mGForce As Double
	Private mFallen As Boolean

	Private incidentLog As List
	Private lastAlertState As String
	Private lastFallTime As Long
	Private lastGForceTime As Long
	Private lastTempTime As Long
	Private lastHumidTime As Long
	Private INCIDENT_COOLDOWN As Long = 10000 ' 10 seconds between same incident type
End Sub

Sub Activity_Create(FirstTime As Boolean)
	If Main.selectedHelmet.IsInitialized = False Then
		ToastMessageShow("No helmet selected", False)
		Activity.Finish
		Return
	End If

	incidentLog.Initialize
	lastAlertState = ""
	lastFallTime = 0
	lastGForceTime = 0
	lastTempTime = 0
	lastHumidTime = 0

	Dim helmetData As Map = Main.selectedHelmet
	mHelmetId   = helmetData.GetDefault("id", "HELMET_001")
	mWorkerName = helmetData.GetDefault("workerName", "Unknown")

	Dim lastSeen As Long = helmetData.GetDefault("lastSeen", 0)
	Dim nowEpoch As Long = DateTime.Now / 1000
	Dim isOnline As Boolean = (lastSeen > 0 And nowEpoch - lastSeen < 15)
	If isOnline Then
		mTemp     = helmetData.GetDefault("temperature", 0.0)
		mHumidity = helmetData.GetDefault("humidity", 0.0)
		mGForce   = helmetData.GetDefault("gforce", 0.0)
		mFallen   = helmetData.GetDefault("fallen", False)
	Else
		mTemp = 0.0
		mHumidity = 0.0
		mGForce = 0.0
		mFallen = False
	End If

	Try
		Dim locationMap As Map = helmetData.Get("location")
		mLat        = locationMap.GetDefault("latitude", 14.5995)
		mLng        = locationMap.GetDefault("longitude", 120.9842)
		mSatellites = locationMap.GetDefault("satellites", 0)
		mValid      = locationMap.GetDefault("valid", False)
	Catch
		mLat = 14.5995
		mLng = 120.9842
		mSatellites = 0
		mValid = False
	End Try

	Activity.Color = colorBackground
	BuildUI
	StartLiveUpdates
End Sub

Sub GetAlertState As String
	If mFallen Then
		Return "FALLEN"
	Else If mTemp > Main.tempThreshold Then
		Return "HIGH_TEMP"
	Else If mGForce > Main.gForceThreshold Then
		Return "HIGH_GFORCE"
	Else If mHumidity > 85 Then
		Return "HIGH_HUMIDITY"
	End If
	Return ""
End Sub

Sub CheckAndLogIncident
	Dim now As Long = DateTime.Now
	Dim timestamp As String = DateTime.Date(now) & " " & DateTime.Time(now)

	' Each condition checked independently with its own cooldown
	' This ensures transient spikes (like G-force) are always caught

	If mFallen And (now - lastFallTime > INCIDENT_COOLDOWN) Then
		lastFallTime = now
		ShowIncidentDialog("FALL DETECTED!" & CRLF & timestamp)
	End If

	If mGForce > Main.gForceThreshold And (now - lastGForceTime > INCIDENT_COOLDOWN) Then
		lastGForceTime = now
		ShowIncidentDialog("High G-Force: " & NumberFormat(mGForce, 1, 2) & "G" & CRLF & timestamp)
	End If

	If mTemp > Main.tempThreshold And (now - lastTempTime > INCIDENT_COOLDOWN) Then
		lastTempTime = now
		ShowIncidentDialog("High Temperature: " & NumberFormat(mTemp, 1, 1) & Chr(176) & "C" & CRLF & timestamp)
	End If

	If mHumidity > 85 And (now - lastHumidTime > INCIDENT_COOLDOWN) Then
		lastHumidTime = now
		ShowIncidentDialog("High Humidity: " & NumberFormat(mHumidity, 1, 1) & "%" & CRLF & timestamp)
	End If
End Sub

Sub ShowIncidentDialog(msg As String)
	Dim fullMsg As String = "Worker: " & mWorkerName & CRLF & _
	                        "Helmet: " & mHelmetId & CRLF & CRLF & _
	                        msg
	Msgbox(fullMsg, "EMERGENCY ALERT")
End Sub

Sub BuildUI
	pnlHeader.Initialize("")
	pnlHeader.Color = colorPrimary
	Activity.AddView(pnlHeader, 0, 0, 100%x, 90dip)

	btnBack.Initialize("btnBack")
	btnBack.Gravity = Gravity.CENTER
	btnBack.Text = Chr(8592)
	btnBack.TextSize = 36
	btnBack.TextColor = colorWhite
	btnBack.Color = Colors.Transparent
	pnlHeader.AddView(btnBack, 10dip, 15dip, 60dip, 60dip)

	lblWorkerName.Initialize("")
	lblWorkerName.Text = mWorkerName
	lblWorkerName.TextColor = colorWhite
	lblWorkerName.TextSize = 18
	lblWorkerName.Typeface = Typeface.DEFAULT_BOLD
	lblWorkerName.Gravity = Gravity.LEFT
	pnlHeader.AddView(lblWorkerName, 80dip, 20dip, 100%x - 220dip, 25dip)

	lblHelmetId.Initialize("")
	lblHelmetId.Text = mHelmetId
	lblHelmetId.TextColor = Colors.ARGB(200, 255, 255, 255)
	lblHelmetId.TextSize = 13
	lblHelmetId.Gravity = Gravity.LEFT
	pnlHeader.AddView(lblHelmetId, 80dip, 48dip, 200dip, 20dip)

	lblStatus.Initialize("")
	lblStatus.TextSize = 11
	lblStatus.Gravity = Gravity.CENTER_VERTICAL + Gravity.RIGHT
	pnlHeader.AddView(lblStatus, 100%x - 130dip, 30dip, 120dip, 30dip)
	UpdateStatusLabel

	pnlInfo.Initialize("")
	pnlInfo.Color = colorWhite
	Activity.AddView(pnlInfo, 0, 100dip, 100%x, 260dip)

	Dim lblGpsTitle As Label
	lblGpsTitle.Initialize("")
	lblGpsTitle.Text = "GPS LOCATION"
	lblGpsTitle.TextSize = 11
	lblGpsTitle.Typeface = Typeface.DEFAULT_BOLD
	lblGpsTitle.TextColor = Colors.RGB(136, 136, 136)
	pnlInfo.AddView(lblGpsTitle, 16dip, 12dip, 200dip, 18dip)

	lblCoords.Initialize("")
	lblCoords.Text = "Coords: " & FormatCoords
	lblCoords.TextSize = 14
	lblCoords.TextColor = Colors.RGB(50, 50, 50)
	pnlInfo.AddView(lblCoords, 16dip, 36dip, 100%x - 32dip, 25dip)

	lblSatellites.Initialize("")
	lblSatellites.Text = "Satellites: " & mSatellites & "   |   GPS: " & IIf(mValid, "Valid", "No fix")
	lblSatellites.TextSize = 13
	lblSatellites.TextColor = Colors.RGB(120, 120, 120)
	pnlInfo.AddView(lblSatellites, 16dip, 66dip, 100%x - 32dip, 25dip)

	Dim lblSensorTitle As Label
	lblSensorTitle.Initialize("")
	lblSensorTitle.Text = "SENSOR READINGS"
	lblSensorTitle.TextSize = 11
	lblSensorTitle.Typeface = Typeface.DEFAULT_BOLD
	lblSensorTitle.TextColor = Colors.RGB(136, 136, 136)
	pnlInfo.AddView(lblSensorTitle, 16dip, 102dip, 200dip, 18dip)

	lblTemp.Initialize("")
	lblTemp.Text = "Temperature: " & NumberFormat(mTemp, 1, 1) & Chr(176) & "C"
	lblTemp.TextSize = 14
	lblTemp.TextColor = Colors.RGB(50, 50, 50)
	pnlInfo.AddView(lblTemp, 16dip, 126dip, 100%x - 32dip, 25dip)

	lblHumidity.Initialize("")
	lblHumidity.Text = "Humidity: " & NumberFormat(mHumidity, 1, 1) & "%"
	lblHumidity.TextSize = 14
	lblHumidity.TextColor = Colors.RGB(50, 50, 50)
	pnlInfo.AddView(lblHumidity, 16dip, 156dip, 100%x - 32dip, 25dip)

	lblGForce.Initialize("")
	lblGForce.Text = "G-Force: " & NumberFormat(mGForce, 1, 2) & " G"
	lblGForce.TextSize = 14
	lblGForce.TextColor = Colors.RGB(50, 50, 50)
	pnlInfo.AddView(lblGForce, 16dip, 186dip, 100%x - 32dip, 25dip)

	lblFallen.Initialize("")
	lblFallen.TextSize = 14
	lblFallen.Typeface = Typeface.DEFAULT_BOLD
	pnlInfo.AddView(lblFallen, 16dip, 216dip, 100%x - 32dip, 25dip)
	UpdateFallenLabel

	lblLastUpdate.Initialize("")
	lblLastUpdate.Text = "Live tracking active"
	lblLastUpdate.TextSize = 11
	lblLastUpdate.TextColor = Colors.RGB(150, 150, 150)
	pnlInfo.AddView(lblLastUpdate, 16dip, 242dip, 100%x - 32dip, 18dip)

	btnViewMap.Initialize("btnViewMap")
	btnViewMap.Text = "View on Google Maps"
	btnViewMap.TextSize = 16
	btnViewMap.TextColor = colorWhite
	btnViewMap.Color = colorPrimary
	Activity.AddView(btnViewMap, 20dip, 375dip, 100%x - 40dip, 60dip)

	btnNavigate.Initialize("btnNavigate")
	btnNavigate.Text = "Navigate Here"
	btnNavigate.TextSize = 14
	btnNavigate.TextColor = colorWhite
	btnNavigate.Color = colorGreen
	Activity.AddView(btnNavigate, 20dip, 450dip, 100%x - 40dip, 55dip)

	btnShare.Initialize("btnShare")
	btnShare.Text = "Share Location"
	btnShare.TextSize = 14
	btnShare.TextColor = Colors.RGB(80, 80, 80)
	btnShare.Color = Colors.RGB(240, 240, 240)
	Activity.AddView(btnShare, 20dip, 520dip, 100%x - 40dip, 55dip)

	btnHome.Initialize("btnHome")
	btnHome.Gravity = Gravity.CENTER
	btnHome.Text = "🏠"
	btnHome.TextSize = 40
	btnHome.TextColor = Colors.Black
	btnHome.Color = Colors.Transparent
	Activity.AddView(btnHome, 20dip, 100%y - 90dip, 100%x - 40dip, 70dip)
End Sub

Sub StartLiveUpdates
	mTimer.Initialize("mTimer", 1000)
	mTimer.Enabled = True
End Sub

Sub mTimer_Tick
	Dim job As HttpJob
	job.Initialize("helmetdata", Me)
	job.Download(Main.FIREBASE_URL & "/helmets/" & mHelmetId & ".json")
End Sub

Sub JobDone(Job As HttpJob)
	If Job.Success Then
		Try
			Dim parser As JSONParser
			parser.Initialize(Job.GetString)
			Dim m As Map = parser.NextObject

			Dim status As String = m.GetDefault("status", "offline")
			Dim lastSeen As Long = m.GetDefault("lastSeen", 0)
			Dim nowEpoch As Long = DateTime.Now / 1000
			Dim isOnline As Boolean = (lastSeen > 0 And nowEpoch - lastSeen < 15)

			If isOnline Then
				mTemp     = m.GetDefault("temperature", mTemp)
				mHumidity = m.GetDefault("humidity", mHumidity)
				mGForce   = m.GetDefault("gforce", mGForce)
				mFallen   = m.GetDefault("fallen", mFallen)
			Else
				mTemp = 0.0
				mHumidity = 0.0
				mGForce = 0.0
				mFallen = False
			End If

			Try
				Dim locMap As Map = m.Get("location")
				mLat        = locMap.GetDefault("latitude", mLat)
				mLng        = locMap.GetDefault("longitude", mLng)
				mSatellites = locMap.GetDefault("satellites", mSatellites)
				mValid      = locMap.GetDefault("valid", mValid)
			Catch
			End Try

			lblCoords.Text     = "Coords: " & FormatCoords
			lblSatellites.Text = "Satellites: " & mSatellites & "   |   GPS: " & IIf(mValid, "Valid", "No fix")
			lblTemp.Text       = "Temperature: " & NumberFormat(mTemp, 1, 1) & Chr(176) & "C"
			lblHumidity.Text   = "Humidity: " & NumberFormat(mHumidity, 1, 1) & "%"
			lblGForce.Text     = "G-Force: " & NumberFormat(mGForce, 1, 2) & " G"
			lblLastUpdate.Text = "Updated: " & DateTime.Time(DateTime.Now)

			If isOnline Then
				lblTemp.TextColor    = IIf(mTemp > Main.tempThreshold, colorRed, Colors.RGB(50, 50, 50))
				lblGForce.TextColor  = IIf(mGForce > Main.gForceThreshold, colorRed, Colors.RGB(50, 50, 50))
				lblHumidity.TextColor = IIf(mHumidity > 85, colorRed, Colors.RGB(50, 50, 50))
			Else
				lblTemp.TextColor    = Colors.RGB(180, 180, 180)
				lblGForce.TextColor  = Colors.RGB(180, 180, 180)
				lblHumidity.TextColor = Colors.RGB(180, 180, 180)
			End If

			UpdateStatusLabel
			UpdateFallenLabel
		Catch
			Log("JobDone error: " & LastException)
		End Try
	End If
	Job.Release
End Sub

Sub FormatCoords As String
	Return NumberFormat(mLat, 1, 6) & ", " & NumberFormat(mLng, 1, 6)
End Sub

Sub UpdateStatusLabel
	If mFallen Then
		lblStatus.Text = "EMERGENCY!"
		lblStatus.TextColor = colorRed
	Else If mTemp > Main.tempThreshold Then
		lblStatus.Text = "EMERGENCY!"
		lblStatus.TextColor = colorRed
	Else If mGForce > Main.gForceThreshold Then
		lblStatus.Text = "EMERGENCY!"
		lblStatus.TextColor = colorRed
	Else If mHumidity > 85 Then
		lblStatus.Text = "WARNING"
		lblStatus.TextColor = colorOrange
	Else If mTemp = 0.0 And mHumidity = 0.0 And mGForce = 0.0 And Not(mValid) Then
		lblStatus.Text = "OFFLINE"
		lblStatus.TextColor = Colors.RGB(150, 150, 150)
	Else If mValid Then
		lblStatus.Text = "GPS Active"
		lblStatus.TextColor = colorGreen
	Else
		lblStatus.Text = "No Fix"
		lblStatus.TextColor = colorOrange
	End If
End Sub

Sub UpdateFallenLabel
	If mFallen Then
		lblFallen.Text = "Status: FALL DETECTED!"
		lblFallen.TextColor = colorRed
	Else If mTemp > Main.tempThreshold Then
		lblFallen.Text = "Status: HIGH TEMPERATURE!"
		lblFallen.TextColor = colorRed
	Else If mGForce > Main.gForceThreshold Then
		lblFallen.Text = "Status: HIGH G-FORCE!"
		lblFallen.TextColor = colorRed
	Else If mHumidity > 85 Then
		lblFallen.Text = "Status: HIGH HUMIDITY!"
		lblFallen.TextColor = colorOrange
	Else
		lblFallen.Text = "Status: Normal"
		lblFallen.TextColor = colorGreen
	End If
End Sub

Sub btnViewMap_Click
	Dim uri As String = "geo:" & mLat & "," & mLng & "?q=" & mLat & "," & mLng & "(" & mWorkerName & ")"
	Dim intent As Intent
	intent.Initialize(intent.ACTION_VIEW, uri)
	StartActivity(intent)
End Sub

Sub btnNavigate_Click
	Dim uri As String = "google.navigation:q=" & mLat & "," & mLng
	Dim intent As Intent
	intent.Initialize(intent.ACTION_VIEW, uri)
	intent.SetPackage("com.google.android.apps.maps")
	StartActivity(intent)
End Sub

Sub btnShare_Click
	Dim shareText As String = mHelmetId & " (" & mWorkerName & ")" & Chr(10) & _
	                          "Coords: " & FormatCoords & Chr(10) & _
	                          "Temp: " & NumberFormat(mTemp, 1, 1) & Chr(176) & "C  Humidity: " & NumberFormat(mHumidity, 1, 1) & "%" & Chr(10) & _
	                          "G-Force: " & NumberFormat(mGForce, 1, 2) & "G" & Chr(10) & _
	                          "https://maps.google.com/?q=" & mLat & "," & mLng
	Dim intent As Intent
	intent.Initialize("android.intent.action.SEND", "")
	intent.SetType("text/plain")
	intent.PutExtra("android.intent.extra.TEXT", shareText)
	StartActivity(intent)
End Sub

Sub btnBack_Click
	Activity.Finish
End Sub

Sub btnHome_Click
	StartActivity(Main)
	ExitApplication
End Sub

Sub Activity_Resume
	If mTimer.IsInitialized Then
		mTimer.Enabled = True
	End If
End Sub

Sub Activity_Pause(UserClosed As Boolean)
	If mTimer.IsInitialized Then
		mTimer.Enabled = False
	End If
End Sub

B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=9.9
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: True
	#ExcludeFromLibrary: True
#End Region

Sub Process_Globals
	Public alertTimer As Timer
	Public FIREBASE_URL As String = "https://safetyhelmetiot-3dfeb-default-rtdb.firebaseio.com"
	Public alertedHelmets As Map
	Public snoozedHelmets As Map
	Private SNOOZE_DURATION As Long = 300000  ' 5 minutes
	Private REPEAT_INTERVAL As Long = 30000   ' 30 seconds
End Sub

Sub Service_Create
	alertedHelmets.Initialize
	snoozedHelmets.Initialize
End Sub

Sub Service_Start(StartingIntent As Intent)
	' Run as foreground service so Android keeps it alive when screen is off
	Dim n As Notification
	n.Initialize
	n.Icon = "icon"
	n.Light = False
	n.Sound = False
	n.Vibrate = False
	n.SetInfo("Helmet Monitor", "Monitoring active", Main)
	Service.StartForeground(99, n)

	' Handle snooze action
	Try
		Dim action As String = StartingIntent.GetExtra("action")
		Dim helmetId As String = StartingIntent.GetExtra("helmetId")
		If action = "snooze" And helmetId <> "" Then
			snoozedHelmets.Put(helmetId, DateTime.Now + SNOOZE_DURATION)
			Log("Snoozed: " & helmetId & " for 5 minutes")
		End If
	Catch
	End Try

	If alertTimer.IsInitialized = False Then
		alertTimer.Initialize("alertTimer", 3000)
	End If
	alertTimer.Enabled = True
End Sub

Sub alertTimer_Tick
	CheckAllHelmets
End Sub

Sub CheckAllHelmets
	Dim job As HttpJob
	job.Initialize("check_alerts", Me)
	job.Download(FIREBASE_URL & "/helmets.json")
End Sub

Sub JobDone(Job As HttpJob)
	If Job.Success Then
		Try
			Dim jsonStr As String = Job.GetString
			If jsonStr = "null" Or jsonStr = "" Then
				Job.Release
				Return
			End If

			Dim parser As JSONParser
			parser.Initialize(jsonStr)
			Dim root As Map = parser.NextObject

			Dim tempThresh As Double = 35.0
			Dim gForceThresh As Double = 2.5
			If File.Exists(File.DirInternal, "temp_threshold.txt") Then
				tempThresh = File.ReadString(File.DirInternal, "temp_threshold.txt")
			End If
			If File.Exists(File.DirInternal, "gforce_threshold.txt") Then
				gForceThresh = File.ReadString(File.DirInternal, "gforce_threshold.txt")
			End If

			For Each key As String In root.Keys
				Dim helmet As Map = root.Get(key)

				' Skip offline helmets - no alert if lastSeen > 15 seconds ago
				Dim lastSeen As Long = helmet.GetDefault("lastSeen", 0)
				Dim nowEpoch As Long = DateTime.Now / 1000
				If lastSeen = 0 Or nowEpoch - lastSeen > 15 Then
					If alertedHelmets.ContainsKey(key) Then alertedHelmets.Remove(key)
					If snoozedHelmets.ContainsKey(key) Then snoozedHelmets.Remove(key)
					Continue
				End If

				Dim temp As Double = helmet.GetDefault("temperature", 0.0)
				Dim gForce As Double = helmet.GetDefault("gforce", 0.0)
				Dim fallen As Boolean = helmet.GetDefault("fallen", False)
				Dim workerName As String = helmet.GetDefault("workerName", "Unknown")

				Dim alertMsg As String = ""
				If fallen Then
					alertMsg = workerName & " HAS FALLEN!"
				Else If temp > tempThresh Then
					alertMsg = workerName & ": High Temp " & NumberFormat(temp, 1, 1) & Chr(176) & "C"
				Else If gForce > gForceThresh Then
					alertMsg = workerName & ": High G-Force " & NumberFormat(gForce, 1, 2) & "G"
				End If

				If alertMsg <> "" Then
					Dim now As Long = DateTime.Now
					Dim snoozeExpiry As Long = snoozedHelmets.GetDefault(key, 0)
					Dim isSnoozed As Boolean = (snoozeExpiry > now)
					Dim lastAlarm As Long = alertedHelmets.GetDefault(key, 0)
					Dim readyToAlarm As Boolean = (now - lastAlarm > REPEAT_INTERVAL)
					Dim playSound As Boolean = Not(isSnoozed) And readyToAlarm And Not(Main.isAppForeground)

					SendNotification(alertMsg, key, playSound)

					If readyToAlarm Then
						alertedHelmets.Put(key, now)
					End If

					' Always write incident for dialog — overwrite only if no unread incident exists
					If Not(File.Exists(File.DirInternal, "incident.txt")) Then
						Dim timestamp As String = DateTime.Date(now) & " " & DateTime.Time(now)
						Dim incident As String = key & "|" & workerName & "|" & alertMsg & "|" & timestamp
						File.WriteString(File.DirInternal, "incident.txt", incident)
						Log("Incident written: " & incident)
					End If

					File.WriteString(File.DirInternal, "alert_helmet.txt", key)
				Else
					If alertedHelmets.ContainsKey(key) Then alertedHelmets.Remove(key)
					If snoozedHelmets.ContainsKey(key) Then snoozedHelmets.Remove(key)
				End If
			Next
		Catch
			Log("Alert check error: " & LastException)
		End Try
	End If
	Job.Release
End Sub

Sub SendNotification(message As String, helmetId As String, playSound As Boolean)
	Dim n As Notification
	n.Initialize
	n.Icon = "icon"
	n.Sound = playSound
	n.AutoCancel = True
	n.SetInfo("Safety Helmet Alert", message, Main)
	n.Notify(1)

	' Play custom sound via RingtoneManager if user selected one
	If playSound Then
		Try
			Dim rm As RingtoneManager
			If File.Exists(File.DirInternal, "alarm_sound_uri.txt") Then
				Dim uri As String = File.ReadString(File.DirInternal, "alarm_sound_uri.txt")
				rm.Play(uri)
			End If
		Catch
			Log("Sound play error: " & LastException)
		End Try
	End If

	Log("NOTIFICATION: " & message & " | sound=" & playSound)
End Sub

Sub Service_TaskRemoved
	StartServiceAt(Me, DateTime.Now + 1000, False)
End Sub

Sub Application_Error(Error As Exception, StackTrace As String) As Boolean
	Return True
End Sub

Sub Service_Destroy
	alertTimer.Enabled = False
	StartServiceAt(Me, DateTime.Now + 3000, False)
End Sub

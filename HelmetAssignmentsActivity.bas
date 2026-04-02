B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
'Construction Helmet IoT - Manager App
'Helmet Assignments Activity - FIREBASE VERSION with Editing

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
	Private colorGreen As Int = Colors.RGB(76, 175, 80)
	Private colorGray As Int = Colors.RGB(204, 204, 204)
	
	Private svAssignments As ScrollView
	Private assignmentsList As List
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.Color = colorBackground
	
	' Always initialize the list
	If assignmentsList.IsInitialized = False Then
		assignmentsList.Initialize
	End If
	
	CreateUI
	LoadAssignmentsFromFirebase
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
	lblTitle.Text = "Helmet Assignments"
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
	
	svAssignments.Initialize(0)
	Activity.AddView(svAssignments, 0, 90dip, 100%x, 100%y - 180dip)
End Sub

Sub LoadAssignmentsFromFirebase
	Dim job As HttpJob
	job.Initialize("get_helmets", Me)
	job.Download(Main.FIREBASE_URL & "/helmets.json")
End Sub

Sub JobDone(Job As HttpJob)
	If Job.Success Then
		Select Job.JobName
			Case "get_helmets"
				ProcessHelmetsData(Job.GetString)
			Case "update_worker"
				ToastMessageShow("Worker assignment updated!", True)
				LoadAssignmentsFromFirebase
			Case "load_workers_for_selection"
				ShowWorkerSelectionDialog(Job.GetString, Job.Tag)
		End Select
	Else
		Log("Error: " & Job.ErrorMessage)
		If Job.JobName = "load_workers_for_selection" Then
			ToastMessageShow("No workers in database. Add workers first.", False)
		Else
			ToastMessageShow("Failed to load data", False)
		End If
	End If
	Job.Release
End Sub

Sub ShowWorkerSelectionDialog(jsonString As String, helmetId As String)
	Try
		Log("Worker JSON Response: " & jsonString)
		
		Dim workerNames As List
		workerNames.Initialize
		workerNames.Add("Remove assignment")
		
		If jsonString <> "null" And jsonString <> "" Then
			Dim parser As JSONParser
			parser.Initialize(jsonString)
			Dim root As Map = parser.NextObject
			
			Log("Workers found: " & root.Size)
			
			' Root contains WORKER_IDs as keys
			For Each workerId As String In root.Keys
				Dim workerData As Object = root.Get(workerId)
				
				' Check if workerData is a Map (has name, position, phone)
				If workerData Is Map Then
					Dim workerMap As Map = workerData
					' Get the actual worker name from the "name" field
					If workerMap.ContainsKey("name") Then
						Dim name As String = workerMap.Get("name")
						Log("Worker name: " & name)
						workerNames.Add(name)
					End If
				End If
			Next
		End If
		
		If workerNames.Size = 1 Then
			ToastMessageShow("No workers in database. Add workers first.", False)
			Return
		End If
		
		Dim result As Int = InputList(workerNames, "Assign Worker to " & helmetId, -1)
		
		If result = 0 Then
			' Remove assignment
			UpdateWorkerAssignment(helmetId, "Unassigned")
		Else If result > 0 Then
			Dim selectedWorker As String = workerNames.Get(result)
			UpdateWorkerAssignment(helmetId, selectedWorker)
		End If
		
	Catch
		Log("Error parsing workers: " & LastException)
		Log("Error message: " & LastException.Message)
		ToastMessageShow("Error: " & LastException.Message, True)
	End Try
End Sub

Sub ProcessHelmetsData(jsonString As String)
	assignmentsList.Clear
	
	' Handle empty response
	If jsonString = "null" Or jsonString = "" Or jsonString = Null Then
		DisplayAssignments
		Return
	End If
	
	Try
		Dim parser As JSONParser
		parser.Initialize(jsonString)
		
		' Check if it's a valid JSON object
		Dim root As Map
		Try
			root = parser.NextObject
		Catch
			' Invalid JSON
			DisplayAssignments
			Return
		End Try
		
		' Check if root is empty
		If root.Size = 0 Then
			DisplayAssignments
			Return
		End If
		
		' Process each helmet
		For Each key As String In root.Keys
			Try
				Dim helmetData As Object = root.Get(key)
				
				' Only process if it's a Map
				If helmetData Is Map Then
					Dim helmetMap As Map = helmetData
					Dim assignment As Map
					assignment.Initialize
					
					' Safely get helmet ID
					assignment.Put("helmetId", key)
					
					' Safely get worker name
					Dim workerName As String = "Unassigned"
					If helmetMap.ContainsKey("workerName") Then
						Dim wn As Object = helmetMap.Get("workerName")
						If wn <> Null Then
							workerName = wn
						End If
					End If
					assignment.Put("workerName", workerName)
					
					' Safely get status
					Dim status As String = "offline"
					If helmetMap.ContainsKey("status") Then
						Dim st As Object = helmetMap.Get("status")
						If st <> Null Then
							status = st
						End If
					End If
					assignment.Put("status", status)
					
					assignmentsList.Add(assignment)
				End If
			Catch
				' Skip this helmet if there's an error
				Continue
			End Try
		Next
		
		DisplayAssignments
		
	Catch
		' If all else fails, show empty list
		DisplayAssignments
	End Try
End Sub

Sub DisplayAssignments
	svAssignments.Panel.RemoveAllViews
	
	Dim yPos As Int = 15dip
	
	If assignmentsList.Size = 0 Then
		Dim lblNoData As Label
		lblNoData.Initialize("")
		lblNoData.Text = "No helmets found" & CRLF & "Check Firebase database"
		lblNoData.TextSize = 16
		lblNoData.TextColor = Colors.RGB(136, 136, 136)
		lblNoData.Gravity = Gravity.CENTER
		svAssignments.Panel.AddView(lblNoData, 20dip, 50dip, 100%x - 40dip, 100dip)
		svAssignments.Panel.Height = 200dip
		Return
	End If
	
	For Each assignment As Map In assignmentsList
		Dim helmetId As String = assignment.Get("helmetId")
		Dim workerName As String = assignment.Get("workerName")
		Dim status As String = assignment.Get("status")
		Dim isAssigned As Boolean = (workerName <> "Unassigned" And workerName <> "")
		
		Dim pnlCard As Panel
		pnlCard.Initialize("")
		pnlCard.Color = colorWhite
		svAssignments.Panel.AddView(pnlCard, 15dip, yPos, 100%x - 30dip, 145dip)
		
		Dim lblHelmetId As Label
		lblHelmetId.Initialize("")
		lblHelmetId.Text = helmetId
		lblHelmetId.TextSize = 15
		lblHelmetId.Typeface = Typeface.DEFAULT_BOLD
		lblHelmetId.TextColor = Colors.RGB(51, 51, 51)
		pnlCard.AddView(lblHelmetId, 20dip, 15dip, 180dip, 25dip)
		
		Dim pnlStatus As Panel
		pnlStatus.Initialize("")
		If isAssigned Then
			pnlStatus.Color = colorGreen
		Else
			pnlStatus.Color = colorGray
		End If
		pnlCard.AddView(pnlStatus, pnlCard.Width - 100dip, 12dip, 80dip, 28dip)
		
		Dim lblStatus As Label
		lblStatus.Initialize("")
		If isAssigned Then
			lblStatus.Text = "Assigned"
		Else
			lblStatus.Text = "Unassigned"
		End If
		lblStatus.TextSize = 11
		lblStatus.TextColor = colorWhite
		lblStatus.Gravity = Gravity.CENTER
		pnlStatus.AddView(lblStatus, 0, 0, 80dip, 28dip)
		
		Dim pnlWorker As Panel
		pnlWorker.Initialize("")
		pnlWorker.Color = colorBackground
		pnlCard.AddView(pnlWorker, 20dip, 50dip, pnlCard.Width - 40dip, 50dip)
		
		Dim lblWorker As Label
		lblWorker.Initialize("")
		lblWorker.Text = "👤 " & workerName
		lblWorker.TextSize = 14
		lblWorker.TextColor = Colors.RGB(102, 102, 102)
		pnlWorker.AddView(lblWorker, 15dip, 15dip, pnlWorker.Width - 30dip, 25dip)
		
		Dim btnEdit As Button
		btnEdit.Initialize("btnEdit")
		btnEdit.Tag = helmetId
		If isAssigned Then
			btnEdit.Text = "Edit Assignment"
		Else
			btnEdit.Text = "Assign Worker"
		End If
		btnEdit.TextSize = 13
		btnEdit.Typeface = Typeface.DEFAULT_BOLD
		btnEdit.TextColor = Colors.RGB(102, 102, 102)
		btnEdit.Color = colorBackground
		pnlCard.AddView(btnEdit, 20dip, 110dip, pnlCard.Width - 40dip, 40dip)
		
		yPos = yPos + 155dip
	Next
	
	svAssignments.Panel.Height = yPos
End Sub

Sub btnEdit_Click
	Dim btn As Button = Sender
	Dim helmetId As String = btn.Tag
	
	' Load workers from database
	LoadWorkersForSelection(helmetId)
End Sub

Sub LoadWorkersForSelection(helmetId As String)
	Dim job As HttpJob
	job.Initialize("load_workers_for_selection", Me)
	job.Tag = helmetId
	job.Download(Main.FIREBASE_URL & "/workers.json")
End Sub

Sub UpdateWorkerAssignment(helmetId As String, workerName As String)
	Dim job As HttpJob
	job.Initialize("update_worker", Me)
	
	Dim json As JSONGenerator
	json.Initialize(CreateMap("workerName": workerName))
	
	job.PatchString(Main.FIREBASE_URL & "/helmets/" & helmetId & ".json", json.ToString)
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
	' Reload assignments when returning to this screen
	LoadAssignmentsFromFirebase
End Sub

Sub Activity_Pause (UserClosed As Boolean)
	
End Sub

B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
'Construction Helmet IoT - Manager App
'Worker Database Activity - COMPLETE VERSION with Manual Input and Cascade Updates

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
	
	Private svWorkers As ScrollView
	Private workersList As List
	Private btnAddWorker As Button
	
	' For input dialogs
	Private edtWorkerName As EditText
	Private edtWorkerPosition As EditText
	Private edtWorkerPhone As EditText
	Private pnlInputDialog As Panel
	Private currentEditWorkerId As String
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.Color = colorBackground
	
	' Always initialize the list
	If workersList.IsInitialized = False Then
		workersList.Initialize
	End If
	
	currentEditWorkerId = ""
	
	CreateUI
	LoadWorkersFromFirebase
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
	lblTitle.Text = "Worker Database"
	lblTitle.TextColor = colorWhite
	lblTitle.TextSize = 20
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.Gravity = Gravity.CENTER
	pnlHeader.AddView(lblTitle, 80dip, 25dip, 100%x - 160dip, 40dip)
	
	' STANDARD ADD BUTTON - 60x60, 15 from top, 36pt, white, centered
	btnAddWorker.Initialize("btnAddWorker")
	btnAddWorker.Gravity = Gravity.CENTER
	btnAddWorker.Text = "+"
	btnAddWorker.TextSize = 36
	btnAddWorker.TextColor = colorWhite
	btnAddWorker.Color = Colors.Transparent
	pnlHeader.AddView(btnAddWorker, 100%x - 70dip, 15dip, 60dip, 60dip)
	
	' STANDARD HOME BUTTON - 70dip tall, 40pt icon, black, centered
	Dim btnHome As Button
	btnHome.Initialize("btnHome")
	btnHome.Gravity = Gravity.CENTER
	btnHome.Text = "🏠"
	btnHome.TextSize = 40
	btnHome.TextColor = Colors.Black
	btnHome.Color = Colors.Transparent
	Activity.AddView(btnHome, 20dip, 100%y - 90dip, 100%x - 40dip, 70dip)
	
	svWorkers.Initialize(0)
	Activity.AddView(svWorkers, 0, 90dip, 100%x, 100%y - 180dip)
End Sub

Sub LoadWorkersFromFirebase
	Dim job As HttpJob
	job.Initialize("get_workers", Me)
	job.Download(Main.FIREBASE_URL & "/workers.json")
End Sub

Sub JobDone(Job As HttpJob)
	If Job.Success Then
		Select Job.JobName
			Case "get_workers"
				ProcessWorkersData(Job.GetString)
			Case "add_worker"
				ToastMessageShow("Worker added successfully!", True)
				LoadWorkersFromFirebase
			Case "update_worker"
				ToastMessageShow("Worker updated successfully!", True)
				LoadWorkersFromFirebase
			Case "delete_worker"
				ToastMessageShow("Worker deleted", True)
				LoadWorkersFromFirebase
			Case "get_helmets_for_cascade"
				CascadeUpdateHelmets(Job.GetString, Job.Tag)
			Case "get_helmets_for_delete_cascade"
				CascadeDeleteFromHelmets(Job.GetString, Job.Tag)
		End Select
	Else
		Log("Error: " & Job.ErrorMessage)
		If Job.JobName = "get_workers" Then
			workersList.Clear
			DisplayWorkers
		Else
			ToastMessageShow("Operation failed", False)
		End If
	End If
	Job.Release
End Sub

Sub ProcessWorkersData(jsonString As String)
	Try
		workersList.Clear
		
		If jsonString = "null" Or jsonString = "" Then
			DisplayWorkers
			Return
		End If
		
		Dim parser As JSONParser
		parser.Initialize(jsonString)
		Dim root As Map = parser.NextObject
		
		For Each key As String In root.Keys
			Dim workerMap As Map = root.Get(key)
			workerMap.Put("id", key)
			workersList.Add(workerMap)
		Next
		
		DisplayWorkers
		
	Catch
		Log("Error parsing: " & LastException)
		DisplayWorkers
	End Try
End Sub

Sub DisplayWorkers
	svWorkers.Panel.RemoveAllViews
	
	Dim yPos As Int = 15dip
	
	If workersList.Size = 0 Then
		Dim lblNoData As Label
		lblNoData.Initialize("")
		lblNoData.Text = "No workers in database" & CRLF & "Click + to add workers"
		lblNoData.TextSize = 16
		lblNoData.TextColor = Colors.RGB(136, 136, 136)
		lblNoData.Gravity = Gravity.CENTER
		svWorkers.Panel.AddView(lblNoData, 20dip, 50dip, 100%x - 40dip, 100dip)
		svWorkers.Panel.Height = 200dip
		Return
	End If
	
	For Each worker As Map In workersList
		Dim workerId As String = worker.Get("id")
		Dim workerName As String = worker.Get("name")
		Dim workerPosition As String = worker.GetDefault("position", "Worker")
		Dim workerPhone As String = worker.GetDefault("phone", "N/A")
		
		Dim pnlCard As Panel
		pnlCard.Initialize("")
		pnlCard.Color = colorWhite
		svWorkers.Panel.AddView(pnlCard, 15dip, yPos, 100%x - 30dip, 120dip)
		
		Dim lblIcon As Label
		lblIcon.Initialize("")
		lblIcon.Text = "👤"
		lblIcon.TextSize = 32
		lblIcon.Gravity = Gravity.CENTER
		pnlCard.AddView(lblIcon, 15dip, 20dip, 50dip, 50dip)
		
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = workerName
		lblName.TextSize = 16
		lblName.Typeface = Typeface.DEFAULT_BOLD
		lblName.TextColor = Colors.RGB(51, 51, 51)
		pnlCard.AddView(lblName, 80dip, 15dip, 180dip, 25dip)
		
		Dim lblPosition As Label
		lblPosition.Initialize("")
		lblPosition.Text = workerPosition
		lblPosition.TextSize = 13
		lblPosition.TextColor = Colors.RGB(102, 102, 102)
		pnlCard.AddView(lblPosition, 80dip, 40dip, 150dip, 25dip)
		
		Dim lblPhone As Label
		lblPhone.Initialize("")
		lblPhone.Text = "📱 " & workerPhone
		lblPhone.TextSize = 12
		lblPhone.TextColor = Colors.RGB(136, 136, 136)
		pnlCard.AddView(lblPhone, 80dip, 65dip, 200dip, 25dip)
		
		' Edit button
		Dim btnEdit As Button
		btnEdit.Initialize("btnEditWorker")
		btnEdit.Tag = workerId
		btnEdit.Text = "✏"
		btnEdit.TextSize = 18
		btnEdit.TextColor = colorPrimary
		btnEdit.Color = Colors.Transparent
		pnlCard.AddView(btnEdit, pnlCard.Width - 110dip, 30dip, 50dip, 40dip)
		
		' Delete button
		Dim btnDelete As Button
		btnDelete.Initialize("btnDeleteWorker")
		btnDelete.Tag = CreateMap("id": workerId, "name": workerName)
		btnDelete.Text = "🗑"
		btnDelete.TextSize = 20
		btnDelete.TextColor = Colors.RGB(220, 53, 69)
		btnDelete.Color = Colors.Transparent
		pnlCard.AddView(btnDelete, pnlCard.Width - 60dip, 30dip, 50dip, 40dip)
		
		yPos = yPos + 130dip
	Next
	
	svWorkers.Panel.Height = yPos
End Sub

Sub btnAddWorker_Click
	ShowInputDialog("", "", "", "add")
End Sub

Sub btnEditWorker_Click
	Dim btn As Button = Sender
	Dim workerId As String = btn.Tag
	
	' Find worker data
	For Each worker As Map In workersList
		If worker.Get("id") = workerId Then
			Dim name As String = worker.Get("name")
			Dim position As String = worker.GetDefault("position", "")
			Dim phone As String = worker.GetDefault("phone", "")
			ShowInputDialog(name, position, phone, "edit")
			currentEditWorkerId = workerId
			Return
		End If
	Next
End Sub

Sub ShowInputDialog(name As String, position As String, phone As String, mode As String)
	' Create overlay panel
	pnlInputDialog.Initialize("")
	pnlInputDialog.Color = Colors.ARGB(200, 0, 0, 0)
	Activity.AddView(pnlInputDialog, 0, 0, 100%x, 100%y)
	
	' Dialog box - compact version
	Dim pnlDialog As Panel
	pnlDialog.Initialize("")
	pnlDialog.Color = colorWhite
	pnlInputDialog.AddView(pnlDialog, 5%x, 20dip, 90%x, 360dip)
	
	Dim yPos As Int = 15dip
	
	' Title
	Dim lblDialogTitle As Label
	lblDialogTitle.Initialize("")
	If mode = "add" Then
		lblDialogTitle.Text = "Add New Worker"
	Else
		lblDialogTitle.Text = "Edit Worker"
	End If
	lblDialogTitle.TextSize = 16
	lblDialogTitle.Typeface = Typeface.DEFAULT_BOLD
	lblDialogTitle.TextColor = colorPrimary
	lblDialogTitle.Gravity = Gravity.CENTER
	pnlDialog.AddView(lblDialogTitle, 10dip, yPos, 90%x - 20dip, 25dip)
	
	yPos = yPos + 35dip
	
	' Name field
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = "Full Name *"
	lblName.TextSize = 12
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.TextColor = Colors.RGB(51, 51, 51)
	pnlDialog.AddView(lblName, 15dip, yPos, 200dip, 18dip)
	
	yPos = yPos + 20dip
	
	edtWorkerName.Initialize("")
	edtWorkerName.Text = name
	edtWorkerName.Hint = "e.g., Juan Dela Cruz"
	edtWorkerName.TextSize = 14
	pnlDialog.AddView(edtWorkerName, 15dip, yPos, 90%x - 30dip, 40dip)
	
	yPos = yPos + 48dip
	
	' Position field
	Dim lblPosition As Label
	lblPosition.Initialize("")
	lblPosition.Text = "Position"
	lblPosition.TextSize = 12
	lblPosition.Typeface = Typeface.DEFAULT_BOLD
	lblPosition.TextColor = Colors.RGB(51, 51, 51)
	pnlDialog.AddView(lblPosition, 15dip, yPos, 200dip, 18dip)
	
	yPos = yPos + 20dip
	
	edtWorkerPosition.Initialize("")
	edtWorkerPosition.Text = position
	edtWorkerPosition.Hint = "e.g., Construction Worker"
	edtWorkerPosition.TextSize = 14
	pnlDialog.AddView(edtWorkerPosition, 15dip, yPos, 90%x - 30dip, 40dip)
	
	yPos = yPos + 48dip
	
	' Phone field
	Dim lblPhone As Label
	lblPhone.Initialize("")
	lblPhone.Text = "Phone Number"
	lblPhone.TextSize = 12
	lblPhone.Typeface = Typeface.DEFAULT_BOLD
	lblPhone.TextColor = Colors.RGB(51, 51, 51)
	pnlDialog.AddView(lblPhone, 15dip, yPos, 200dip, 18dip)
	
	yPos = yPos + 20dip
	
	edtWorkerPhone.Initialize("")
	edtWorkerPhone.Text = phone
	edtWorkerPhone.Hint = "e.g., 09171234567"
	edtWorkerPhone.TextSize = 14
	edtWorkerPhone.InputType = edtWorkerPhone.INPUT_TYPE_PHONE
	pnlDialog.AddView(edtWorkerPhone, 15dip, yPos, 90%x - 30dip, 40dip)
	
	yPos = yPos + 50dip
	
	' Buttons - NOW VISIBLE!
	Dim buttonWidth As Int = (90%x - 45dip) / 2
	
	Dim btnCancel As Button
	btnCancel.Initialize("btnCancelDialog")
	btnCancel.Text = "Cancel"
	btnCancel.TextSize = 14
	btnCancel.TextColor = Colors.RGB(102, 102, 102)
	btnCancel.Color = colorBackground
	pnlDialog.AddView(btnCancel, 15dip, yPos, buttonWidth, 45dip)
	
	Dim btnSave As Button
	btnSave.Initialize("btnSaveDialog")
	btnSave.Tag = mode
	btnSave.Text = "Save"
	btnSave.TextSize = 14
	btnSave.Typeface = Typeface.DEFAULT_BOLD
	btnSave.TextColor = colorWhite
	btnSave.Color = colorPrimary
	pnlDialog.AddView(btnSave, 25dip + buttonWidth, yPos, buttonWidth, 45dip)
End Sub

Sub btnCancelDialog_Click
	Activity.RemoveViewAt(Activity.NumberOfViews - 1)
End Sub

Sub btnSaveDialog_Click
	Dim btn As Button = Sender
	Dim mode As String = btn.Tag
	
	Dim name As String = edtWorkerName.Text.Trim
	Dim position As String = edtWorkerPosition.Text.Trim
	Dim phone As String = edtWorkerPhone.Text.Trim
	
	If name = "" Then
		ToastMessageShow("Worker name is required", False)
		Return
	End If
	
	If position = "" Then position = "Worker"
	If phone = "" Then phone = "N/A"
	
	Activity.RemoveViewAt(Activity.NumberOfViews - 1)
	
	If mode = "add" Then
		AddWorkerToFirebase(name, position, phone)
	Else If mode = "edit" Then
		' Get old name for cascade update
		Dim oldName As String = ""
		For Each worker As Map In workersList
			If worker.Get("id") = currentEditWorkerId Then
				oldName = worker.Get("name")
				Exit
			End If
		Next
		
		UpdateWorkerInFirebase(currentEditWorkerId, name, position, phone, oldName)
	End If
End Sub

Sub AddWorkerToFirebase(name As String, position As String, phone As String)
	Dim job As HttpJob
	job.Initialize("add_worker", Me)
	
	Dim workerId As String = "WORKER_" & DateTime.Now
	
	Dim json As JSONGenerator
	json.Initialize(CreateMap("name": name, "position": position, "phone": phone))
	
	job.PutString(Main.FIREBASE_URL & "/workers/" & workerId & ".json", json.ToString)
	job.GetRequest.SetContentType("application/json")
End Sub

Sub UpdateWorkerInFirebase(workerId As String, name As String, position As String, phone As String, oldName As String)
	Dim job As HttpJob
	job.Initialize("update_worker", Me)
	
	Dim json As JSONGenerator
	json.Initialize(CreateMap("name": name, "position": position, "phone": phone))
	
	job.PatchString(Main.FIREBASE_URL & "/workers/" & workerId & ".json", json.ToString)
	job.GetRequest.SetContentType("application/json")
	
	' Cascade update to helmets if name changed
	If oldName <> name Then
		CascadeNameChange(oldName, name)
	End If
End Sub

Sub CascadeNameChange(oldName As String, newName As String)
	' Load all helmets to find those assigned to this worker
	Dim job As HttpJob
	job.Initialize("get_helmets_for_cascade", Me)
	job.Tag = CreateMap("oldName": oldName, "newName": newName)
	job.Download(Main.FIREBASE_URL & "/helmets.json")
End Sub

Sub CascadeUpdateHelmets(jsonString As String, tagMap As Map)
	Try
		If jsonString = "null" Or jsonString = "" Then Return
		
		Dim oldName As String = tagMap.Get("oldName")
		Dim newName As String = tagMap.Get("newName")
		
		Dim parser As JSONParser
		parser.Initialize(jsonString)
		Dim root As Map = parser.NextObject
		
		For Each helmetId As String In root.Keys
			Dim helmetMap As Map = root.Get(helmetId)
			Dim assignedWorker As String = helmetMap.GetDefault("workerName", "")
			
			If assignedWorker = oldName Then
				' Update this helmet
				Dim job As HttpJob
				job.Initialize("cascade_update_helmet", Me)
				
				Dim json As JSONGenerator
				json.Initialize(CreateMap("workerName": newName))
				
				job.PatchString(Main.FIREBASE_URL & "/helmets/" & helmetId & ".json", json.ToString)
				job.GetRequest.SetContentType("application/json")
			End If
		Next
	Catch
		Log("Cascade update error: " & LastException)
	End Try
End Sub

Sub btnDeleteWorker_Click
	Dim btn As Button = Sender
	Dim tagMap As Map = btn.Tag
	Dim workerId As String = tagMap.Get("id")
	Dim workerName As String = tagMap.Get("name")
	
	Dim result As Int = Msgbox2("Delete " & workerName & "?" & CRLF & "This will also unassign them from all helmets.", "Delete Worker", "Delete", "", "Cancel", Null)
	
	If result = DialogResponse.POSITIVE Then
		DeleteWorkerFromFirebase(workerId, workerName)
	End If
End Sub

Sub DeleteWorkerFromFirebase(workerId As String, workerName As String)
	' First cascade delete from helmets
	Dim job As HttpJob
	job.Initialize("get_helmets_for_delete_cascade", Me)
	job.Tag = CreateMap("workerId": workerId, "workerName": workerName)
	job.Download(Main.FIREBASE_URL & "/helmets.json")
End Sub

Sub CascadeDeleteFromHelmets(jsonString As String, tagMap As Map)
	Try
		Dim workerId As String = tagMap.Get("workerId")
		Dim workerName As String = tagMap.Get("workerName")
		
		If jsonString <> "null" And jsonString <> "" Then
			Dim parser As JSONParser
			parser.Initialize(jsonString)
			Dim root As Map = parser.NextObject
			
			For Each helmetId As String In root.Keys
				Dim helmetMap As Map = root.Get(helmetId)
				Dim assignedWorker As String = helmetMap.GetDefault("workerName", "")
				
				If assignedWorker = workerName Then
					' Unassign from this helmet
					Dim job As HttpJob
					job.Initialize("cascade_delete_helmet", Me)
					
					Dim json As JSONGenerator
					json.Initialize(CreateMap("workerName": "Unassigned"))
					
					job.PatchString(Main.FIREBASE_URL & "/helmets/" & helmetId & ".json", json.ToString)
					job.GetRequest.SetContentType("application/json")
				End If
			Next
		End If
		
		' Now delete the worker
		Dim job As HttpJob
		job.Initialize("delete_worker", Me)
		job.Delete(Main.FIREBASE_URL & "/workers/" & workerId & ".json")
		
	Catch
		Log("Cascade delete error: " & LastException)
	End Try
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

Sub Activity_Pause (UserClosed As Boolean)
	
End Sub

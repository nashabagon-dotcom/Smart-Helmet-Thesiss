B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
'Construction Helmet IoT - Manager App
'Login Activity - REAL Firebase Authentication

#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	Private FIREBASE_API_KEY As String = "AIzaSyBObItlAdigV3Bd5YISWDhHAeptYc3F7x0"
	Private FIREBASE_AUTH_URL As String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="
End Sub

Sub Globals
	Private colorPrimary As Int = Colors.RGB(255, 107, 53)
	Private colorWhite As Int = Colors.White
	
	Private edtEmail As EditText
	Private edtPassword As EditText
	Private btnLogin As Button
	Private ProgressBar1 As ProgressBar
End Sub

Sub Activity_Create(FirstTime As Boolean)
	CreateUI
End Sub

Sub CreateUI
	Activity.Color = colorPrimary
	
	Dim yPos As Int = 100dip
	
	Dim pnlLogo As Panel
	pnlLogo.Initialize("")
	pnlLogo.Color = colorWhite
	Activity.AddView(pnlLogo, 50%x - 40dip, yPos, 80dip, 80dip)
	
	Dim lblIcon As Label
	lblIcon.Initialize("")
	lblIcon.Text = "⛑️"
	lblIcon.TextSize = 40
	lblIcon.Gravity = Gravity.CENTER
	pnlLogo.AddView(lblIcon, 0, 0, 80dip, 80dip)
	
	yPos = yPos + 100dip
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = "Helmet Monitor"
	lblTitle.TextSize = 24
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.TextColor = colorWhite
	lblTitle.Gravity = Gravity.CENTER
	Activity.AddView(lblTitle, 10%x, yPos, 80%x, 35dip)
	
	yPos = yPos + 40dip
	
	Dim lblSubtitle As Label
	lblSubtitle.Initialize("")
	lblSubtitle.Text = "Safety Management System"
	lblSubtitle.TextSize = 14
	lblSubtitle.TextColor = colorWhite
	lblSubtitle.Gravity = Gravity.CENTER
	Activity.AddView(lblSubtitle, 10%x, yPos, 80%x, 25dip)
	
	yPos = yPos + 60dip
	
	Dim lblEmailLabel As Label
	lblEmailLabel.Initialize("")
	lblEmailLabel.Text = "Email"
	lblEmailLabel.TextSize = 13
	lblEmailLabel.TextColor = colorWhite
	lblEmailLabel.Typeface = Typeface.DEFAULT_BOLD
	Activity.AddView(lblEmailLabel, 10%x, yPos, 80%x, 20dip)
	
	yPos = yPos + 25dip
	
	edtEmail.Initialize("")
	edtEmail.Hint = "Enter email"
	edtEmail.TextSize = 15
	edtEmail.Color = colorWhite
	edtEmail.InputType = edtEmail.INPUT_TYPE_TEXT
	Activity.AddView(edtEmail, 10%x, yPos, 80%x, 50dip)
	
	yPos = yPos + 65dip
	
	Dim lblPasswordLabel As Label
	lblPasswordLabel.Initialize("")
	lblPasswordLabel.Text = "Password"
	lblPasswordLabel.TextSize = 13
	lblPasswordLabel.TextColor = colorWhite
	lblPasswordLabel.Typeface = Typeface.DEFAULT_BOLD
	Activity.AddView(lblPasswordLabel, 10%x, yPos, 80%x, 20dip)
	
	yPos = yPos + 25dip
	
	edtPassword.Initialize("")
	edtPassword.Hint = "Enter password"
	edtPassword.PasswordMode = True
	edtPassword.TextSize = 15
	edtPassword.Color = colorWhite
	Activity.AddView(edtPassword, 10%x, yPos, 80%x, 50dip)
	
	yPos = yPos + 70dip
	
	btnLogin.Initialize("btnLogin")
	btnLogin.Text = "Login"
	btnLogin.TextSize = 16
	btnLogin.Typeface = Typeface.DEFAULT_BOLD
	btnLogin.TextColor = colorWhite
	btnLogin.Color = Colors.RGB(26, 26, 26)
	Activity.AddView(btnLogin, 10%x, yPos, 80%x, 60dip)
	
	ProgressBar1.Initialize("")
	ProgressBar1.Visible = False
	Activity.AddView(ProgressBar1, 10%x, yPos + 70dip, 80%x, 50dip)
End Sub

Sub btnLogin_Click
	Dim email As String = edtEmail.Text.Trim
	Dim password As String = edtPassword.Text.Trim
	
	If email = "" Then
		ToastMessageShow("Please enter email", False)
		Return
	End If
	
	If password = "" Then
		ToastMessageShow("Please enter password", False)
		Return
	End If
	
	If password.Length < 6 Then
		ToastMessageShow("Password must be at least 6 characters", False)
		Return
	End If
	
	btnLogin.Enabled = False
	ProgressBar1.Visible = True
	
	LoginWithFirebase(email, password)
End Sub

Sub LoginWithFirebase(email As String, password As String)
	Dim job As HttpJob
	job.Initialize("firebase_login", Me)
	
	Dim json As JSONGenerator
	json.Initialize(CreateMap("email": email, "password": password, "returnSecureToken": True))
	
	job.PostString(FIREBASE_AUTH_URL & FIREBASE_API_KEY, json.ToString)
	job.GetRequest.SetContentType("application/json")
End Sub

Sub JobDone(Job As HttpJob)
	If Job.Success Then
		Select Job.JobName
			Case "firebase_login"
				Try
					Dim parser As JSONParser
					parser.Initialize(Job.GetString)
					Dim root As Map = parser.NextObject
					
					If root.ContainsKey("idToken") Then
						Dim email As String = root.Get("email")
						Dim idToken As String = root.Get("idToken")
						Dim userId As String = root.Get("localId")
						
						SaveLoginState(email, idToken, userId)
						
						ToastMessageShow("Login successful!", True)
						StartActivity(Main)
						Activity.Finish
					Else
						btnLogin.Enabled = True
						ProgressBar1.Visible = False
						ToastMessageShow("Login failed", False)
					End If
				Catch
					Log("Login error: " & LastException)
					btnLogin.Enabled = True
					ProgressBar1.Visible = False
					ToastMessageShow("Login error: " & LastException.Message, False)
				End Try
		End Select
	Else
		Log("HTTP Error: " & Job.ErrorMessage)
		btnLogin.Enabled = True
		ProgressBar1.Visible = False
		
		Try
			Dim parser As JSONParser
			parser.Initialize(Job.GetString)
			Dim root As Map = parser.NextObject
			Dim errorMsg As Map = root.Get("error")
			Dim message As String = errorMsg.Get("message")
			
			If message.Contains("INVALID_PASSWORD") Or message.Contains("EMAIL_NOT_FOUND") Then
				ToastMessageShow("Invalid email or password", False)
			Else If message.Contains("USER_DISABLED") Then
				ToastMessageShow("Account has been disabled", False)
			Else
				ToastMessageShow("Login failed: " & message, False)
			End If
		Catch
			ToastMessageShow("Login failed. Check your connection.", False)
		End Try
	End If
	Job.Release
End Sub

Sub SaveLoginState(email As String, token As String, userId As String)
	File.WriteString(File.DirInternal, "login.txt", "true")
	File.WriteString(File.DirInternal, "email.txt", email)
	File.WriteString(File.DirInternal, "token.txt", token)
	File.WriteString(File.DirInternal, "userid.txt", userId)
End Sub

Sub Activity_Resume
	
End Sub

Sub Activity_Pause (UserClosed As Boolean)
	
End Sub

B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.8
@EndOfDesignText@
'Construction Helmet IoT - Manager App
'Change Password Activity (UI Only)

#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	
End Sub

Sub Globals
	'Colors
	Private colorPrimary As Int = Colors.RGB(255, 107, 53)
	Private colorWhite As Int = Colors.White
	Private colorBackground As Int = Colors.RGB(248, 249, 250)
	
	'Views
	Private edtCurrentPassword As EditText
	Private edtNewPassword As EditText
	Private edtConfirmPassword As EditText
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.Color = colorBackground
	
	CreateUI
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
	
	'Title
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = "Change Password"
	lblTitle.TextColor = colorWhite
	lblTitle.TextSize = 20
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.Gravity = Gravity.CENTER
	pnlHeader.AddView(lblTitle, 80dip, 25dip, 100%x - 90dip, 40dip)
	
	Dim yPos As Int = 110dip
	
	'Current Password
	Dim lblCurrent As Label
	lblCurrent.Initialize("")
	lblCurrent.Text = "Current Password"
	lblCurrent.TextSize = 14
	lblCurrent.Typeface = Typeface.DEFAULT_BOLD
	lblCurrent.TextColor = Colors.RGB(51, 51, 51)
	Activity.AddView(lblCurrent, 20dip, yPos, 250dip, 25dip)
	
	yPos = yPos + 30dip
	
	edtCurrentPassword.Initialize("")
	edtCurrentPassword.Hint = "Enter current password"
	edtCurrentPassword.PasswordMode = True
	edtCurrentPassword.TextSize = 15
	edtCurrentPassword.Color = colorWhite
	Activity.AddView(edtCurrentPassword, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 70dip
	
	'New Password
	Dim lblNew As Label
	lblNew.Initialize("")
	lblNew.Text = "New Password"
	lblNew.TextSize = 14
	lblNew.Typeface = Typeface.DEFAULT_BOLD
	lblNew.TextColor = Colors.RGB(51, 51, 51)
	Activity.AddView(lblNew, 20dip, yPos, 250dip, 25dip)
	
	yPos = yPos + 30dip
	
	edtNewPassword.Initialize("")
	edtNewPassword.Hint = "Enter new password"
	edtNewPassword.PasswordMode = True
	edtNewPassword.TextSize = 15
	edtNewPassword.Color = colorWhite
	Activity.AddView(edtNewPassword, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 70dip
	
	'Confirm Password
	Dim lblConfirm As Label
	lblConfirm.Initialize("")
	lblConfirm.Text = "Confirm New Password"
	lblConfirm.TextSize = 14
	lblConfirm.Typeface = Typeface.DEFAULT_BOLD
	lblConfirm.TextColor = Colors.RGB(51, 51, 51)
	Activity.AddView(lblConfirm, 20dip, yPos, 250dip, 25dip)
	
	yPos = yPos + 30dip
	
	edtConfirmPassword.Initialize("")
	edtConfirmPassword.Hint = "Re-enter new password"
	edtConfirmPassword.PasswordMode = True
	edtConfirmPassword.TextSize = 15
	edtConfirmPassword.Color = colorWhite
	Activity.AddView(edtConfirmPassword, 20dip, yPos, 100%x - 40dip, 50dip)
	
	yPos = yPos + 70dip
	
	'Save button
	Dim btnSave As Button
	btnSave.Initialize("btnSave")
	btnSave.Text = "Save Changes"
	btnSave.TextSize = 16
	btnSave.Typeface = Typeface.DEFAULT_BOLD
	btnSave.TextColor = colorWhite
	btnSave.Color = colorPrimary
	Activity.AddView(btnSave, 20dip, yPos, 100%x - 40dip, 60dip)
	
	yPos = yPos + 75dip
	
	' STANDARD HOME BUTTON - 70dip tall, 40pt icon, black, centered
	Dim btnHome As Button
	btnHome.Initialize("btnHome")
	btnHome.Gravity = Gravity.CENTER
	btnHome.Text = "🏠"
	btnHome.TextSize = 40
	btnHome.TextColor = Colors.Black
	btnHome.Color = Colors.Transparent
	Activity.AddView(btnHome, 20dip, yPos, 100%x - 40dip, 70dip)
End Sub

Sub btnBack_Click
	Activity.Finish
End Sub

Sub btnHome_Click
	' Go back to Main screen and close all other activities
	StartActivity(Main)
	ExitApplication
End Sub

Sub btnSave_Click
	If edtCurrentPassword.Text.Trim = "" Then
		ToastMessageShow("Please enter current password", False)
		Return
	End If
	
	If edtNewPassword.Text.Trim = "" Then
		ToastMessageShow("Please enter new password", False)
		Return
	End If
	
	If edtNewPassword.Text.Length < 6 Then
		ToastMessageShow("Password must be at least 6 characters", False)
		Return
	End If
	
	If edtNewPassword.Text <> edtConfirmPassword.Text Then
		ToastMessageShow("Passwords do not match", False)
		Return
	End If
	
	ToastMessageShow("Password changed successfully!", True)
	
	'Clear fields
	edtCurrentPassword.Text = ""
	edtNewPassword.Text = ""
	edtConfirmPassword.Text = ""
End Sub

Sub Activity_Resume
	
End Sub

Sub Activity_Pause (UserClosed As Boolean)
	
End Sub

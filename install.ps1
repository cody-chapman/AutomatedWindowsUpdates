Function WriteLog($string, $color)
{
   if ($Color -eq $null) {$color = "Green"}
   write-host $string -foregroundcolor $color
 }



$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 
$WSUS = $ScriptPath + "\WSUS.bat"

WriteLog "Disabling Firewall"
netsh advfirewall set allprofiles state off

WriteLog "Removing DEP" 
cmd.exe /c 'bcdedit.exe /set {current} nx AlwaysOff'

WriteLog "Disabling UAC" 
cmd.exe /c '%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f'

WriteLog  "Setting Time Zone to CST" 
C:\Windows\System32\tzutil.exe /s "Central Standard Time"

WriteLog  "Disabling IPv6" 
cmd.exe /c '%windir%\System32\reg.exe ADD HKLM\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters /v DisabledComponents /t REG_DWORD /d 0xffffffff /f' 

WriteLog "Enabling Remote Desktop"
Set-ItemProperty “HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server” -Name “fDenyTSConnections” -Value 0

WriteLog "Setting small memory dump"
gwmi Win32_OSRecoveryConfiguration -EnableAllPrivileges | swmi -Arguments @{DebugInfoType=1}

WriteLog "Adding user"
cmd.exe /c 'net user admin Password1 /add /fullname:"Admin"'

WriteLog "Adding user to Local Administrators"
cmd.exe /c 'net localgroup Administrators admin /add'

WriteLog "Adding user to Remote Desktop Users"
cmd.exe /c 'net localgroup "Remote Desktop Users" admin /add'

WriteLog  "Setting user password to not expire"
$user = [adsi]"WinNT://$env:computername/admin"
$user.UserFlags.value = $user.UserFlags.value -bor 0x10000
$user.CommitChanges()

WriteLog "Setting Autologon"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0x00000001" -Type DWORD ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "admin" ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "Pasword1" ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateAutoUpdater" -Value "$WSUS" ;

exit


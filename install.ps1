Function WriteLog($string, $color)
{
   if ($Color -eq $null) {$color = "Green"}
   write-host $string -foregroundcolor $color
 }

Import-Module ServerManager

$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 
$WSUS = $ScriptPath + "\WSUS.bat"

WriteLog "Disabling Server Manager from launching every login"
schtasks /change /tn '\Microsoft\Windows\Server Manager\ServerManager' /disable

WriteLog "Installing Web-Server"  
Add-WindowsFeature -Name Web-Server -IncludeAllSubFeature

WriteLog "Installing Application-Server"  
Add-WindowsFeature -Name Application-Server -IncludeAllSubFeature

WriteLog  "Installing SMTP-Server"
Add-WindowsFeature -Name SMTP-Server -IncludeAllSubFeature
WriteLog  "Setting SMTP Startup to Automatic" 
Set-Service "SMTPSVC" -StartupType Automatic

WriteLog "Installing Qwave"
Add-WindowsFeature -Name qwave -IncludeAllSubFeature
Set-Service "qwave" -StartupType Automatic


WriteLog  "IE Enhanced Security Configuration (ESC) has been disabled."
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" 

$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" 

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0  

Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0  

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

WriteLog "Adding hfx_admin"
cmd.exe /c 'net user hfx_admin hfx!!3333 /add /fullname:"Heraflux Admin"'

WriteLog "Adding hfx_admin to Local Administrators"
cmd.exe /c 'net localgroup Administrators hfx_admin /add'

WriteLog "Adding hfx_admin to Remote Desktop Users"
cmd.exe /c 'net localgroup "Remote Desktop Users" hfx_admin /add'

WriteLog  "Setting hfx_admin password to not expire"
$user = [adsi]"WinNT://$env:computername/hfx_admin"
$user.UserFlags.value = $user.UserFlags.value -bor 0x10000
$user.CommitChanges()

WriteLog "Setting Autologon"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0x00000001" -Type DWORD ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "hfx_admin" ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "hfx!!3333" ;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateAutoUpdater" -Value "$WSUS" ;

exit


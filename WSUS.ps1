Function WriteLog($string, $color)
{
   if ($Color -eq $null) {$color = "Green"}
   write-host $string -foregroundcolor $color
}
Function RemoveAutologon {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon";
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName";
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" ;
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateAutoUpdater" ;
    shutdown /f /l /t 0
}
Start-Sleep -s 25

WriteLog  "Checking for Windows Updates"

function Get-WIAStatusValue($value)
{

	switch -exact ($value)

	{

	0   {"NotStarted"}


	1   {"InProgress"}



	2   {"Succeeded"}



	3   {"SucceededWithErrors"}



	4   {"Failed"}



	5   {"Aborted"}

	}

}

$needsReboot = $false

$UpdateSession = New-Object -ComObject Microsoft.Update.Session

$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

WriteLog  " - Searching for Updates"

$SearchResult = $UpdateSearcher.Search("IsHidden=0 and IsInstalled=0")

WriteLog " - Found [$($SearchResult.Updates.count)] updates to download and install"

WriteLog 

foreach($Update in $SearchResult.Updates) {

	$UpdatesCollection = New-Object -ComObject Microsoft.Update.UpdateColl

	if ( $Update.EulaAccepted -eq 0 ) { $Update.AcceptEula() }

	$UpdatesCollection.Add($Update) | out-null

	WriteLog  " + Downloading update $($Update.Title)"

	$UpdatesDownloader = $UpdateSession.CreateUpdateDownloader()

	$UpdatesDownloader.Updates = $UpdatesCollection

	$DownloadResult = $UpdatesDownloader.Download()

	$Message = " - Download {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)

	WriteLog  $message

	WriteLog  " - Installing Update"

	$UpdatesInstaller = $UpdateSession.CreateUpdateInstaller()

	$UpdatesInstaller.Updates = $UpdatesCollection

	$InstallResult = $UpdatesInstaller.Install()

	$Message = " - Install {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)

	WriteLog  $message

	$needsReboot = $True
	#$needsReboot = $installResult.rebootRequired

}

if($needsReboot) {
	WriteLog "Restarting computer"
	restart-computer
} else {
	RemoveAutologon
}

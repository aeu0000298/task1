cd "C:\Applications\Windows Kits\10\ADK"
Start-Process -FilePath adksetup.exe -ArgumentList "/s" -Wait

cd "C:\Applications\windows kits\10\ADKWinPEAddons"
Start-Process -FilePath adkwinpesetup.exe -ArgumentList "/s" -wait

cd "C:\Applications"
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"mdt.msi`" /quiet /norestart" -wait

$mdtInstallerPath = "C:\Applications\mdt.msi"
#Silent Install
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$mdtInstallerPath`" /quiet /norestart" -Wait

cd "C:\Users\Administrator"

New-Item -Path "C:\DeploymentShare" -ItemType directory
New-SmbShare -Name "DeploymentShare" -Path "C:\DeploymentShare" -FullAccess Administrators

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"

New-PSDrive -Name "DS002" -PSProvider "MDTProvider" -root "C:\DeploymentShare" -Description "MDT Deployment Share" -networkPath "\\Server\DeploymentShare" -Verbose | Add-MDTPersistentDrive -Verbose

Import-MDTOperatingSystem -Path "DS002:\Operating Systems" -SourcePath "C:\Windows 11" -DestinationFolder "Windows 11" -Verbose

Import-MDTApplication -Path "DS002:\Applications" -enable "True" -Name "Adobe reader 9" -ShortName "reader" -Version "9"  -Publisher "Adobe" -Language "English" -CommandLine "Reader.exe /sAll /rs /l" -WorkingDirectory ".\Applications\Adobe reader 9" -ApplicationSourcePath "C:\2022" -DestinationFolder "Adobe reader 9" -Verbose

Import-MDTTaskSequence -Path "DS002:\Task Sequences" -Name "Win11" -Template "Client.xml" -Comments "Deloying Win11" -ID "1" -Version "1.0" -OperatingSystemPath "DS002:\Operating Systems\Windows 11 Pro in Windows 11 install.wim" -FullName "Windows User" -OrgName "test" -Verbose

Remove-Item -Path "C:\DeploymentShare\Control\Bootstrap.ini" -Force
New-Item -Path "C:\DeploymentShare\Control\Bootstrap.ini" -ItemType File
Set-Content -Path "C:\DeploymentShare\Control\Bootstrap.ini" -Value (Get-Content "C:\Users\Administrator\Desktop\BootStrap.ini")

Remove-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Force
New-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -ItemType File
Set-Content -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Value (Get-Content "C:\Users\Administrator\Desktop\CustomSettings.ini")

$XMLfile = "C:\DeploymentShare\Control\Settings.xml"
[xml]$SettingsXML = Get-Content $XMLfile
$SettingsXML.Settings."SupportX86" = "Flase"
$SettingsXML.Save($XMLfile)

#Update the Deployment Share to create the boot wims and iso files
Update-MDTDeploymentShare -Path "DS002:" -Force -Verbose

Install-WindowsFeature -Name WDS -IncludeManagementTools

$WDSPath = 'C:\RemoteInstall'
wdsutil /Verbose /Progress /Initialize-Server /RemInst:$WDSPath
Start-Sleep -s 10
Write-Host "Attempting to start WDS..." -NoNewline
wdsutil /Verbose /Start-Server
Start-Sleep -s 10

wdsutil /set-Server /AnswerClients:All

Import-WdsBootImage -Path C:\DeploymentShare\Boot\LiteTouchPE_x64.wim -NewImageName "LiteTouchPE_x64" -SkipVerify


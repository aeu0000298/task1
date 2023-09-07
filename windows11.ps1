
New-Item -Path "C:\DeploymentShare" -ItemType directory
New-SmbShare -Name "DeploymentShare" -Path "C:\DeploymentShare" -FullAccess Administrators
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\DeploymentShare" -Description "MDT Deployment Share" -NetworkPath "\\Server-Jie\DeploymentShare" -Verbose | add-MDTPersistentDrive -Verbose


Import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "Adobe reader 9" -ShortName "reader" -Version "9" -Publisher "Adobe" -Language "English" -CommandLine "Reader.exe /sAll /rs /l" -WorkingDirectory ".\Applications\Adobe reader 9" -ApplicationSourcePath "C:\adobe" -DestinationFolder "Adobe reader 9" -Verbose
import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "VideoLan vlc 1" -ShortName "vlc" -Version "1" -Publisher "VideoLan" -Language "English" -CommandLine "vlc.exe /S /V /qn" -WorkingDirectory ".\Applications\VideoLan vlc 1" -ApplicationSourcePath "C:\vlc" -DestinationFolder "VideoLan vlc 1" -Verbose
import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "Google Chrome 1" -ShortName "Chrome" -Version "1" -Publisher "Google" -Language "English" -CommandLine "MsiExec.exe /i googlechromestandaloneenterprise64.msi /qn" -WorkingDirectory ".\Applications\Google Chrome 1" -ApplicationSourcePath "C:\google" -DestinationFolder "Google Chrome 1" -Verbose

import-mdtoperatingsystem -path "DS001:\Operating Systems" -SourcePath "C:\windows 11" -DestinationFolder "Windows 11" -Verbose

import-mdttasksequence -path "DS001:\Task Sequences" -Name "win11" -Template "Client.xml" -Comments "Deploying Windows 11" -ID "1" -Version "1.0" -OperatingSystemPath "DS001:\Operating Systems\Windows 11 Pro in Windows 11 install.wim" -FullName "Windows User" -OrgName "Aspire2" -HomePage "about:blank" -Verbose
$CSFile = @"
[Settings]
Priority=Model, Default
Properties=MyCustomProperty

[Default]
OSInstall=Y
SkipCapture=YES
SkipComputerBackup=YES
SkipAdminPassword=YES
SkipProductKey=YES
SkipDeploymentType=YES
SkipDomainMembership=YES
SkipUserData=YES
SkipBDDWelcome=YES
SkipComputerName=YES
SkipTaskSequence=YES
TaskSequenceID=1
SkipLocaleSelection=YES
UserLocale=en-US
KeyboardLocale=en-US
SkipTimeZone=YES
TimeZoneName=GMT Standard Time
SkipApplications=NO
SkipBitLocker=YES
SkipSummary=YES
EventServices=http://Deployment:9800
"@ 

# The closing part of the here-string needs to be the first characters on the line

Remove-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Force
New-Item -Path "C:\DeploymentShare\Control\CustomSettings.ini" -ItemType File
Set-Content -Path "C:\DeploymentShare\Control\CustomSettings.ini" -Value $CSFile



##############################################
# replace the standard bootstrap.ini with our own
# fill in the variables below with your chosen values
# you can even use local user/passwords on this server



$BSFile = @"
[Settings]
Priority=Default

[Default]
DeployRoot=\\Server-Jie\DeploymentShare
UserID=Administrator
UserPassword=Aeu0000298!@
UserDomain=jie.com
SkipBDDWelcome=YES
TaskSequenceID=1

"@ 

# The closing part of the here-string needs to be the first characters on the line

Remove-Item -Path "C:\DeploymentShare\Control\BootStrap.ini" -Force
New-Item -Path "C:\DeploymentShare\Control\BootStrap.ini" -ItemType File
Set-Content -Path "C:\DeploymentShare\Control\BootStrap.ini" -Value $BSFile

# Disable the X86 boot wim and change the Selection Profile for the X64 boot wim
$XMLFile = "C:\DeploymentShare\Control\Settings.xml"
            [xml]$SettingsXML = Get-Content $XMLFile
            $SettingsXML.Settings."SupportX86" = "False"
            $SettingsXML.Save($XMLFile)

#Update the Deployment Share to create the boot wims and iso files
update-MDTDeploymentShare -path "DS001:" -Force -Verbose

Install-WindowsFeature -Name WDS -IncludeManagementTools
#Installing WDS using powershell
$WDSPath = 'C:\RemoteInstall'
wdsutil /Verbose /Progress /Initialize-Server /RemInst:$WDSPath
Start-Sleep -s 10
Write-Host "Attempting to start WDS..." -NoNewline
wdsutil /Verbose /Start-Server
Start-Sleep -s 10
WDSUTIL /Set-Server /AnswerClients:All
Import-WdsBootImage -Path C:\DeploymentShare\Boot\LiteTouchPE_x64.wim -NewImageName "LiteTouchPE_x64" -SkipVerify

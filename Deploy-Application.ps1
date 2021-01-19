﻿<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'OIT'
	[string]$appName = 'Mandatory Restart'
	[string]$appVersion = ''
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = $appScriptDate
	[string]$appScriptDate = '2021.01.14'
	[string]$appScriptAuthor = 'Brandon Kessler and Rachel Catches-Ford'

	## Adds a Registry Key variable for SCCM Detection Method
	[string]$agency = 'OIT-CDHS'
	[string]$regPath = "$agency\$appVendor"
	## Close apps
	$closeApps = '' # seperate apps to close by commas. Needs to be the name of the .exe, without the extension
	[int]$Time = 2

	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''


	

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.2'
	[string]$deployAppScriptDate = '08/05/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>


		$OS = Get-wmiobject Win32_OperatingSystem
		$Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
		[int]$DaysUp = $Uptime.TotalDays
		$Days = 7

		if($DaysUp -gt $Days){
			Write-Warning "System has been up for $DaysUp."
			## Detect Logged on Users
			$LoggedOnUsers = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object {($_.UserName -ne $null) -and ($_.UserName -like "$Domain*")} | Sort-Object SessionId -Unique

			if(!($LoggedOnUsers)){
				Write-Warning "No users detected. Restarting Machine now."
				shutdown -r -t 900
			}
    		if(!(get-eventlog -LogName System -InstanceId 2147484722 -after (Get-date).addDays(-1))){
				Show-DialogBox -text "Your computer has been up for $DaysUp days. It needs to be restarted." -Icon Information -Timeout 900
				$Tomorrow = (Get-Date).AddDays(1).Date.AddHours($Time)
				shutdown -r -t ([decimal]::round(($Tomorrow - (Get-Date)).TotalSeconds))
				Show-InstallationRestartPrompt -CountDownSeconds ([decimal]::round(($Tomorrow - (Get-Date)).TotalSeconds))
			}elseif(get-eventlog -LogName System -InstanceId 2147484722 -after (Get-date).addDays(-1)){
				#Show-DialogBox -text "Your computer has been up for $DaysUp days. It needs to be restarted." -Icon Information -Timeout 900
				$Tomorrow = (Get-Date).AddDays(1).Date.AddHours($Time)
				#shutdown -r -t ([decimal]::round(($Tomorrow - (Get-Date)).TotalSeconds))
				Show-InstallationRestartPrompt -CountDownSeconds ([decimal]::round(($Tomorrow - (Get-Date)).TotalSeconds))
			}

		}

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

		## Create RegKey for software Detection


		## Display a message at the end of the install
		#If (-not $useDefaultMsi) { Show-InstallationPrompt -Message "$appName $appVersion was successfully installed. Please contact the OIT Servicedesk at 303-239-4357 for any further assistance." -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps "$closeApps" -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>


		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>


		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>

		if(!(Test-Path -Path "HKLM:\SOFTWARE\$regPath\$appName")){
			New-Item -Path "HKLM:\SOFTWARE\$regPath" -Name "$appName" -Force
		}
			
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "Status" -Value "$deploymentType"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "Version" -Value "$appVersion"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "AppCreated" -Value "$appScriptDate"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "DateStatusChange" -Value "$(Get-Date -Format yyyy.MM.dd)"


	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
		Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>
		## <Perform Post-Repair tasks here>

		if(!(Test-Path -Path "HKLM:\SOFTWARE\$regPath\$appName")){
			New-Item -Path "HKLM:\SOFTWARE\$regPath" -Name "$appName" -Force
		}
			
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "Status" -Value "$deploymentType"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "Version" -Value "$appVersion"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "AppCreated" -Value "$appScriptDate"
			Set-ItemProperty -Path "HKLM:\SOFTWARE\$regPath\$appName" -Name "DateStatusChange" -Value "$(Get-Date -Format yyyy.MM.dd)"


    }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}

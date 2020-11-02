
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Find installation directory for given predefined program name

.DESCRIPTION
Find-Installation is called by Test-Installation, ie. only if test for existing path
fails then this method kicks in

.PARAMETER Program
Predefined program name

.PARAMETER ComputerName
Computer name on which to look for program installation

.EXAMPLE
PS> Find-Installation "Office"

.INPUTS
None. You cannot pipe objects to Find-Installation

.OUTPUTS
[System.Boolean] true or false if installation directory if found, installation table is updated

.NOTES
None.
#>
function Find-Installation
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Find-Installation.md")]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Program,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	Initialize-Table

	# TODO: if it's program in user profile then how do we know it that applies to admins or users in rule?
	# TODO: need to check some of these search strings (cases), also remove hardcoded directories
	# NOTE: we want to preserve system environment variables for firewall GUI,
	# otherwise firewall GUI will show full paths which is not desired for sorting reasons
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Start searching for $Program"
	switch -Wildcard ($Program)
	{
		"dotnet"
		{
			# TODO: No algorithm to find this path
			Edit-Table "%ProgramFiles%\dotnet"
			break
		}
		"CMake"
		{
			Update-Table "CMake"
			break
		}
		"SQLDTS"
		{
			# $SQLServerBinnRoot = Get-SQLInstance | Select-Object -ExpandProperty SQLBinRoot
			$SQLDTSRoot = Get-SQLInstance | Select-Object -ExpandProperty SQLPath
			if ($SQLDTSRoot)
			{
				Edit-Table $SQLDTSRoot
			}
			break
		}
		"SQLManagementStudio"
		{
			$SQLManagementStudioRoot = Get-SQLManagementStudio |
			Select-Object -ExpandProperty InstallLocation

			if ($SQLManagementStudioRoot)
			{
				Edit-Table $SQLManagementStudioRoot
			}
			break
		}
		"WindowsDefender"
		{
			# NOTE: On fresh installed system the path may be wrong (to ProgramFiles)
			$DefenderRoot = Get-WindowsDefender $ComputerName |
			Select-Object -ExpandProperty InstallLocation

			if ($DefenderRoot)
			{
				Edit-Table $DefenderRoot
			}
			break
		}
		"NuGet"
		{
			# NOTE: ask user where he installed NuGet
			break
		}
		"NETFramework"
		{
			# Get latest NET Framework installation directory
			$NETFramework = Get-NetFramework $ComputerName
			if ($null -ne $NETFramework)
			{
				$NETFrameworkRoot = $NETFramework |
				Sort-Object -Property Version |
				Where-Object { $_.InstallLocation } |
				Select-Object -Last 1 -ExpandProperty InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] $NETFrameworkRoot"
				Edit-Table $NETFrameworkRoot
			}
			break
		}
		"vcpkg"
		{
			# NOTE: ask user where he installed vcpkg
			break
		}
		"SysInternals"
		{
			# NOTE: ask user where he installed SysInternals
			break
		}
		"WindowsKits"
		{
			# Get Windows SDK debuggers root (latest SDK)
			$WindowsKits = Get-WindowsKit $ComputerName
			if ($null -ne $WindowsKits)
			{
				$SDKDebuggers = $WindowsKits |
				Where-Object { $_.Product -like "WindowsDebuggersRoot*" } |
				Sort-Object -Property Product |
				Select-Object -Last 1 -ExpandProperty InstallLocation

				# TODO: Check other such cases where using the variable without knowing if
				# installation is available, this case here is fixed with if($SDKDebuggers)...
				if ($SDKDebuggers)
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] $SDKDebuggers"
					Edit-Table $SDKDebuggers
				}
			}
			break
		}
		"WebPlatform"
		{
			Edit-Table "%ProgramFiles%\Microsoft\Web Platform Installer"
			break
		}
		"XTU"
		{
			Edit-Table "%ProgramFiles(x86)%\Intel\Intel(R) Extreme Tuning Utility\Client"
			break
		}
		"Chocolatey"
		{
			Edit-Table "%ALLUSERSPROFILE%\chocolatey"
			break
		}
		"ArenaChess"
		{
			Update-Table "Arena Chess"
			break
		}
		"GoogleDrive"
		{
			Update-Table "Google Drive"
			break
		}
		"RivaTuner"
		{
			Update-Table "RivaTuner Statistics Server"
			break
		}
		"Incredibuild"
		{
			Update-Table "Incredibuild"
			break
		}
		"Metatrader"
		{
			Update-Table "InstaTrader"
			break
		}
		"RealWorld"
		{
			Edit-Table "%ProgramFiles(x86)%\RealWorld Cursor Editor"
			break
		}
		"qBittorrent"
		{
			Update-Table "qBittorrent"
			break
		}
		"OpenTTD"
		{
			Update-Table "OpenTTD"
			break
		}
		"EveOnline"
		{
			Update-Table "Eve Online"
			break
		}
		"DemiseOfNations"
		{
			Update-Table "Demise of Nations - Rome"
			break
		}
		"CounterStrikeGO"
		{
			Update-Table "Counter-Strike Global Offensive"
			break
		}
		"PinballArcade"
		{
			Update-Table "PinballArcade"
			break
		}
		"JavaPlugin"
		{
			# TODO: this is wrong, requires path search type
			Update-Table "Java\jre1.8.0_45\bin"
			break
		}
		"JavaUpdate"
		{
			Update-Table "Java Update"
			break
		}
		"JavaRuntime"
		{
			# TODO: this is wrong, requires path search type
			Update-Table "Java\jre7\bin"
			break
		}
		"AdobeARM"
		{
			# TODO: this is wrong, requires path search type
			Update-Table "Adobe\ARM"
			break
		}
		"AdobeAcrobat"
		{
			Update-Table "Acrobat Reader DC"
			break
		}
		"LoLGame"
		{
			Update-Table "League of Legends" -UserProfile
			break
		}
		"FileZilla"
		{
			Update-Table "FileZilla FTP Client"
			break
		}
		"PathOfExile"
		{
			Update-Table "Path of Exile"
			break
		}
		"HWMonitor"
		{
			Update-Table "HWMonitor"
			break
		}
		"CPU-Z"
		{
			Update-Table "CPU-Z"
			break
		}
		"MSIAfterburner"
		{
			Update-Table "MSI Afterburner"
			break
		}
		"GPG"
		{
			Update-Table "GNU Privacy Guard"
			break
		}
		"OBSStudio"
		{
			Update-Table "OBSStudio"
			break
		}
		"PasswordSafe"
		{
			Update-Table "Password Safe"
			break
		}
		"Greenshot"
		{
			Update-Table "Greenshot" -UserProfile
			break
		}
		"DnsCrypt"
		{
			Update-Table "Simple DNSCrypt"
			break
		}
		"OpenSSH"
		{
			Edit-Table "%ProgramFiles%\OpenSSH-Win64"
			break
		}
		"PowerShellCore64"
		{
			Update-Table "pwsh.exe" -Executable
			break
		}
		"PowerShell64"
		{
			Update-Table "PowerShell.exe" -Executable
			break
		}
		"PowerShell86"
		{
			Edit-Table "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
			break
		}
		"OneDrive"
		{
			# NOTE: this path didn't exist on fresh installed windows, but one drive was installed
			# It was in appdata user folder
			# Edit-Table "%ProgramFiles(x86)%\Microsoft OneDrive"

			Update-Table "OneDrive" -UserProfile
			break
		}
		"HelpViewer"
		{
			# TODO: is version number OK? no.
			Edit-Table "%ProgramFiles(x86)%\Microsoft Help Viewer\v2.3"
			break
		}
		"VSCode"
		{
			Update-Table "Visual Studio Code"
			break
		}
		"MicrosoftOffice"
		{
			# TODO: Returned path is missing \root\Office16
			# versions: https://en.wikipedia.org/wiki/History_of_Microsoft_Office
			# Update-Table "Microsoft Office"

			$OfficeRoot = Get-ExecutablePath | Where-Object -Property Name -EQ "Winword.exe" |
			Select-Object -ExpandProperty InstallLocation

			if ($OfficeRoot)
			{
				Edit-Table $OfficeRoot
			}
			break
		}
		"TeamViewer"
		{
			Update-Table "Team Viewer"
			break
		}
		"EdgeChromium"
		{
			# TODO: msedge.exe is found in executable paths, need to update search algorithm
			Update-Table "Microsoft Edge"
			break
		}
		"Chrome"
		{
			Update-Table "Google Chrome" -UserProfile
			break
		}
		"Firefox"
		{
			Update-Table "Firefox" -UserProfile
			break
		}
		"Yandex"
		{
			Update-Table "Yandex" -UserProfile
			break
		}
		"Tor"
		{
			# NOTE: ask user where he installed Tor because it doesn't include an installer
			break
		}
		"uTorrent"
		{
			Update-Table "uTorrent" -UserProfile
			break
		}
		"Thuderbird"
		{
			Update-Table "Thuderbird" -UserProfile
			break
		}
		"Steam"
		{
			Update-Table "Steam"
			break
		}
		"Nvidia64"
		{
			Edit-Table "%ProgramFiles%\NVIDIA Corporation"
			break
		}
		"Nvidia86"
		{
			Edit-Table "%ProgramFiles(x86)%\NVIDIA Corporation"
			break
		}
		"GeForceExperience"
		{
			# TODO: this is temporary measure, it should be handled with Test-File function
			# see also related todo in Nvidia.ps1
			# NOTE: calling script must not use this path, it is used only to check if installation
			# exists, the real path is obtained with "Nvidia" switch case
			Update-Table "GeForce Experience"
			break
		}
		"WarThunder"
		{
			Edit-Table "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"
			break
		}
		"PokerStars"
		{
			Update-Table "PokerStars"
			break
		}
		"VisualStudio"
		{
			# TODO: should we handle multiple instances and their names, also for other programs.
			# NOTE: VSSetup will return full path, no environment variables
			$VSRoot = Get-VSSetupInstance |
			Select-VSSetupInstance -Latest |
			Select-Object -ExpandProperty InstallationPath

			if ($VSRoot)
			{
				Edit-Table $VSRoot
			}
			break
		}
		"VisualStudioInstaller"
		{
			Update-Table "Visual Studio Installer"
			break
		}
		"MSYS2"
		{
			Update-Table "MSYS2" -UserProfile
			break
		}
		"Git"
		{
			Update-Table "Git"
			break
		}
		"GithubDesktop"
		{
			Update-Table "GitHub Desktop" -UserProfile
			break
		}
		"EpicGames"
		{
			Update-Table "Epic Games Launcher"
			break
		}
		"UnrealEngine"
		{
			# NOTE: game engine does not have installer, it is managed by launcher, and if it's
			# built from source user must enter path to engine manually
			$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles%\Epic Games")

			if (Test-Path $ExpandedPath)
			{
				$VersionFolders = Get-ChildItem -Directory -Path $ExpandedPath -Name

				foreach ($VersionFolder in $VersionFolders)
				{
					Edit-Table "$ExpandedPath\$VersionFolder\Engine"
				}
			}

			break
		}
		default
		{
			Write-Warning -Message "Parameter '$Program' not recognized"
		}
	}

	if ($InstallTable.Rows.Count -gt 0)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation for $Program found"
		return $true
	}
	else
	{
		Write-Warning -Message "Installation directory for '$Program' not found"

		# NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
		$Script = (Get-PSCallStack)[2].Command

		# TODO: these loops seem to be skipped, probably missing Test-File, need to check
		Write-Information -Tags "User" -MessageData "INFO: If you installed $Program elsewhere you can input the correct path now"
		Write-Information -Tags "User" -MessageData "INFO: or adjust the path in $Script and re-run the script later."
		Write-Information -Tags "User" -MessageData "INFO: otherwise ignore this warning if $Program is not installed."

		if (Approve-Execute "Yes" "Rule group for $Program" "Do you want to input path now?")
		{
			while ($InstallTable.Rows.Count -eq 0)
			{
				[string] $InstallLocation = Read-Host "Input path to '$Program' root directory"

				if (![string]::IsNullOrEmpty($InstallLocation))
				{
					Edit-Table $InstallLocation

					if ($InstallTable.Rows.Count -gt 0)
					{
						return $true
					}
				}

				Write-Warning -Message "Installation directory for '$Program' not found"
				if (Approve-Execute "No" "Unable to locate '$InstallLocation'" "Do you want to try again?")
				{
					break
				}
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] User skips input for $Program"

		# Finally status is bad
		Set-Variable -Name WarningStatus -Scope Global -Value $true
		return $false
	}
}

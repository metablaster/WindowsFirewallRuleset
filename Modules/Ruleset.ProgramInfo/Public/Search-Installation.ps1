
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Search-Installation is called by Confirm-Installation, ie. only if test for existing path
fails then this method kicks in

.PARAMETER Application
Predefined program name

.PARAMETER Domain
Computer name on which to look for program installation

.EXAMPLE
PS> Search-Installation "Office"

.EXAMPLE
PS> Search-Installation "VSCode" -Domain Server01

.INPUTS
None. You cannot pipe objects to Search-Installation

.OUTPUTS
[bool] true or false if installation directory if found, installation table is updated

.NOTES
None.
#>
function Search-Installation
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Search-Installation.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("Program")]
		[TargetProgram] $Application,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	Initialize-Table

	# TODO: if it's program in user profile then how do we know it that applies to admins or users in rule?
	# TODO: need to check some of these search strings (cases), also remove hardcoded directories
	# NOTE: we want to preserve system environment variables for firewall GUI,
	# otherwise firewall GUI will show full paths which is not desired for sorting reasons
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Start searching for $Application"

	switch ($Application)
	{
		"dotnet"
		{
			# TODO: No algorithm to find this path
			Edit-Table "%ProgramFiles%\dotnet"
			break
		}
		"CMake"
		{
			Update-Table -Search "CMake"
			break
		}
		"SQLDTS"
		{
			# $SQLServerBinnRoot = Get-SqlServerInstance | Select-Object -ExpandProperty SQLBinRoot
			$SQLDTSRoot = Get-SqlServerInstance | Select-Object -ExpandProperty SQLPath
			if ($SQLDTSRoot)
			{
				Edit-Table $SQLDTSRoot
			}
			break
		}
		"SqlManagementStudio"
		{
			$SqlManagementStudioRoot = Get-SqlManagementStudio |
			Select-Object -ExpandProperty InstallLocation

			if ($SqlManagementStudioRoot)
			{
				Edit-Table $SqlManagementStudioRoot
			}
			break
		}
		"WindowsDefender"
		{
			# NOTE: On fresh installed system the path may be wrong (to ProgramFiles)
			$DefenderRoot = Get-WindowsDefender $Domain |
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
			$NETFramework = Get-NetFramework $Domain
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
			$WindowsKits = Get-WindowsKit $Domain
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
			Update-Table -Search "Arena Chess"
			break
		}
		"GoogleDrive"
		{
			Update-Table -Search "Google Drive"
			break
		}
		"RivaTuner"
		{
			Update-Table -Search "RivaTuner Statistics Server"
			break
		}
		"Incredibuild"
		{
			Update-Table -Search "Incredibuild"
			break
		}
		"MetaTrader"
		{
			Update-Table -Search "InstaTrader"
			break
		}
		"RealWorld"
		{
			Edit-Table "%ProgramFiles(x86)%\RealWorld Cursor Editor"
			break
		}
		"qBittorrent"
		{
			Update-Table -Search "qBittorrent"
			break
		}
		"OpenTTD"
		{
			Update-Table -Search "OpenTTD"
			break
		}
		"EveOnline"
		{
			Update-Table -Search "Eve Online"
			break
		}
		"DemiseOfNations"
		{
			Update-Table -Search "Demise of Nations - Rome"
			break
		}
		"CounterStrikeGO"
		{
			Update-Table -Search "Counter-Strike Global Offensive"
			break
		}
		"PinballArcade"
		{
			Update-Table -Search "PinballArcade"
			break
		}
		"JavaUpdate"
		{
			Edit-Table "%ProgramFiles(x86)%\Common Files\Java\Java Update"
			break
		}
		"JavaRuntime"
		{
			# TODO: This depends on x64 or x86 installation for plugin
			Update-Table -Search "Java"
			break
		}
		"AdobeARM"
		{
			Edit-Table "%SystemDrive%\Program Files (x86)\Common Files\Adobe\ARM\1.0"
			break
		}
		"AdobeReader"
		{
			# Adobe Acrobat Reader DC
			Update-Table -Search "Acrobat Reader"
			break
		}
		"AdobeAcrobat"
		{
			# Adobe Acrobat DC
			Update-Table -Search "Adobe Acrobat DC"
			break
		}
		"LoLGame"
		{
			Update-Table -Search "League of Legends" -UserProfile
			break
		}
		"FileZilla"
		{
			Update-Table -Search "FileZilla FTP Client"
			break
		}
		"PathOfExile"
		{
			Update-Table -Search "Path of Exile"
			break
		}
		"HWMonitor"
		{
			Update-Table -Search "HWMonitor"
			break
		}
		"CPUZ"
		{
			Update-Table -Search "CPU-Z"
			break
		}
		"MSIAfterburner"
		{
			Update-Table -Search "MSI Afterburner"
			break
		}
		"GPG"
		{
			Update-Table -Search "GNU Privacy Guard"
			break
		}
		"OBSStudio"
		{
			Update-Table -Search "OBSStudio"
			break
		}
		"PasswordSafe"
		{
			Update-Table -Search "Password Safe"
			break
		}
		"Greenshot"
		{
			Update-Table -Search "Greenshot" -UserProfile
			break
		}
		"DnsCrypt"
		{
			Update-Table -Search "Simple DNSCrypt"
			break
		}
		"OpenSSH"
		{
			Edit-Table "%ProgramFiles%\OpenSSH-Win64"
			break
		}
		"PowerShellCore64"
		{
			Update-Table -Executable "pwsh.exe"
			break
		}
		"PowerShell64"
		{
			Update-Table -Executable "PowerShell.exe"
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

			Update-Table -Search "OneDrive" -UserProfile
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
			Update-Table -Search "Visual Studio Code"
			break
		}
		"MicrosoftOffice"
		{
			# TODO: Returned path is missing \root\Office16
			# versions: https://en.wikipedia.org/wiki/History_of_Microsoft_Office
			# Update-Table -Search "Microsoft Office"

			$OfficeRoot = $ExecutablePaths | Where-Object -Property Name -EQ "Winword.exe" |
			Select-Object -ExpandProperty InstallLocation

			if ($OfficeRoot)
			{
				Edit-Table $OfficeRoot
			}
			break
		}
		"TeamViewer"
		{
			Update-Table -Search "Team Viewer"
			break
		}
		"EdgeChromium"
		{
			Update-Table -Search "Microsoft Edge" -Executable "msedge.exe"
			break
		}
		"Chrome"
		{
			Update-Table -Search "Google Chrome" -UserProfile
			break
		}
		"Firefox"
		{
			Update-Table -Search "Firefox" -UserProfile
			break
		}
		"Yandex"
		{
			Update-Table -Search "Yandex" -UserProfile
			break
		}
		"Tor"
		{
			# NOTE: ask user where he installed Tor because it doesn't include an installer
			break
		}
		"uTorrent"
		{
			Update-Table -Search "uTorrent" -UserProfile
			break
		}
		"Thuderbird"
		{
			Update-Table -Search "Thuderbird" -UserProfile
			break
		}
		"Steam"
		{
			Update-Table -Search "Steam"
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
			# TODO: this is temporary measure, it should be handled with Test-ExecutableFile function
			# see also related todo in Nvidia.ps1
			# NOTE: calling script must not use this path, it is used only to check if installation
			# exists, the real path is obtained with "Nvidia" switch case
			Update-Table -Search "GeForce Experience"
			break
		}
		"WarThunder"
		{
			Edit-Table "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"
			break
		}
		"PokerStars"
		{
			Update-Table -Search "PokerStars"
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
			Update-Table -Search "Visual Studio Installer"
			break
		}
		"MSYS2"
		{
			Update-Table -Search "MSYS2" -UserProfile
			break
		}
		"Git"
		{
			Update-Table -Search "Git"
			break
		}
		"GitHubDesktop"
		{
			Update-Table -Search "GitHub Desktop" -UserProfile
			break
		}
		"EpicGames"
		{
			Update-Table -Search "Epic Games Launcher"
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
		"BingWallpaper"
		{
			Edit-Table "%SystemDrive%\Users\$DefaultUser\AppData\Local\Microsoft\BingWallpaperApp"
			break
		}
		default
		{
			Write-Error -Category ObjectNotFound -TargetObject $Application -Message "Parameter '$Application' not implemented"
		}
	}

	if ($InstallTable.Rows.Count -gt 0)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation for $Application found"
		return $true
	}
	else
	{
		Write-Warning -Message "Installation directory for '$Application' not found"

		# NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
		$Script = (Get-PSCallStack)[2].Command

		# TODO: these loops seem to be skipped, probably missing Test-ExecutableFile, need to check
		Write-Information -Tags "User" -MessageData "INFO: If you installed $Application elsewhere you can input valid path now"
		Write-Information -Tags "User" -MessageData "INFO: Alternatively adjust path in $Script and re-run the script later"

		$Accept = "Provide full path to '$Application' installation directory"
		$Deny = "Skip operation, rules for '$Application' won't be loaded into firewall"

		if (Approve-Execute -Accept $Accept -Deny $Deny -Title "Rule group for $Application" -Question "Do you want to input path now?")
		{
			$Accept = "Try again, required path may be deeper or shallower into/from root directory for '$Application'"
			$Deny = "Stop asking for '$Application' and continue"

			while ($InstallTable.Rows.Count -eq 0)
			{
				[string] $InstallLocation = Read-Host "Please input path to '$Application' root directory"

				if (![string]::IsNullOrEmpty($InstallLocation))
				{
					Edit-Table $InstallLocation

					if ($InstallTable.Rows.Count -gt 0)
					{
						return $true
					}
				}

				Write-Warning -Message "Installation directory for '$Application' not found"
				if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Title "Unable to locate '$InstallLocation'" -Question "Do you want to try again?"))
				{
					break
				}
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] User skips input for $Application"

		# Finally status is bad
		Set-Variable -Name WarningStatus -Scope Global -Value $true
		return $false
	}
}

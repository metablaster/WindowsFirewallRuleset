
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Computer name on which to search for program installations

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER CimSession
Specifies the CIM session to use

.PARAMETER Interactive
If requested program installation directory is not found, Search-Installation will ask
user to specify program installation location

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if default program
installation directory path does not exist or if it's of an invalid syntax needed for firewall.
Same applies for program path (if found) specified by -Application parameter.

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
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Search-Installation.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("Program")]
		[TargetProgram] $Application,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(Mandatory = $true, ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter(Mandatory = $true, ParameterSetName = "Session")]
		[CimSession] $CimSession,

		[Parameter()]
		[switch] $Interactive,

		[Parameter()]
		[switch] $Quiet
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($PsCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session

		$PSDefaultParameterValues["Edit-Table:Session"] = $Session
		$PSDefaultParameterValues["Edit-Table:CimSession"] = $CimSession
		$PSDefaultParameterValues["Update-Table:CimSession"] = $CimSession
	}
	else
	{
		$SessionParams.ComputerName = $Domain
		$PSDefaultParameterValues["Edit-Table:Domain"] = $Domain
		$PSDefaultParameterValues["Update-Table:Domain"] = $Domain

		if ($Credential)
		{
			$SessionParams.Credential = $Credential
			$PSDefaultParameterValues["Edit-Table:Credential"] = $Credential
		}
	}

	Initialize-Table
	$MachineName = Format-ComputerName $Domain
	$PSDefaultParameterValues["Edit-Table:Quiet"] = $Quiet

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
		"SqlPath"
		{
			# TODO: Once returning a table is implemented, SQL search should get both SQLPath and InstallLocation directories
			# $SQLServerBinnRoot = Get-SqlServerInstance | Select-Object -ExpandProperty SQLBinRoot
			$SqlPathRoot = Get-SqlServerInstance $Domain | Select-Object -ExpandProperty SqlPath
			if ($SqlPathRoot)
			{
				Edit-Table $SqlPathRoot
			}
			break
		}
		"SqlServer"
		{
			$SqlServerRoot = Get-SqlServerInstance $Domain | Select-Object -ExpandProperty InstallLocation
			if ($SqlServerRoot)
			{
				Edit-Table $SqlServerRoot
			}
			break
		}
		"SqlManagementStudio"
		{
			$SqlManagementStudioRoot = Get-SqlManagementStudio $Domain |
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
			# NOTE: ask user for standalone installation directory of NuGet
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
			# NOTE: ask user for standalone installation directory of vcpkg
			break
		}
		"SysInternals"
		{
			# NOTE: ask user for standalone installation directory of SysInternals
			break
		}
		"Psiphon"
		{
			Edit-Table "%SystemDrive%\Users\$DefaultUser\AppData\Local\Temp"
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
			Edit-Table "%ProgramFiles%\Intel\Intel(R) Extreme Tuning Utility\Client"
			break
		}
		"Chocolatey"
		{
			Edit-Table "%ALLUSERSPROFILE%\chocolatey"
			break
		}
		"AzureDataStudio"
		{
			Edit-Table -Search "Azure Data Studio"
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
		"ColorMania"
		{
			Update-Table -Search "ColorMania"
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
		"EdgeWebView"
		{
			Update-Table -Search "Microsoft Edge WebView"

			if ($InstallTable.Rows.Count -eq 1)
			{
				$InstallLocation = $InstallTable | Select-Object -ExpandProperty InstallLocation
				$VersionFolders = Invoke-Command @SessionParams -ScriptBlock {
					Get-ChildItem -Directory -Path ([System.Environment]::ExpandEnvironmentVariables($using:InstallLocation)) |
					Where-Object {
						$_.BaseName -match "^\d+\."
					}
				}

				$VersionFoldersCount = ($VersionFolders | Measure-Object).Count
				if ($VersionFoldersCount -gt 0)
				{
					$VersionFolder = $VersionFolders | Sort-Object | Select-Object -Last 1
					Initialize-Table
					Edit-Table "$InstallLocation\$($VersionFolder.BaseName)"
				}
			}

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
		"MSI"
		{
			Edit-Table "%ProgramFiles(x86)%\MSI"
			break
		}
		"GPG"
		{
			Update-Table -Search "GNU Privacy Guard"
			break
		}
		"OBSStudio"
		{
			Update-Table -Search "OBS Studio"
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

			if ($MachineName -ne $script:LastPolicyStore)
			{
				# If domain changed, need to update script cache
				$script:ExecutablePaths = Get-ExecutablePath -Domain $Domain
			}

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
			# NOTE: ask user for standalone installation directory of Tor
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
				$VersionFolders = Invoke-Command @SessionParams -ScriptBlock {
					Get-ChildItem -Directory -Path $using:ExpandedPath -Name
				}

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
			if (!$Quiet)
			{
				Write-Error -Category ObjectNotFound -TargetObject $Application -Message "Parameter '$Application' not implemented"
			}
		}
	}

	if ($InstallTable.Rows.Count -gt 0)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation for $Application found"
		return $true
	}
	else
	{
		if (!$Quiet)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Installation directory for '$Application' not found"
		}

		if ($Interactive)
		{
			# NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
			$Script = (Get-PSCallStack)[2].Command

			# TODO: these loops seem to be skipped, probably missing Test-ExecutableFile, need to check
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: If you installed $Application elsewhere you can input valid path now"

			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Alternatively adjust path in $Script and re-run the script later"

			# TODO: If path is specified with quotes it's not found, but Format-Path in Edit-Table should handle this
			$Accept = "Provide full path to '$Application' installation directory without quotes"
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

					Write-Warning -Message "[$($MyInvocation.InvocationName)] Installation directory for '$Application' not found"
					if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Title "Unable to locate '$InstallLocation'" -Question "Do you want to try again?"))
					{
						break
					}
				}
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] User skips input for $Application"
		}

		# Finally status is bad
		Set-Variable -Name WarningStatus -Scope Global -Value $true
		return $false
	}
}

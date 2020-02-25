
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

Set-StrictMode -Version Latest

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	$ThisModule = $MyInvocation.MyCommand.Name -replace ".{5}$"

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

# Includes
. $PSScriptRoot\External\Get-SQLInstances.ps1
Import-Module -Name $PSScriptRoot\..\VSSetup
Import-Module -Name $PSScriptRoot\..\Project.Windows.UserInfo
# Import-Module -Name $PSScriptRoot\..\Project.Windows.ComputerInfo
Import-Module -Name $PSScriptRoot\..\Project.AllPlatforms.Utility

<#
.SYNOPSIS
get store app SID
.PARAMETER UserName
Username for which to query app SID
.PARAMETER AppName
"PackageFamilyName" string
.EXAMPLE
sample: Get-AppSID "User" "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
.INPUTS
None. You cannot pipe objects to Get-AppSID
.OUTPUTS
System.String store app SID (security identifier)
.NOTES
TODO: Test if path exists
TODO: remote computers?
#>
function Get-AppSID
{
	[CmdletBinding()]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true)]
		[string] $UserName,

		[Parameter(Mandatory = $true)]
		[string] $AppName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing app: $AppName"

	$TargetPath = "C:\Users\$UserName\AppData\Local\Packages\$AppName\AC"
	if (Test-Path -PathType Container -Path $TargetPath)
	{
		$ACL = Get-ACL $TargetPath
		$ACE = $ACL.Access.IdentityReference.Value

		foreach ($Entry in $ACE)
		{
			# NOTE: avoid spaming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing: $Entry"

			# package SID starts with S-1-15-2-
			if ($Entry -match "S-1-15-2-") {
				return $Entry
			}
		}
	}
	else
	{
		Write-Warning -Message "Store app '$AppName' is not isnstalled by user '$UserName' or the app is missing"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem let this user update all of it's apps in Windows store"
	}
}

<#
.SYNOPSIS
check if file such as an *.exe exists
.PARAMETER FilePath
path to file
.EXAMPLE
Test-File "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
.INPUTS
None. You cannot pipe objects to Test-File
.OUTPUTS
warning message if file not found
.NOTES
We should attempt to fix the path if invlid here!
#>
function Test-File
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking: $ExpandedPath"

	if (!([System.IO.File]::Exists($ExpandedPath)))
	{
		# NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
		$Script = (Get-PSCallStack)[1].Command
		$SearchPath = Split-Path -Path $ExpandedPath -Parent
		$Executable = Split-Path -Path $ExpandedPath -Leaf

		Write-Warning -Message "Executable '$Executable' was not found, rules for '$Executable' won't have any effect"

		Write-Information -Tags "User" -MessageData "INFO: Searched path was: $SearchPath"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem find '$Executable' then adjust the path in $Script and re-run the script later again"
	}
}

<#
.SYNOPSIS
Same as Test-Path but expands system environment variables, and checks if compatible path
.PARAMETER FilePath
Path to folder, Allow null or empty since input may come from other commandlets which can return empty or null
.EXAMPLE
Test-Evnironment %SystemDrive%
.INPUTS
None. You cannot pipe objects to Test-Environment
.OUTPUTS
$true if path exists, false otherwise
#>
function Test-Environment
{
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $FilePath = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if path is valid for firewall rule"

	if ([System.String]::IsNullOrEmpty($FilePath))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $false
	}

	if ([array]::Find($UserProfileEnvironment, [System.Predicate[string]]{ $FilePath -like "$($args[0])*" }))
	{
		Write-Warning -Message "Rules with environment variable paths that lead to user profile are not valid"
		Write-Information -Tags "Project" -MessageData "INFO: Bad path detected is: $FilePath"
		return $false
	}

	return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)))
}

<#
.SYNOPSIS
check if service exists on system
.PARAMETER Service
service name (not display name)
.EXAMPLE
Test-Service dnscache
.INPUTS
None. You cannot pipe objects to Test-Service
.OUTPUTS
warning and info message if service not found
#>
function Test-Service
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Service
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if rules point to valid system services"

	if (!(Get-Service -Name $Service -ErrorAction Ignore))
	{
		Write-Warning -Message "Service '$Service' not found, rule won't have any effect"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem update or comment out all firewall rules for '$Service' service"
	}
}

<#
.SYNOPSIS
Check if input path leads to user profile
.PARAMETER FilePath
File path to check, can be unformatted or have environment variables
.EXAMPLE
Test-UserProfile "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
.INPUTS
None. You cannot pipe objects to Test-UserProfile
.OUTPUTS
$true or $false
.NOTES
TODO: is it possible to nest this into Test-Environment somehow?
#>
function Test-UserProfile
{
	[CmdletBinding()]
	param (
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Impssible to know what the imput may be
	if ([System.String]::IsNullOrEmpty($FilePath))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $false
	}

	# Make an array of (environment variable/path) value pair,
	# user profile environment variables only
	$Variables = @()
	foreach ($Entry in @(Get-ChildItem Env:))
	{
		$Entry.Name = "%" + $Entry.Name + "%"
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

		if ($UserProfileEnvironment -contains $Entry.Name)
		{
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting $($Entry.Name)"
			$Variables += $Entry
		}
	}

	# TODO: sorted result will have multiple same variables,
	# Sorting from longest paths which should be checked first
	$Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

	# Strip away quotations from path
	$FilePath = $FilePath.Trim('"')
	$FilePath = $FilePath.Trim("'")

	# Replace double slasses with single ones
	$FilePath = $FilePath.Replace("\\", "\")

	# If input path is root drive, removing a slash would produce bad path
	# Otherwise remove trailing slahs for cases where entry path is convertible to variable
	if ($FilePath.Length -gt 3)
	{
		$FilePath = $FilePath.TrimEnd('\\')
	}

	# Make a copy of file path because modification can be wrong
	$SearchString = $FilePath

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$FilePath' already contains user profile environment variable"
	foreach ($Variable in $Variables)
	{
		if ($FilePath -like "$($Variable.Name)*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path leads to user profile"
			return $true
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to user profile environment variable"
	while (![System.String]::IsNullOrEmpty($SearchString))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing: $SearchString"

		foreach ($Entry in $Variables)
		{
			if ($Entry.Value -like "*$SearchString")
			{
				# Environment variable found, if this is first hit, trailing slash is already removed
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path leads to user profile"
				return $true
			}
		}

		# Strip away file or last folder in path then try again (also trims trailing slash)
		$SearchString = Split-Path -Path $SearchString -Parent
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] input path does not lead to user profile"
	return $false
}

<#
.SYNOPSIS
format path into firewall compatible path
.PARAMETER FilePath
File path to check, can be unformatted or have environment variables
.EXAMPLE
Format-Path "C:\Program Files\\Dir\"
.INPUTS
None. You cannot pipe objects to Format-Path
.OUTPUTS
System.String formatted path, includes environment variables, stripped off of junk
#>
function Format-Path
{
	[CmdletBinding()]
	param (
		[string] $FilePath
	)

	# Impssible to know what the imput may be
	if ([System.String]::IsNullOrEmpty($FilePath))
	{
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $FilePath
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Make an array of (environment variable/path) value pair,
	# excluding user profile environment variables
	$Variables = @()
	foreach ($Entry in @(Get-ChildItem Env:))
	{
		$Entry.Name = "%" + $Entry.Name + "%"
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

		if ($BlackListEnvironment -notcontains $Entry.Name)
		{
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting $($Entry.Name)"
			$Variables += $Entry
		}
	}

	# TODO: sorted result will have multiple same variables,
	# Sorting from longest paths which should be checked first
	$Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

	# Strip away quotations from path
	$FilePath = $FilePath.Trim('"')
	$FilePath = $FilePath.Trim("'")

	# Some paths may have semicollon (ie. command paths)
	$FilePath = $FilePath.TrimEnd(";")

	# Replace double slasses with single ones
	$FilePath = $FilePath.Replace("\\", "\")

	# If input path is root drive, removing a slash would produce bad path
	# Otherwise remove trailing slahs for cases where entry path is convertible to variable
	if ($FilePath.Length -gt 3)
	{
		$FilePath = $FilePath.TrimEnd('\\')
	}

	# Make a copy of file path because modification can be wrong
	$SearchString = $FilePath

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$FilePath' already contains environment variable"
	foreach ($Variable in $Variables)
	{
		if ($FilePath -like "$($Variable.Name)*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path already formatted"
			return $FilePath
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to environment variable"
	while (![System.String]::IsNullOrEmpty($SearchString))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing: $SearchString"

		foreach ($Entry in $Variables)
		{
			if ($Entry.Value -like "*$SearchString")
			{
				# Environment variable found, if this is first hit, trailing slash is already removed
				$FilePath = $FilePath.Replace($SearchString, $Entry.Name)
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Formatting input path to: $FilePath"
				return $FilePath
			}
		}

		# Strip away file or last folder in path then try again (also trims trailing slash)
		$SearchString = Split-Path -Path $SearchString -Parent
	}

	# path has been reduced to root drive so get that
	$SearchString = Split-Path -Path $FilePath -Qualifier

	# Find candidate replacements
	$Variables = $Variables | Where-Object { $_.Value -eq $SearchString}

	if ([System.String]::IsNullOrEmpty($Variables))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Environment variables for input path don't exist"
		# There are no environment variables for this drive
		# Just trim trailing slash
		return $FilePath.TrimEnd('\\')
	}

	# Since there may be duplicate entries, we grab first one
	$Replacement = $Variables.Name[0]

	# Only root drive is converted, just trim away trailing slash
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Only root drive is converted to environment variable"
	return $FilePath.Replace($SearchString, $Replacement).TrimEnd('\\')
}

<#
.SYNOPSIS
search installed programs in userprofile for specifit user account
.PARAMETER UserAccount
User account in form of "COMPUTERNAME\USERNAME"
.EXAMPLE
Get-UserPrograms "COMPUTERNAME\USERNAME"
.INPUTS
None. You cannot pipe objects to Get-UserPrograms
.OUTPUTS
System.Management.Automation.PSCustomObject list of programs for specified account if form of COMPUTERNAME\USERNAME
#>
function Get-UserPrograms
{
	[CmdletBinding()]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true)]
		[string] $UserName,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		$HKU = Get-AccountSID $UserName -Machine $ComputerName
		$HKU += "\Software\Microsoft\Windows\CurrentVersion\Uninstall"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
		$UserKey = $RemoteKey.OpenSubkey($HKU)

		$UserPrograms = @()
		if (!$UserKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKU:$HKU"
		}
		else
		{
			foreach ($HKUSubKey in $UserKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKUSubKey"
				$SubKey = $UserKey.OpenSubkey($HKUSubKey)

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub Key: $HKUSubKey"
					continue
				}

				$InstallLocation = $SubKey.GetValue("InstallLocation")

				if ([System.String]::IsNullOrEmpty($InstallLocation))
				{
					Write-Warning -Message "Failed to read registry entry $HKUSubKey\InstallLocation"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKUSubKey"

				# TODO: move all instances to directly format (first call above)
				# NOTE: Avoid spamming
				$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

				# Get more key entries as needed
				# TODO: PSObject to psobject?
				$UserPrograms += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $HKUSubKey
					"Name" = $SubKey.GetValue("displayname")
					"InstallLocation" = $InstallLocation
				}
			}
		}

		return $UserPrograms
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
search installed programs for all users, system wide
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-SystemPrograms "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-SystemPrograms
.OUTPUTS
System.Management.Automation.PSCustomObject list of programs installed for all users
#>
function Get-SystemPrograms
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
				"SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
			)
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		$SystemPrograms = @()
		foreach ($HKLMRootKey in $HKLM)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLMRootKey"
			$RootKey = $RemoteKey.OpenSubkey($HKLMRootKey)

			if (!$RootKey)
			{
				Write-Warning -Message "Failed to open registry root key: HKLM:$HKLMRootKey"
				continue
			}

			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				# NOTE: Avoid spamming
				# Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey);

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub Key: $HKLMSubKey"
					continue
				}

				# First we get InstallLocation by normal means
				# Strip away quotations and ending backslash
				$InstallLocation = $SubKey.GetValue("InstallLocation")

				# NOTE: Avoid spamming
				$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

				if ([System.String]::IsNullOrEmpty($InstallLocation))
				{
					# Some programs do not install InstallLocation entry
					# so let's take a look at DisplayIcon which is the path to executable
					# then strip off all of the junk to get clean and relevant directory output
					$InstallLocation = $SubKey.GetValue("DisplayIcon")

					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

					# regex to remove: \whatever.exe at the end
					$InstallLocation = $InstallLocation -Replace "\\(?:.(?!\\))+exe$", ""
					# once exe is removed, remove unistall folder too if needed
					#$InstallLocation = $InstallLocation -Replace "\\uninstall$", ""

					if ([System.String]::IsNullOrEmpty($InstallLocation) -or
					$InstallLocation -like "*{*}*" -or
					$InstallLocation -like "*.exe*")
					{
						# NOTE: Avoid spamming
						# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key: $HKLMSubKey"
						continue
					}
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

				# Get more key entries as needed
				$SystemPrograms += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Name" = $SubKey.GetValue("DisplayName")
					"InstallLocation" = $InstallLocation
				}
			}
		}

		return $SystemPrograms
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
search program install properties for all users
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-AllUserPrograms "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-AllUserPrograms
.OUTPUTS
System.Management.Automation.PSCustomObject list of programs installed for all users
#>
function Get-AllUserPrograms
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	# TODO: if else here not at the end
	if (Test-TargetComputer $ComputerName)
	{
		# TODO: this key may not exist on fresh installed systems, tested in fresh installed Windows Server 2019
		$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		$AllUserPrograms = @()
		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($HKLSubMKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLSubMKey\Products"
				$UserProducts = $RootKey.OpenSubkey("$HKLSubMKey\Products")

				if (!$UserProducts)
				{
					Write-Warning -Message "Failed to open UserKey: $HKLSubMKey\Products"
					continue
				}

				foreach ($HKLMKey in $UserProducts.GetSubKeyNames())
				{
					# NOTE: Avoid spamming
					# Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMKey\InstallProperties"
					$ProductKey = $UserProducts.OpenSubkey("$HKLMKey\InstallProperties")

					if (!$ProductKey)
					{
						Write-Warning -Message "Failed to open ProductKey: $HKLMKey\InstallProperties"
						continue
					}

					$InstallLocation = $ProductKey.GetValue("InstallLocation")

					if ([System.String]::IsNullOrEmpty($InstallLocation))
					{
						# NOTE: Avoid spamming
						# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key: $HKLMKey\InstallProperties"
						continue
					}

					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMKey\InstallProperties"

					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

					# TODO: generate Principal entry in all registry functions
					# Get more key entries as needed
					$AllUserPrograms += New-Object -TypeName PSObject -Property @{
						"ComputerName" = $ComputerName
						"RegKey" = $HKLMKey
						"SIDKey" = $HKLSubMKey
						"Name" = $ProductKey.GetValue("DisplayName")
						"Version" = $ProductKey.GetValue("DisplayVersion")
						"InstallLocation" = $InstallLocation
					}
				}
			}

			return $AllUserPrograms
		}
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get list of install locations for executables and executable names
.DESCRIPTION
Returs a table of installed programs, with exectuable name, installation path,
registry path and child registry key name for target computer
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-AppPaths "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-SystemPrograms
.OUTPUTS
System.Management.Automation.PSCustomObject list of executables and their installation path
.NOTES
TODO: we are using OUTPUTS to describe something that isn't really an output.
#>
function Get-ExecutablePaths
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
				# NOTE: It looks like this key is exact duplicate, not used
				# even if there are both 32 and 64 bit, 32 bit applications on 64 bit system the path will point to 64 bit application
				# "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths"
			)
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		$AppPaths = @()
		foreach ($HKLMRootKey in $HKLM)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLMRootKey"
			$RootKey = $RemoteKey.OpenSubkey($HKLMRootKey)

			if (!$RootKey)
			{
				Write-Warning -Message "Failed to open registry root key: HKLM:$HKLMRootKey"
				continue
			}

			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey);

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub Key: $HKLMSubKey"
					continue
				}

				# Default key can be empty
				[string] $FilePath = $SubKey.GetValue("")
				if (![string]::IsNullOrEmpty($FilePath))
				{
					# Strip away quotations from path
					$FilePath = $FilePath.Trim('"')
					$FilePath = $FilePath.Trim("'")

					# Replace double slasses with single ones
					$FilePath = $FilePath.Replace("\\", "\")

					# Get only executable name
					$Executable = Split-Path -Path $FilePath -Leaf
				}

				# Path can be empty
				$InstallLocation = $SubKey.GetValue("Path")
				if (![string]::IsNullOrEmpty($InstallLocation))
				{
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false
				}
				elseif (![string]::IsNullOrEmpty($FilePath))
				{
					# Get install location from Default key
					$InstallLocation = Split-Path -Path $FilePath -Parent
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false
				}

				# Some executables may have duplicate entries (keys related to executable)
				# Select only those which have a valid path (original executable keys)
				if ([string]::IsNullOrEmpty($InstallLocation))
				{
					# NOTE: Avoid spamming
					# Write-Debug -Message "Ignoring useless key: $HKLMSubKey"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

				# Get more key entries as needed
				# We want to separate leaf key name because some key names are holding alternative executable name
				$AppPaths += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					#"RegPath" = $SubKey.Name
					"Name" = $Executable
					"InstallLocation" = $InstallLocation
				}
			}
		}

		return $AppPaths
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Create data table used to hold information for specific program for each user
.PARAMETER TableName
Table name
.EXAMPLE
$MyTable = Initialize-Table
.INPUTS
None. You cannot pipe objects to Initialize-Table
.OUTPUTS
System.Data.DataTable empty table with 2 columns, user entry and install location
#>
function Initialize-Table
{
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $TableName = "InstallationTable"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Create Table object
	if ($Develop)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] resetting global installation table"
		Set-Variable -Name InstallTable -Scope Global -Value (New-Object -TypeName System.Data.DataTable $TableName)
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] resetting local installation table"
		Set-Variable -Name InstallTable -Scope Script -Value (New-Object -TypeName System.Data.DataTable $TableName)
	}

	# Define Columns
	$PrincipalColumn = New-Object -TypeName System.Data.DataColumn Principal, ([PSObject])
	$InstallColumn = New-Object -TypeName System.Data.DataColumn InstallLocation, ([string])

	# Add the Columns
	$InstallTable.Columns.Add($PrincipalColumn)
	$InstallTable.Columns.Add($InstallColumn)
}

<#
.SYNOPSIS
Search and add new program installation directory to the global table
.PARAMETER SearchString
Search string which corresponds to the output of "Get programs" functions
.PARAMETER UserProfile
true if user profile is to be searched too, system locations only otherwise
.PARAMETER Executables
true if executable paths should be searched first.
.EXAMPLE
Update-Table "Google Chrome"
.INPUTS
None. You cannot pipe objects to Update-Table
.OUTPUTS
None, global installation table is updated
.NOTES
Table code needs to be updated to fill it for USERS instead of same path for each individual user
#>
function Update-Table
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $SearchString,

		[Parameter()]
		[switch] $UserProfile,

		[Parameter()]
		[switch] $Executables
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Search string is: $SearchString"

	# To reduce typing and make code clear
	$UserGroups = Get-UserGroups -Machine $PolicyStore

	if ($Executables)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching executable names for: $SearchString"

		$TargetPath = $ExecutablePaths |
		Where-Object -Property Name -eq $SearchString |
		Select-Object -ExpandProperty InstallLocation

		if ($TargetPath)
		{
			# Create a row
			$Row = $InstallTable.NewRow()

			# Enter data into row
			$Row.Principal = $UserGroups | Where-Object -Property Group -eq "Users"
			$Row.InstallLocation = $TargetPath

			# Add row to the table
			$InstallTable.Rows.Add($Row)

			# If the path is known there is not need to continue
			return
		}
	}

	# TODO: try to search also for path in addition to program name
	# TODO: SearchString may pick up irrelevant paths (ie. unreal), or even miss
	# Search system wide installed programs
	if ($SystemPrograms.Name -like "*$SearchString*")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching system programs for $SearchString"

		# TODO: need better mechanism for multiple maches
		$TargetPrograms = $SystemPrograms | Where-Object -Property Name -like "*$SearchString*"

		foreach ($Program in $TargetPrograms)
		{
			# Create a row
			$Row = $InstallTable.NewRow()

			# Enter data into row
			$Row.Principal = $UserGroups | Where-Object -Property Group -eq "Users"
			$Row.InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

			# Add row to the table
			$InstallTable.Rows.Add($Row)
		}

		# Since the path is known there is not need to continue
		return
	}
	# Program not found on system, attempt alternative search
	elseif ($AllUserPrograms.Name -like "*$SearchString*")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching program install properties for $SearchString"
		$TargetPrograms = $AllUserPrograms | Where-Object -Property Name -like "*$SearchString*"

		foreach ($Program in $TargetPrograms)
		{
			# Create a row
			$Row = $InstallTable.NewRow()

			# Let see who owns the sub key which is the SID
			$KeyOwner = ConvertFrom-SID $Program.SIDKey
			if ($KeyOwner -eq "Users")
			{
				# Enter data into row
				$Row.Principal = $UserGroups | Where-Object -Property Group -eq "Users"
			}
			else
			{
				# TODO: we need more registry samples to determine what is right, Administrators seems logical
				$Row.Principal = $UserGroups | Where-Object -Property Group -eq "Administrators"
			}

			$Row.InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

			# Add row to the table
			$InstallTable.Rows.Add($Row)
		}

		# Since the path is known there is not need to continue
		return
	}

	# Search user profiles
	if ($UserProfile)
	{
		foreach ($Account in $UserAccounts)
		{
			# NOTE: the story is different here, each user may have multiple matches for search string
			# letting one match to have same principal would be mistake.
			$UserPrograms = Get-UserPrograms $Account.User | Where-Object -Property Name -like "*$SearchString*"

			if ($UserPrograms)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching $Account programs for $SearchString"

				foreach ($Program in $UserPrograms)
				{
					# Create a row
					$Row = $InstallTable.NewRow()

					# Enter data into row
					$Row.Principal = $Account.User
					$Row.InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

					# Add the row to the table
					$InstallTable.Rows.Add($Row)
				}
			}
		}
	}
}

<#
.SYNOPSIS
Manually add new program installation directory to the global table from string for each user
.PARAMETER InstallRoot
Program installation directory
.EXAMPLE
Edit-Table "%ProgramFiles(x86)%\TeamViewer"
.INPUTS
None. You cannot pipe objects to Edit-Table
.OUTPUTS
None, global installation table is updated
.NOTES
TODO: principal parameter?
#>
function Edit-Table
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $InstallLocation
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempt to insert new entry into installation table"

	# Nothing to do if the path does not exist
	if (!(Test-Environment $InstallLocation))
	{
		# TODO: will be true also for user profile, we should try to fix the path if it leads to user prfofile instead of doing nothing.
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $InstallLocation not found or invalid"
		return
	}

	# Check if input path leads to user profile
	if (Test-UserProfile $InstallLocation)
	{
		# Make sure user profile variables are removed
		$InstallLocation = Format-Path ([System.Environment]::ExpandEnvironmentVariables($InstallLocation))

		# Create a row
		$Row = $InstallTable.NewRow()

		# Get a list of users to choose from
		$Users = Get-GroupUsers "Users"

		# Enter data into row, 3rd element in the path is user name
		$Row.Principal = $Users | Where-Object -Property User -eq ($InstallLocation.Split("\"))[2]
		$Row.InstallLocation = $InstallLocation

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table with $InstallLocation for $($Row.Principal)"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
		return
	}

	$InstallLocation = Format-Path $InstallLocation

	# Not user profile path, so it applies to all users

	# Create a row
	$Row = $InstallTable.NewRow()

	# Enter data into row
	$Row.Principal = Get-UserGroups -Machine $PolicyStore | Where-Object -Property Group -eq "Users"
	$Row.InstallLocation = $InstallLocation

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table with $InstallLocation for 'Users' group"

	# Add the row to the table
	$InstallTable.Rows.Add($Row)
}

<#
.SYNOPSIS
Test if given installation directory is valid
.PARAMETER Program
predefined program name
.PARAMETER FilePath
Path to program (excluding executable)
.EXAMPLE
Test-Installation "Office" "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
.INPUTS
None. You cannot pipe objects to Test-Installation
.OUTPUTS
If test OK same path, if not try to update path, else return given path back
.NOTES
TODO: temporarily using ComputerName parameter
#>
function Test-Installation
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Program,

		[Parameter(Mandatory = $true, Position = 1)]
		[ref] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# If input path is valid just make sure it's formatted
	if (Test-Environment $FilePath.Value)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Formatting $FilePath"
		$FilePath.Value = Format-Path $FilePath.Value
	}
	elseif (Find-Installation $Program)
	{
		# NOTE: the paths in installation table are supposed to be formatted
		$InstallLocation = "unknown install location"
		$Count = $InstallTable.Rows.Count

		if ($Count -gt 1)
		{
			Write-Information -Tags "User" -MessageData "INFO: Found multiple candidate installation directories for $Program"

			# Print out all candidate installation directories
			Write-Host "0. Abort this operation"
			for ($Index = 0; $Index -lt $Count; ++$Index)
			{
				# TODO: show principal too!
				Write-Host "$($Index + 1). $($InstallTable.Rows[$Index].Item("InstallLocation"))"
			}

			# Prompt user to chose one
			[int32] $Choice = -1
			while ($Choice -lt 0 -or $Choice -gt $Count)
			{
				Write-Information -Tags "User" -MessageData "INFO: Input number to choose which one is correct"
				$Input = Read-Host

				if($Input -notmatch '^-?\d+$')
				{
					Write-Information -Tags "User" -MessageData "INFO: Digits only please!"
					continue
				}

				$Choice = $Input
			}

			if ($Choice -eq 0)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] User input is: $Choice, canceling operation"

				# User doesn't know the path, skip correction message
				return $false
			}

			$InstallLocation = $InstallTable.Rows[$Choice - 1].Item("InstallLocation")
		}
		else
		{
			$InstallLocation = $InstallTable | Select-Object -ExpandProperty InstallLocation
		}

		# Using single quotes to make it emptiness obvious when the path is empty.
		Write-Information -Tags "Project" -MessageData "INFO: Path corrected from: '$($FilePath.Value)' to: '$InstallLocation'"
		$FilePath.Value = $InstallLocation
	}
	else
	{
		return $false # installation not found
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation for $Program found"
	return $true # path exists
}

<#
.SYNOPSIS
find installation directory for given program
.PARAMETER Program
predefined program name
.PARAMETER ComputerName
Computer name on which to look for program installation
.EXAMPLE
Find-Installation "Office"
.INPUTS
None. You cannot pipe objects to Find-Installation
.OUTPUTS
True or false if installation directory if found, installation table is updated
#>
function Find-Installation
{
	[CmdletBinding()]
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
		"SQLDTS"
		{
			# $SQLServerBinnRoot = Get-SQLInstances | Select-Object -ExpandProperty SQLBinRoot
			$SQLDTSRoot = Get-SQLInstances | Select-Object -ExpandProperty SQLPath
			if ($SQLDTSRoot)
			{
				Edit-Table $SQLDTSRoot
			}
			break
		}
		"SQLManagementStudio"
		{
			$SQLManagementStudioRoot = Get-SQLManagementStudio | Select-Object -ExpandProperty InstallPath
			if ($SQLManagementStudioRoot)
			{
				Edit-Table $SQLManagementStudioRoot
			}
			break
		}
		"WindowsDefender"
		{
			$DefenderRoot = Get-WindowsDefender $ComputerName | Select-Object -ExpandProperty InstallPath
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
				Where-Object {$_.InstallPath} |
				Select-Object -Last 1 -ExpandProperty InstallPath

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
			$WindowsKits = Get-WindowsKits $ComputerName
			if ($null -ne $WindowsKits)
			{
				$SDKDebuggers = $WindowsKits |
				Where-Object {$_.Product -like "WindowsDebuggersRoot*"} |
				Sort-Object -Property Product |
				Select-Object -Last 1 -ExpandProperty InstallPath

				Write-Debug -Message "[$($MyInvocation.InvocationName)] $SDKDebuggers"
				Edit-Table $SDKDebuggers
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
		"Filezilla"
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
			Update-Table "pwsh.exe" -Executables
			break
		}
		"PowerShell64"
		{
			Update-Table "PowerShell.exe" -Executables
			break
		}
		"PowerShell86"
		{
			Edit-Table "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
			break
		}
		"OneDrive"
		{
			Edit-Table "%ProgramFiles(x86)%\Microsoft OneDrive"
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
			Update-Table "Microsoft Office"
			break
		}
		"TeamViewer"
		{
			Update-Table "Team Viewer"
			break
		}
		"EdgeChromium"
		{
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
			Update-Table "Tor" -UserProfile
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
			# TODO: need to test this
			Update-Table "GitHubDesktop" -UserProfile
			break
		}
		"EpicGames"
		{
			Edit-Table "%ProgramFiles(x86)%\Epic Games\Launcher"
			break
		}
		"UnrealEngine"
		{
			Update-Table "UnrealEngine"
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

		# TODO: this loops seem to be skiped, probably missing Test-File, need to check
		Write-Information -Tags "User" -MessageData "INFO: If you installed $Program elsewhere you can input the correct path now"
		Write-Information -Tags "User" -MessageData "INFO: or adjust the path in $Script and re-run the script later."
		Write-Information -Tags "User" -MessageData "INFO: otherwise ignore this warning if you don't have $Program installed."

		if (Approve-Execute "Yes" "Rule group for $Program" "Do you want to input path now?")
		{
			while ($InstallTable.Rows.Count -eq 0)
			{
				[string] $InstallLocation = Read-Host "Input path to '$Program' root directory"

				if (![System.String]::IsNullOrEmpty($InstallLocation))
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

		# Finaly status is bad
		Set-Variable -Name WarningStatus -Scope Global -Value $true
		return $false
	}
}

<#
.SYNOPSIS
Return installed NET Frameworks
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-NetFramework COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-NetFramework
.OUTPUTS
System.Management.Automation.PSCustomObject for installed NET Frameworks and install paths
#>
function Get-NetFramework
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		$HKLM = "SOFTWARE\Microsoft\NET Framework Setup\NDP"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		$NetFramework = @()
		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey)

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
					continue
				}

				$Version = $SubKey.GetValue("Version")
				if (![System.String]::IsNullOrEmpty($Version))
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

					$InstallLocation = $SubKey.GetValue("InstallPath")

					# else not warning because some versions are built in
					if (![System.String]::IsNullOrEmpty($InstallLocation))
					{
						$InstallLocation = Format-Path $InstallLocation
					}

					# we add entry regarldess of presence of install path
					$NetFramework += New-Object -TypeName PSObject -Property @{
						"ComputerName" = $ComputerName
						"RegKey" = $HKLMSubKey
						"Version" = $Version
						"InstallPath" = $InstallLocation
					}
				}
				else # go one key down
				{
					foreach ($HKLMKey in $SubKey.GetSubKeyNames())
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMKey"
						$Key = $SubKey.OpenSubkey($HKLMKey)

						if (!$Key)
						{
							Write-Warning -Message "Failed to open registry sub Key: $HKLMKey"
							continue
						}

						$Version = $Key.GetValue("Version")
						if ([System.String]::IsNullOrEmpty($Version))
						{
							Write-Warning -Message "Failed to read registry key entry: $HKLMKey\Version"
							continue
						}

						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMKey"

						$InstallLocation = $Key.GetValue("InstallPath")

						# else not warning because some versions are built in
						if (![System.String]::IsNullOrEmpty($InstallLocation))
						{
							$InstallLocation = Format-Path $InstallLocation
						}

						# we add entry regarldess of presence of install path
						$NetFramework += New-Object -TypeName PSObject -Property @{
							"ComputerName" = $ComputerName
							"RegKey" = $HKLMKey
							"Version" = $Version
							"InstallPath" = $InstallLocation
						}
					}
				}
			}
		}

		return $NetFramework
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Return installed Windows SDK
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-WindowsSDK COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsSDK
.OUTPUTS
System.Management.Automation.PSCustomObject for installed Windows SDK versions and install paths
#>
function Get-WindowsSDK
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = "SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows"
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Microsoft SDKs\Windows"

		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		$WindowsSDK = @()
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey)

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
					continue
				}

				$InstallLocation = $SubKey.GetValue("InstallationFolder")

				if ([System.String]::IsNullOrEmpty($InstallLocation))
				{
					Write-Warning -Message "Failed to read registry key entry: $HKLMSubKey\InstallationFolder"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"
				$InstallLocation = Format-Path $InstallLocation

				$WindowsSDK += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Product" = $SubKey.GetValue("ProductName")
					"Version" = $SubKey.GetValue("ProductVersion")
					"InstallPath" = $InstallLocation
				}
			}
		}

		return $WindowsSDK
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Return installed Windows Kits
.PARAMETER ComputerName
Computer name for which to list installed installed windows kits
.EXAMPLE
Get-WindowsKits COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsKits
.OUTPUTS
System.Management.Automation.PSCustomObject for installed Windows Kits versions and install paths
#>
function Get-WindowsKits
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = "SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"

		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows Kits\Installed Roots"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		# TODO: try catch for remote registry access
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		$WindowsKits = @()
		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($RootKeyEntry in $RootKey.GetValueNames())
			{
				$RootKeyLeaf = Split-Path $RootKey.ToString() -Leaf
				$InstallLocation = $RootKey.GetValue($RootKeyEntry)

				if ([System.String]::IsNullOrEmpty($InstallLocation))
				{
					Write-Warning -Message "Failed to read registry key entry: $RootKeyLeaf\$RootKeyEntry"
					continue
				}
				elseif ($InstallLocation -notlike "C:\Program Files*")
				{
					# NOTE: Avoid spamming
					# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key entry: $RootKeyLeaf\$RootKeyEntry"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key entry: $RootKeyLeaf\$RootKeyEntry"
				$InstallLocation = Format-Path $InstallLocation

				$WindowsKits += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $RootKeyLeaf
					"Product" = $RootKeyEntry
					"InstallPath" = $InstallLocation
				}
			}
		}

		return $WindowsKits
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Return installed Windows Defender
.PARAMETER ComputerName
Computer name for which to list installed Windows Defender
.EXAMPLE
Get-WindowsDefender COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsDefender
.OUTPUTS
System.Management.Automation.PSCustomObject for installed Windows Defender, version and install paths
#>
function Get-WindowsDefender
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		$HKLM = "SOFTWARE\Microsoft\Windows Defender"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		$WindowsDefender = $null
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			$RootKeyLeaf = Split-Path $RootKey.ToString() -Leaf
			$InstallLocation = $RootKey.GetValue("InstallLocation")

			if ([System.String]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "Failed to read registry key entry: $RootKeyLeaf\InstallLocation"
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $RootKeyLeaf"

				$WindowsDefender = New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $RootKeyLeaf
					"InstallPath" = Format-Path $InstallLocation
				}
			}
		}

		return $WindowsDefender
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get installed Microsoft SQL Server Management Studio
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-SQLManagementStudio COMPUTERNAME

	RegKey ComputerName Version      InstallPath
	------ ------------ -------      -----------
	18     COMPUTERNAME   15.0.18206.0 %ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18

.INPUTS
None. You cannot pipe objects to Get-SQLManagementStudio
.OUTPUTS
System.Management.Automation.PSCustomObject for installed Microsoft SQL Server Management Studio
 #>
 function Get-SQLManagementStudio
 {
	[CmdletBinding()]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			# NOTE: in the far future this may need to be updated, if SSMS becomes x64 bit
			$HKLM = "SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server Management Studio"
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Microsoft SQL Server Management Studio"

		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		$ManagementStudio = @()
		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: $HKLM"
		}
		else
		{
			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey)

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
					continue
				}

				$InstallLocation = $SubKey.GetValue("SSMSInstallRoot")

				if ([System.String]::IsNullOrEmpty($InstallLocation))
				{
					Write-Warning -Message "Failed to read registry key entry $HKLMSubKey\SSMSInstallRoot"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing registry key: $HKLMSubKey"

				# TODO: Should we return object by object to make pipeline work?
				# TODO: Use InstallPath in ever function, some functions have InstallRoot property instead
				# also try to get same set of properties for all req querries
				$ManagementStudio += New-Object -TypeName PSObject -Property @{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Version" = $SubKey.GetValue("Version")
					"InstallPath" = Format-Path $InstallLocation
				}
			}
		}

		return $ManagementStudio
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

#
# Module variables
#

# Installation table holds user and program directory pair
if ($Develop)
{
	Remove-Variable -Name InstallTable -Scope Script -ErrorAction Ignore
	Set-Variable -Name InstallTable -Scope Global -Value $null
}
else
{
	Remove-Variable -Name InstallTable -Scope Global -ErrorAction Ignore
	Set-Variable -Name InstallTable -Scope Script -Value $null
}

# Any environment variables to user profile are not valid for firewall
New-Variable -Name BlackListEnvironment -Scope Script -Option Constant -Value @(
	"%APPDATA%"
	"%HOME%"
	"%HOMEPATH%"
	"%LOCALAPPDATA%"
	"%OneDrive%"
	"%OneDriveConsumer%"
	"%Path%"
	"%PSModulePath%"
	"%TEMP%"
	"%TMP%"
	"%USERNAME%"
	"%USERPROFILE%"
	)

New-Variable -Name UserProfileEnvironment -Scope Script -Option Constant -Value @(
	"%APPDATA%"
	"%HOME%"
	"%HOMEPATH%"
	"%LOCALAPPDATA%"
	"%OneDrive%"
	"%OneDriveConsumer%"
	"%TEMP%"
	"%TMP%"
	"%USERNAME%"
	"%USERPROFILE%"
	)

# Programs installed for all users
New-Variable -Name SystemPrograms -Scope Script -Option ReadOnly -Value (Get-SystemPrograms -Computer $PolicyStore)

# Programs installed for all users
New-Variable -Name ExecutablePaths -Scope Script -Option ReadOnly -Value (Get-ExecutablePaths -Computer $PolicyStore)

# Programs installed for all users
New-Variable -Name AllUserPrograms -Scope Script -Option ReadOnly -Value (Get-AllUserPrograms -Computer $PolicyStore)

#
# Function exports
#

Export-ModuleMember -Function Test-File
Export-ModuleMember -Function Test-Installation
Export-ModuleMember -Function Get-AppSID
Export-ModuleMember -Function Test-Service

Export-ModuleMember -Function Format-Path
Export-ModuleMember -Function Test-UserProfile
Export-ModuleMember -Function Find-Installation
Export-ModuleMember -Function Test-Environment

Export-ModuleMember -Function Get-UserPrograms
Export-ModuleMember -Function Get-AllUserPrograms
Export-ModuleMember -Function Get-SystemPrograms
Export-ModuleMember -Function Get-ExecutablePaths

Export-ModuleMember -Function Get-NetFramework
Export-ModuleMember -Function Get-WindowsKits
Export-ModuleMember -Function Get-WindowsSDK
Export-ModuleMember -Function Get-WindowsDefender
Export-ModuleMember -Function Get-SQLInstances
Export-ModuleMember -Function Get-SQLManagementStudio

#
# Exports for debugging
#
if ($Develop)
{
	# Function exports
	Export-ModuleMember -Function Update-Table
	Export-ModuleMember -Function Edit-Table
	Export-ModuleMember -Function Initialize-Table

	# Variable exports
	Export-ModuleMember -Variable InstallTable
}

<# Opening keys, naming convention as you drill down the keys

Object (key)/	Key Path(s) name/	Sub key names (multiple)
RemoteKey	/	RegistryHive
Array of keys/	HKLM
RootKey		/	HKLMRootKey		/	HKLMNames
SubKey		/	HKLMSubKey		/	HKLMSubKeyNames
Key			/	HKLMKey			/	HKLMKeyNames
SpecificNames...
*KeyName*Entry
#>

<# In order listed
FUNCTIONS
	1 RegistryKey.OpenSubKey
	2 RegistryKey.GetValue
	3 RegistryKey.OpenRemoteBaseKey
	4 RegistryKey.GetSubKeyNames
	5 RegistryKey.GetValueNames

RETURNS
	1 The subkey requested, or null if the operation failed.
	2 The value associated with name, or null if name is not found.
	3 The requested registry key.
	4 An array of strings that contains the names of the subkeys for the current key.
	5 An array of strings that contains the value names for the current key.

EXCEPTION
	ArgumentNullException
	1 name is null.
	3 machineName is null.

	ArgumentException
	3 hKey is invalid.

	ObjectDisposedException
	1, 2, 4, 5 The RegistryKey is closed (closed keys cannot be accessed).

	SecurityException
	1 The user does not have the permissions required to access the registry key in the specified mode.

	SecurityException
	2, 5 The user does not have the permissions required to read from the registry key.
	3 The user does not have the proper permissions to perform this operation.
	4 The user does not have the permissions required to read from the key.

	IOException
	2 The RegistryKey that contains the specified value has been marked for deletion.
	3 machineName is not found.
	4, 5 A system error occurred, for example the current key has been deleted.

	UnauthorizedAccessException
	2, 3, 4, 5 The user does not have the necessary registry rights.
#>

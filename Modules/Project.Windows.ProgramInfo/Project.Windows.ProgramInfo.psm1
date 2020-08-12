
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
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

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

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}
else
{
	# Everything is default except InformationPreference should be enabled
	$InformationPreference = "Continue"
}

# Includes
. $PSScriptRoot\External\Get-SQLInstance.ps1
Import-Module -Name $PSScriptRoot\..\VSSetup
Import-Module -Name $PSScriptRoot\..\Project.Windows.UserInfo
# Import-Module -Name $PSScriptRoot\..\Project.Windows.ComputerInfo
Import-Module -Name $PSScriptRoot\..\Project.AllPlatforms.Utility

<#
.SYNOPSIS
Get store app SID
.DESCRIPTION
Get SID for single store app if the app exists
.PARAMETER UserName
Username for which to query app SID
.PARAMETER AppName
"PackageFamilyName" string
.EXAMPLE
sample: Get-AppSID "User" "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
.INPUTS
None. You cannot pipe objects to Get-AppSID
.OUTPUTS
[string] store app SID (security identifier) if app found
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
		$ACL = Get-Acl $TargetPath
		$ACE = $ACL.Access.IdentityReference.Value

		foreach ($Entry in $ACE)
		{
			# NOTE: avoid spamming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing: $Entry"

			# package SID starts with S-1-15-2-
			if ($Entry -match "S-1-15-2-")
			{
				return $Entry
			}
		}
	}
	else
	{
		Write-Warning -Message "Store app '$AppName' is not installed by user '$UserName' or the app is missing"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem let this user update all of it's apps in Windows store"
	}
}

<#
.SYNOPSIS
Check if file such as an *.exe exists
.DESCRIPTION
In addition to Test-Path of file, message and stack trace is shown
.PARAMETER FilePath
path to file
.EXAMPLE
Test-File "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
.INPUTS
None. You cannot pipe objects to Test-File
.OUTPUTS
None. Warning message if file not found
.NOTES
TODO: We should attempt to fix the path if invalid here!
TODO: We should return true or false and conditionally load rule
#>
function Test-File
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking: $ExpandedPath"

	# NOTE: or Test-Path -PathType Leaf ?
	if (!([System.IO.File]::Exists($ExpandedPath)))
	{
		# NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
		$Script = (Get-PSCallStack)[1].Command
		$SearchPath = Split-Path -Path $ExpandedPath -Parent
		$Executable = Split-Path -Path $ExpandedPath -Leaf

		Write-Warning -Message "Executable '$Executable' was not found, rules for '$Executable' won't have any effect"

		Write-Information -Tags "User" -MessageData "INFO: Searched path was: $SearchPath"
		Write-Information -Tags "User" -MessageData "INFO: To fix the problem find '$Executable' and adjust the path in $Script and re-run the script"
	}
}

<#
.SYNOPSIS
Test if path is valid for firewall rule
.DESCRIPTION
Same as Test-Path but expands system environment variables, and checks if path is compatible
for firewall rules
.PARAMETER FilePath
Path to folder, Allows null or empty since input may come from other commandlets which can return empty or null
.EXAMPLE
Test-Environment %SystemDrive%
.INPUTS
None. You cannot pipe objects to Test-Environment
.OUTPUTS
[bool] true if path exists, false otherwise
.NOTES
None.
#>
function Test-Environment
{
	[OutputType([System.Boolean])]
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

	if ([array]::Find($UserProfileEnvironment, [System.Predicate[string]] { $FilePath -like "$($args[0])*" }))
	{
		Write-Warning -Message "Rules with environment variable paths that lead to user profile are not valid"
		Write-Information -Tags "Project" -MessageData "INFO: Bad path detected is: $FilePath"
		return $false
	}

	return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)) -PathType Container)
}

<#
.SYNOPSIS
Check if service exists on system
.DESCRIPTION
Check if service exists on system, if not show warning message
.PARAMETER Service
Service name (not display name)
.EXAMPLE
Test-Service dnscache
.INPUTS
None. You cannot pipe objects to Test-Service
.OUTPUTS
None. Warning and info message if service not found
.NOTES
None.
#>
function Test-Service
{
	[OutputType([System.Void])]
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
.DESCRIPTION
User profile paths are not valid for firewall rules, this method help make a check
if this is true
.PARAMETER FilePath
File path to check, can be unformatted or have environment variables
.EXAMPLE
Test-UserProfile "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
.INPUTS
None. You cannot pipe objects to Test-UserProfile
.OUTPUTS
[bool] true if userprofile path or false otherwise
.NOTES
TODO: is it possible to nest this into Test-Environment somehow?
#>
function Test-UserProfile
{
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Impossible to know what the input may be
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
		# NOTE: Avoid spamming
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

		if ($UserProfileEnvironment -contains $Entry.Name)
		{
			# NOTE: Avoid spamming
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

	# Replace double slashes with single ones
	$FilePath = $FilePath.Replace("\\", "\")

	# If input path is root drive, removing a slash would produce bad path
	# Otherwise remove trailing slash for cases where entry path is convertible to variable
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

	while (![System.String]::IsNullOrEmpty($SearchString))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to user profile environment variable"

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
Format path into firewall compatible path
.DESCRIPTION
Various paths drilled out of registry, and those specified by the user must be
checked and properly formatted.
Formatted paths will also help sorting rules in firewall GUI based on path.
.PARAMETER FilePath
File path to format, can have environment variables, or consists of trailing slashes.
.EXAMPLE
Format-Path "C:\Program Files\\Dir\"
.INPUTS
[System.String] File path to format
.OUTPUTS
[string] formatted path, includes environment variables, stripped off of junk
.NOTES
None.
#>
function Format-Path
{
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[string] $FilePath
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# Impossible to know what the input may be
		if ([System.String]::IsNullOrEmpty($FilePath))
		{
			# TODO: why allowing empty path?
			# NOTE: Avoid spamming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
			return $FilePath
		}

		# Make an array of (environment variable/path) value pair,
		# excluding user profile environment variables
		$Variables = @()
		foreach ($Entry in @(Get-ChildItem Env:))
		{
			$Entry.Name = "%" + $Entry.Name + "%"
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

			if ($BlackListEnvironment -notcontains $Entry.Name)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting $($Entry.Name)"
				$Variables += $Entry
			}
		}

		# TODO: sorted result will have multiple same variables,
		# Sorting from longest paths which should be checked first
		$Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

		# Strip away quotations from path
		$FilePath = $FilePath.Trim('"')
		$FilePath = $FilePath.Trim("'")

		# Some paths may have semicolon (ie. command paths)
		$FilePath = $FilePath.TrimEnd(";")

		# Replace double slashes with single ones
		$FilePath = $FilePath.Replace("\\", "\")

		# NOTE: forward slashes while valid for firewall rule are not valid to format path into
		# environment variable.
		$FilePath = $FilePath.Replace("//", "\")

		# Replace forward slashes with backward ones
		$FilePath = $FilePath.Replace("/", "\")

		# If input path is root drive, removing a slash would produce bad path
		# Otherwise remove trailing slash for cases where entry path is convertible to variable
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
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path already formatted: $FilePath"
				return $FilePath
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to environment variable"
		while (![System.String]::IsNullOrEmpty($SearchString))
		{
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
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to environment variable"
		}

		# path has been reduced to root drive so get that
		$SearchString = Split-Path -Path $FilePath -Qualifier
		Write-Debug -Message "[$($MyInvocation.InvocationName)] path has been reduced to root drive, now searching for: $SearchString"

		# Find candidate replacements
		$Variables = $Variables | Where-Object { $_.Value -eq $SearchString }

		if ([System.String]::IsNullOrEmpty($Variables))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Environment variables for input path don't exist"
			# There are no environment variables for this drive
			# Just trim trailing slash
			return $FilePath.TrimEnd('\\')
		}
		elseif (($Variables | Measure-Object).Count -gt 1)
		{
			# Since there may be duplicate entries, we grab first one
			$Replacement = $Variables.Name[0]
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Multiple matches exist for '$SearchString', selecting first one: $Replacement"
		}
		else
		{
			# If there is single match selecting [0] would result in selecting a single letter not env. variable!
			$Replacement = $Variables.Name
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Found exact match for '$SearchString' -> $Replacement"
		}

		$FilePath = $FilePath.Replace($SearchString, $Replacement).TrimEnd('\\')

		# Only root drive is converted, just trim away trailing slash
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Only root drive is formatted: $FilePath"
		return $FilePath
	}
}

<#
.SYNOPSIS
Get a list of programs installed by specific user
.DESCRIPTION
Search installed programs in userprofile for specific user account
.PARAMETER UserName
User name in form of "USERNAME"
.PARAMETER ComputerName
NETBios Computer name in form of "COMPUTERNAME"
.EXAMPLE
Get-UserSoftware "USERNAME"
.INPUTS
None. You cannot pipe objects to Get-UserSoftware
.OUTPUTS
[PSCustomObject[]] list of programs for specified user on a target computer
.NOTES
TODO: We should make a query for an array of users, will help to save into variable
#>
function Get-UserSoftware
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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
		$HKU = Get-AccountSID $UserName -Computer $ComputerName
		$HKU += "\Software\Microsoft\Windows\CurrentVersion\Uninstall"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
		$UserKey = $RemoteKey.OpenSubkey($HKU)

		[PSCustomObject[]] $UserPrograms = @()
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
				$InstallLocation = Format-Path $InstallLocation #-Verbose:$false -Debug:$false

				# Get more key entries as needed
				$UserPrograms += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKUSubKey
					"Name" = $SubKey.GetValue("displayname")
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $UserPrograms
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Search installed programs for all users, system wide
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-SystemSoftware "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-SystemSoftware
.OUTPUTS
[PSCustomObject[]] list of programs installed for all users
.NOTES
We should return empty PSCustomObject if test computer fails
#>
function Get-SystemSoftware
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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
		# TODO: Test-Path those keys first?
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

		[PSCustomObject[]] $SystemPrograms = @()
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
					# once exe is removed, remove uninstall folder too if needed
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
				$SystemPrograms += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Name" = $SubKey.GetValue("DisplayName")
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $SystemPrograms
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Search program install properties for all users, system wide
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-AllUserSoftware "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-AllUserSoftware
.OUTPUTS
[PSCustomObject[]] list of programs installed for all users
.NOTES
TODO: should be renamed into Get-InstallProperties
#>
function Get-AllUserSoftware
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $AllUserPrograms = @()
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
					# NOTE: Avoid spamming (set to debug from verbose)
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMKey\InstallProperties"
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
					$AllUserPrograms += [PSCustomObject]@{
						"ComputerName" = $ComputerName
						"RegKey" = $HKLMKey
						"SIDKey" = $HKLSubMKey
						"Name" = $ProductKey.GetValue("DisplayName")
						"Version" = $ProductKey.GetValue("DisplayVersion")
						"InstallLocation" = $InstallLocation
					}
				}
			}

			Write-Output $AllUserPrograms
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
Returns a table of installed programs, with executable name, installation path,
registry path and child registry key name for target computer
.PARAMETER ComputerName
Computer name which to check
.EXAMPLE
Get-ExecutablePath "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Get-ExecutablePath
.OUTPUTS
[PSCustomObject[]] list of executables, their installation path and additional information
.NOTES
None.
#>
function Get-ExecutablePath
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $AppPaths = @()
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

					# Replace double slashes with single ones
					$FilePath = $FilePath.Replace("\\", "\")

					# Get only executable name
					$Executable = Split-Path -Path $FilePath -Leaf
				}

				# Path can be empty
				$InstallLocation = $SubKey.GetValue("Path")
				if (![string]::IsNullOrEmpty($InstallLocation))
				{
					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false
				}
				elseif (![string]::IsNullOrEmpty($FilePath))
				{
					# Get install location from Default key
					$InstallLocation = Split-Path -Path $FilePath -Parent
					# NOTE: Avoid spamming
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
				$AppPaths += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					#"RegPath" = $SubKey.Name
					"Name" = $Executable
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $AppPaths
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Create data table used to hold information for a list of programs
.DESCRIPTION
Create data table which is filled with data about programs and principals such
as users or groups and their SID for which given firewall rule applies
This method is primarily used to reset the table
Each entry in the table also has an ID to help choosing entries by ID
.PARAMETER TableName
Table name
.EXAMPLE
Initialize-Table
.INPUTS
None. You cannot pipe objects to Initialize-Table
.OUTPUTS
None. Module scope installation table with initial columns is created
.NOTES
TODO: There should be a better way to drop the table instead of recreating it
TODO: We should initialize table with complete list of programs and principals and
return the table by reference
#>
function Initialize-Table
{
	[OutputType([System.Void])]
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

	Set-Variable -Name RowIndex -Scope Script -Value 0

	# Define Columns
	$ColumnID = New-Object -TypeName System.Data.DataColumn ID, ([int32])
	$ColumnSID = New-Object -TypeName System.Data.DataColumn SID, ([string])
	$ColumnUser = New-Object -TypeName System.Data.DataColumn User, ([string])
	$ColumnGroup = New-Object -TypeName System.Data.DataColumn Group, ([string])
	$ColumnAccount = New-Object -TypeName System.Data.DataColumn Account, ([string])
	$ColumnComputer = New-Object -TypeName System.Data.DataColumn Computer, ([string])
	$ColumnInstallLocation = New-Object -TypeName System.Data.DataColumn InstallLocation, ([string])

	# Add the Columns
	$InstallTable.Columns.Add($ColumnID)
	$InstallTable.Columns.Add($ColumnSID)
	$InstallTable.Columns.Add($ColumnUser)
	$InstallTable.Columns.Add($ColumnGroup)
	$InstallTable.Columns.Add($ColumnAccount)
	$InstallTable.Columns.Add($ColumnComputer)
	$InstallTable.Columns.Add($ColumnInstallLocation)
}

<#
.SYNOPSIS
Print installation directories to console
.DESCRIPTION
Prints found program data which includes program name, program ID, install location etc.
.PARAMETER Caption
Single line string to print before printing the table
.EXAMPLE
Show-Table "Table data"
.INPUTS
None. You cannot pipe objects to Test-Installation
.OUTPUTS
None. Table data is printed to console
.NOTES
This function is needed to avoid warning of write-host inside non "Show" function
#>
function Show-Table
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $Caption
	)

	if (![String]::IsNullOrEmpty($Caption))
	{
		Write-Host $Caption
	}

	$InstallTable | Format-Table -AutoSize | Out-Host
}

<#
.SYNOPSIS
Fill data table with principal and program location
.DESCRIPTION
Search system for programs with input search string, and add new program installation directory
to the table, as well as other information needed to make a firewall rule
.PARAMETER SearchString
Search string which corresponds to the output of "Get programs" functions
.PARAMETER UserProfile
true if user profile is to be searched too, system locations only otherwise
.PARAMETER Executables
true if executable paths should be searched first.
.EXAMPLE
Update-Table "GoogleChrome"
.INPUTS
None. You cannot pipe objects to Update-Table
.OUTPUTS
None. Module scope installation table is updated
.NOTES
TODO: For programs in user profile rules should update LocalUser parameter accordingly,
currently it looks like we assign entry user group for program that applies to user only
#>
function Update-Table
{
	[OutputType([System.Void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
	param (
		[Parameter(Mandatory = $true)]
		[string] $SearchString,

		[Parameter()]
		[switch] $UserProfile,

		[Parameter()]
		[switch] $Executables
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("InstallTable", "Insert data into table"))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Search string is: $SearchString"

		# To reduce typing and make code clear
		$UserGroups = Get-UserGroup -Computer $PolicyStore

		if ($Executables)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching executable names for: $SearchString"

			$InstallLocation = $ExecutablePaths |
			Where-Object -Property Name -EQ $SearchString |
			Select-Object -ExpandProperty InstallLocation

			if ($InstallLocation)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)

				# TODO: If the path is known there is no need to continue?
				return
			}
		}

		# TODO: try to search also for path in addition to program name
		# TODO: SearchString may pick up irrelevant paths (ie. unreal engine), or even miss
		# Search system wide installed programs
		if ($SystemPrograms -and $SystemPrograms.Name -like "*$SearchString*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching system programs for $SearchString"

			# TODO: need better mechanism for multiple matches
			$TargetPrograms = $SystemPrograms | Where-Object -Property Name -Like "*$SearchString*"
			$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"

			foreach ($Program in $TargetPrograms)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)
			}
		}
		# Program not found on system, attempt alternative search
		elseif ($AllUserPrograms -and $AllUserPrograms.Name -like "*$SearchString*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching program install properties for $SearchString"
			$TargetPrograms = $AllUserPrograms | Where-Object -Property Name -Like "*$SearchString*"

			foreach ($Program in $TargetPrograms)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				# Let see who owns the sub key which is the SID
				$KeyOwner = ConvertFrom-SID $Program.SIDKey
				if ($KeyOwner -eq "Users")
				{
					$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"
				}
				else
				{
					# TODO: we need more registry samples to determine what is right, Administrators seems logical
					$Principal = $UserGroups | Where-Object -Property Group -EQ "Administrators"
				}

				$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)
			}
		}

		# Search user profiles
		# NOTE: User profile should be searched even if there is an installation system wide
		if ($UserProfile)
		{
			$Principals = Get-GroupPrincipal "Users"

			foreach ($Principal in $Principals)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching $($Principal.Account) programs for $SearchString"

				# TODO: We handle OneDrive case here but there may more such programs in the future
				# so this obviously means we need better approach to handle this
				if ($SearchString -ne "OneDrive")
				{
					# NOTE: the story is different here, each user may have multiple matches for search string
					# letting one match to have same principal would be mistake.
					$UserPrograms = Get-UserSoftware $Principal.User | Where-Object -Property Name -Like "*$SearchString*"

					if ($UserPrograms)
					{
						foreach ($Program in $UserPrograms)
						{
							# NOTE: Avoid spamming
							# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing program: $Program"

							$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

							# Create a row
							$Row = $InstallTable.NewRow()

							# Enter data into row
							$Row.ID = ++$RowIndex
							$Row.SID = $Principal.SID
							$Row.User = $Principal.User
							# TODO: we should add group entry for users
							# $Row.Group = $Principal.Group
							$Row.Account = $Principal.Account
							$Row.Computer = $Principal.Computer
							$Row.InstallLocation = $InstallLocation

							Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Account) with $InstallLocation"

							# Add the row to the table
							$InstallTable.Rows.Add($Row)
						}
					}
				}
				else
				{
					# NOTE: For one drive there is different registry drilling procedure
					$OneDriveInfo = Get-OneDrive $Principal.User

					if ($OneDriveInfo)
					{
						$InstallLocation = $OneDriveInfo | Select-Object -ExpandProperty InstallLocation

						# Create a row
						$Row = $InstallTable.NewRow()

						# Enter data into row
						$Row.ID = ++$RowIndex
						$Row.SID = $Principal.SID
						$Row.User = $Principal.User
						# TODO: we should add group entry for users
						# $Row.Group = $Principal.Group
						$Row.Account = $Principal.Account
						$Row.Computer = $Principal.Computer
						$Row.InstallLocation = $InstallLocation

						Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Account) with $InstallLocation"

						# Add the row to the table
						$InstallTable.Rows.Add($Row)
					}
				}
			}
		}
	}
}

<#
.SYNOPSIS
Manually add new program installation directory to the table
.DESCRIPTION
Based on path and if it's valid path fill the table with it and add principals and other information
.PARAMETER InstallLocation
Program installation directory
.EXAMPLE
Edit-Table "%ProgramFiles(x86)%\TeamViewer"
.INPUTS
None. You cannot pipe objects to Edit-Table
.OUTPUTS
None. Module scope installation table is updated
.NOTES
TODO: principal parameter?
#>
function Edit-Table
{
	[OutputType([System.Void])]
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
		# TODO: will be true also for user profile, we should try to fix the path if it leads to user profile instead of doing nothing.
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

		# TODO: checking if Principal exists
		# Get a list of users to choose from, 3rd element in the path is user name
		$Principal = Get-GroupPrincipal "Users" | Where-Object -Property User -EQ ($InstallLocation.Split("\"))[2]

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.SID = $Principal.SID
		$Row.User = $Principal.User
		$Row.Account = $Principal.Account
		$Row.Computer = $Principal.Computer
		$Row.InstallLocation = $InstallLocation

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($Principal.Account) with $InstallLocation"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
	else
	{
		$InstallLocation = Format-Path $InstallLocation

		# Not user profile path, so it applies to all users
		$Principal = Get-UserGroup -Computer $PolicyStore | Where-Object -Property Group -EQ "Users"

		# Create a row
		$Row = $InstallTable.NewRow()

		# Enter data into row
		$Row.ID = ++$RowIndex
		$Row.SID = $Principal.SID
		$Row.Group = $Principal.Group
		$Row.Computer = $Principal.Computer
		$Row.InstallLocation = $InstallLocation

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Editing table for $($Principal.Caption) with $InstallLocation"

		# Add the row to the table
		$InstallTable.Rows.Add($Row)
	}
}

<#
.SYNOPSIS
Test if given installation directory is valid
.DESCRIPTION
Test if given installation directory is valid and if not this method will search the
system for valid path and return it via reference parameter
.PARAMETER Program
Predefined program name for which to search
.PARAMETER FilePath
Reference to variable which holds a path to program (excluding executable)
.EXAMPLE
$MyProgram = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
Test-Installation "Office" ([ref] $MyProgram)
.INPUTS
None. You cannot pipe objects to Test-Installation
.OUTPUTS
[bool] true if path is ok or found false otherwise,
via reference, if test OK same path, if not try to update path, else given path back is not modified
.NOTES
TODO: temporarily using ComputerName parameter
#>
function Test-Installation
{
	[OutputType([System.Boolean])]
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

			# Sort the table by ID column in ascending order
			# NOTE: not needed if table is not modified
			$InstallTable.DefaultView.Sort = "ID asc"
			$InstallTable = $InstallTable.DefaultView.ToTable()

			# Print out all candidate rows
			Show-Table "Input '0' to abort this operation"

			# Prompt user to chose one
			[int32] $Choice = -1
			while ($Choice -lt 0 -or $Choice -gt $Count)
			{
				Write-Information -Tags "User" -MessageData "INFO: Input the ID number to choose which one is correct"
				$UserInput = Read-Host

				if ($UserInput -notmatch '^-?\d+$')
				{
					Write-Information -Tags "User" -MessageData "INFO: Digits only please!"
					continue
				}

				$Choice = $UserInput
			}

			if ($Choice -eq 0)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] User input is: $Choice, canceling operation"

				# User doesn't know the path, skip correction message
				return $false
			}

			$InstallLocation = $InstallTable.Rows[$Choice - 1].InstallLocation
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
Find installation directory for given predefined program name
.DESCRIPTION
Find-Installation is called by Test-Installation, ie. only if test for existing path
fails then this method kicks in
.PARAMETER Program
Predefined program name
.PARAMETER ComputerName
Computer name on which to look for program installation
.EXAMPLE
Find-Installation "Office"
.INPUTS
None. You cannot pipe objects to Find-Installation
.OUTPUTS
[bool] true or false if installation directory if found, installation table is updated
.NOTES
None.
#>
function Find-Installation
{
	[OutputType([System.Boolean])]
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
			$SQLManagementStudioRoot = Get-SQLManagementStudio | Select-Object -ExpandProperty InstallLocation
			if ($SQLManagementStudioRoot)
			{
				Edit-Table $SQLManagementStudioRoot
			}
			break
		}
		"WindowsDefender"
		{
			$DefenderRoot = Get-WindowsDefender $ComputerName | Select-Object -ExpandProperty InstallLocation
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

		# Finally status is bad
		Set-Variable -Name WarningStatus -Scope Global -Value $true
		return $false
	}
}

<#
.SYNOPSIS
Get installed NET Frameworks
.DESCRIPTION
Get-NetFramework will return all NET frameworks installed regardless if
installation directory exists or not, since some versions are built in
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-NetFramework COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-NetFramework
.OUTPUTS
[PSCustomObject[]] for installed NET Frameworks and install paths
.NOTES
None.
#>
function Get-NetFramework
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $NetFramework = @()
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

					# we add entry regardless of presence of install path
					$NetFramework += [PSCustomObject]@{
						"ComputerName" = $ComputerName
						"RegKey" = $HKLMSubKey
						"Version" = $Version
						"InstallLocation" = $InstallLocation
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

						# we add entry regardless of presence of install path
						$NetFramework += [PSCustomObject]@{
							"ComputerName" = $ComputerName
							"RegKey" = $HKLMKey
							"Version" = $Version
							"InstallLocation" = $InstallLocation
						}
					}
				}
			}
		}

		Write-Output $NetFramework
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get installed Windows SDK
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-WindowsSDK COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsSDK
.OUTPUTS
[PSCustomObject[]] for installed Windows SDK versions and install paths
.NOTES
None.
#>
function Get-WindowsSDK
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $WindowsSDK = @()
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

				$WindowsSDK += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Product" = $SubKey.GetValue("ProductName")
					"Version" = $SubKey.GetValue("ProductVersion")
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $WindowsSDK
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get installed Windows Kits
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name for which to list installed installed windows kits
.EXAMPLE
Get-WindowsKit COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsKit
.OUTPUTS
[PSCustomObject[]] for installed Windows Kits versions and install paths
.NOTES
None.
#>
function Get-WindowsKit
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $WindowsKits = @()
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

				$WindowsKits += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $RootKeyLeaf
					"Product" = $RootKeyEntry
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $WindowsKits
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get installed Windows Defender
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name for which to list installed Windows Defender
.EXAMPLE
Get-WindowsDefender COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsDefender
.OUTPUTS
[PSCustomObject] for installed Windows Defender, version and install paths
.NOTES
None.
#>
function Get-WindowsDefender
{
	[OutputType([System.Management.Automation.PSCustomObject])]
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

		[PSCustomObject] $WindowsDefender = $null
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

				$WindowsDefender = [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $RootKeyLeaf
					"InstallLocation" = Format-Path $InstallLocation
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
Get installed Microsoft SQL Server Management Studios
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
Get-SQLManagementStudio COMPUTERNAME

	RegKey ComputerName Version      InstallLocation
	------ ------------ -------      -----------
	18     COMPUTERNAME   15.0.18206.0 %ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18

.INPUTS
None. You cannot pipe objects to Get-SQLManagementStudio
.OUTPUTS
[PSCustomObject[]] for installed Microsoft SQL Server Management Studio's
.NOTES
None.
 #>
function Get-SQLManagementStudio
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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

		[PSCustomObject[]] $ManagementStudio = @()
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
				# also try to get same set of properties for all req queries
				$ManagementStudio += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					"Version" = $SubKey.GetValue("Version")
					"InstallLocation" = Format-Path $InstallLocation
				}
			}
		}

		Write-Output $ManagementStudio
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact computer: $ComputerName"
	}
}

<#
.SYNOPSIS
Get One Drive information for specific user
.DESCRIPTION
Search installed One Drive instance in userprofile for specific user account
.PARAMETER UserName
User name in form of "USERNAME"
.PARAMETER ComputerName
NETBios Computer name in form of "COMPUTERNAME"
.EXAMPLE
Get-OneDrive "USERNAME"
.INPUTS
None. You cannot pipe objects to Get-UserSoftware
.OUTPUTS
[PSCustomObject[]] One Drive program info for specified user on a target computer
.NOTES
TODO: We should make a query for an array of users, will help to save into variable,
this is duplicate comment of Get-UserSoftware
TODO: The logic of this function should probably be part of Get-UserSoftware, it is unknown
if OneDrive can be installed for all users too.
#>
function Get-OneDrive
{
	[OutputType([System.Management.Automation.PSCustomObject[]])]
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
		$HKU = Get-AccountSID $UserName -Computer $ComputerName
		$HKU += "\Software\Microsoft\OneDrive"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
		$OneDriveKey = $RemoteKey.OpenSubkey($HKU)

		[PSCustomObject[]] $OneDriveInfo = @()
		if (!$OneDriveKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKU:$HKU"
		}
		else
		{
			# NOTE: remove executable file name
			$InstallLocation = Split-Path -Path $OneDriveKey.GetValue("OneDriveTrigger") -Parent

			if ([System.String]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "Failed to read registry entry $HKU\OneDriveTrigger"
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $OneDriveKey"

				# NOTE: Avoid spamming
				$InstallLocation = Format-Path $InstallLocation #-Verbose:$false -Debug:$false

				# Get more key entries as needed
				$OneDriveInfo += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = Split-Path -Path $OneDriveKey.ToString() -Leaf
					"Name" = "OneDrive"
					"InstallLocation" = $InstallLocation
					"UserFolder" = $OneDriveKey.GetValue("UserFolder")
				}
			}
		}

		Write-Output $OneDriveInfo
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
	Write-Debug -Message "[$ThisModule] Initialize Global variable: InstallTable"
	Remove-Variable -Name InstallTable -Scope Script -ErrorAction Ignore
	Set-Variable -Name InstallTable -Scope Global -Value $null
}
else
{
	Write-Debug -Message "[$ThisModule] Initialize module variable: InstallTable"
	Remove-Variable -Name InstallTable -Scope Global -ErrorAction Ignore
	Set-Variable -Name InstallTable -Scope Script -Value $null
}

Write-Debug -Message "[$ThisModule] Initialize module Constant variable: BlackListEnvironment"
# Any environment variables to user profile or multiple paths are not valid for firewall
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

Write-Debug -Message "[$ThisModule] Initialize module Constant variable: UserProfileEnvironment"
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

Write-Debug -Message "[$ThisModule] Initialize module readonly variable: SystemPrograms"
# Programs installed for all users
New-Variable -Name SystemPrograms -Scope Script -Option ReadOnly -Value (Get-SystemSoftware -Computer $PolicyStore)

Write-Debug -Message "[$ThisModule] Initialize module readonly variable: ExecutablePaths"
# Programs installed for all users
New-Variable -Name ExecutablePaths -Scope Script -Option ReadOnly -Value (Get-ExecutablePath -Computer $PolicyStore)

Write-Debug -Message "[$ThisModule] Initialize module readonly variable: AllUserPrograms"
# Programs installed for all users
New-Variable -Name AllUserPrograms -Scope Script -Option ReadOnly -Value (Get-AllUserSoftware -Computer $PolicyStore)

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

Export-ModuleMember -Function Get-UserSoftware
Export-ModuleMember -Function Get-AllUserSoftware
Export-ModuleMember -Function Get-SystemSoftware
Export-ModuleMember -Function Get-ExecutablePath

Export-ModuleMember -Function Get-NetFramework
Export-ModuleMember -Function Get-WindowsKit
Export-ModuleMember -Function Get-WindowsSDK
Export-ModuleMember -Function Get-WindowsDefender
Export-ModuleMember -Function Get-SQLManagementStudio
Export-ModuleMember -Function Get-OneDrive

#
# External function exports
#

Export-ModuleMember -Function Get-SQLInstance

#
# Exports for debugging
#
if ($Develop)
{
	# Function exports
	Export-ModuleMember -Function Update-Table
	Export-ModuleMember -Function Edit-Table
	Export-ModuleMember -Function Initialize-Table
	Export-ModuleMember -Function Show-Table

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

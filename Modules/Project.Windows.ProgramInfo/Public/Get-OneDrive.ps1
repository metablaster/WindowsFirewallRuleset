
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
Get One Drive information for specific user
.DESCRIPTION
Search installed One Drive instance in userprofile for specific user account
.PARAMETER UserName
User name in form of "USERNAME"
.PARAMETER ComputerName
NETBIOS Computer name in form of "COMPUTERNAME"
.EXAMPLE
Get-OneDrive "USERNAME"
.INPUTS
None. You cannot pipe objects to Get-UserSoftware
.OUTPUTS
[PSCustomObject[]] OneDrive program info for specified user on a target computer
.NOTES
TODO: We should make a query for an array of users, will help to save into variable,
this is duplicate comment of Get-UserSoftware
TODO: The logic of this function should probably be part of Get-UserSoftware, it is unknown
if OneDrive can be installed for all users too.
#>
function Get-OneDrive
{
	[OutputType([PSCustomObject[]])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-OneDrive.md")]
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
		$UserSID = Get-AccountSID $UserName -Computer $ComputerName

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		# Check if target user is logged in (has it's reg hive loaded)
		[bool] $ReleaseHive = $false
		if ([array]::Find($RemoteKey.GetSubKeyNames(), [System.Predicate[string]] { $UserSID -eq $args[0] }))
		{
			$HKU = "$UserSID\Software\Microsoft\OneDrive"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] User '$UserName' is not logged into system"

			# TODO: We need environment variable for remote computer
			$UserRegConfig = "$env:SystemDrive\Users\$UserName\NTUSER.DAT"

			# NOTE: Using TempUserName instead of SID to minimize the chance of existing key with
			# that name or any kind of other unkown issues
			$TempKey = "Temp-$UserName" # $UserSID

			if (Test-Path -Path $UserRegConfig)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Loading offline hive for user '$UserName' to HKU:$TempKey"
				# NOTE: Start-Process is needed to make the command finish it's job and print status
				$Status = Get-ProcessOutput -NoNewWindow -FilePath reg.exe -ArgumentList "load HKU\$TempKey $UserRegConfig"
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Status"
				$ReleaseHive = $true
				$HKU = "$TempKey\Software\Microsoft\OneDrive"
			}
			else
			{
				Write-Warning -Message "Failed to locate user registry config: $UserRegConfig"
				return
			}
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
			$OneDriveKey = $RemoteKey.OpenSubkey($HKU)
		}
		catch
		{
			Write-Debug -Message "Exception opening registry root key: HKU:$HKU"
			if ($ReleaseHive)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Unloading and release hive HKU:$TempKey"
				[gc]::collect()
				$Status = Get-ProcessOutput -NoNewWindow -FilePath reg.exe -ArgumentList "unload HKU\$TempKey"
				Write-Debug -Message "[$($MyInvocation.InvocationName)] $Status"
			}
		}

		[PSCustomObject[]] $OneDriveInfo = @()

		if (!$OneDriveKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKU:$HKU"
		}
		else
		{
			# NOTE: remove executable file name
			$InstallLocation = Split-Path -Path $OneDriveKey.GetValue("OneDriveTrigger") -Parent

			if ([string]::IsNullOrEmpty($InstallLocation))
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

			# key loaded with 'reg load' has to be closed, if not 'reg unload' fails with "Access denied"
			# TODO: We close the key regardless, other functions using registry should also implement closing keys
			$OneDriveKey.Close()

			if ($ReleaseHive)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Unload and release hive HKU:$TempKey"
				[gc]::collect()
				$Status = Get-ProcessOutput -NoNewWindow -FilePath reg.exe -ArgumentList "unload HKU\$TempKey"
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Status"
			}
		}

		Write-Output $OneDriveInfo
	}
}

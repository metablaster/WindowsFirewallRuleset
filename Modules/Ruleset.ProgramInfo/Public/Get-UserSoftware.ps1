
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Get a list of programs installed by specific user

.DESCRIPTION
Search installed programs in userprofile for specific user account

.PARAMETER User
User name in form of "USERNAME"

.PARAMETER Domain
NETBIOS Computer name in form of "COMPUTERNAME"

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER CimSession
Specifies the CIM session to use

.PARAMETER Session
Specifies the PS session to use

.EXAMPLE
PS> Get-UserSoftware "User"

.EXAMPLE
PS> Get-UserSoftware "User" -Domain "Server01"

.INPUTS
None. You cannot pipe objects to Get-UserSoftware

.OUTPUTS
[PSCustomObject] list of programs for specified user on a target computer

.NOTES
TODO: We should make a query for an array of users, will help to save into variable
#>
function Get-UserSoftware
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserSoftware.md")]
	[OutputType("Ruleset.ProgramInfo", [void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("UserName")]
		[string] $User,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[CimSession] $CimSession,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $CimParams = @{}
	[hashtable] $SessionParams = @{}

	if ($PSCmdlet.ParameterSetName -eq "Session")
	{
		if ($Session.ComputerName -ne $CimSession.ComputerName)
		{
			Write-Error -Category InvalidArgument -TargetObject $CimSession `
				-Message "Session and CimSession must be targeting same computer"
			return
		}

		$Domain = $CimSession.ComputerName
		$CimParams.CimSession = $CimSession
		$SessionParams.Session = $Session
	}
	else
	{
		$Domain = Format-ComputerName $Domain

		# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
		if ($Domain -ne [System.Environment]::MachineName)
		{
			$CimParams.ComputerName = $Domain
			$SessionParams.ComputerName = $Domain

			if ($Credential)
			{
				$SessionParams.Credential = $Credential
			}
		}
	}

	if (Test-Computer $Domain)
	{
		$Principal = Get-PrincipalSID $User @CimParams
		if (!$Principal) { return }

		$UserSID = $Principal.SID
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer '$Domain'"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain)
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return
		}

		# Check if target user is logged in (user reg hive is loaded)
		$TempKey = $null

		if ([array]::Find($RemoteKey.GetSubKeyNames(), [System.Predicate[string]] { $UserSID -eq $args[0] }))
		{
			$HKU = "$UserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] User '$User' is not logged into system"

			[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem @CimParams |
			Select-Object -ExpandProperty SystemDrive
			$UserRegConfig = "$SystemDrive\Users\$User\NTUSER.DAT"

			if ($Domain -eq [System.Environment]::MachineName)
			{
				$PathToTest = $UserRegConfig
			}
			else
			{
				$PathToTest = "\\$Domain\$($SystemDrive.TrimEnd(":"))$\Users\$User\NTUSER.DAT"
			}

			# NOTE: Using User-UserName instead of SID to minimize the chance of existing key with same name
			$TempKey = "User-$User"

			if (Test-Path -Path $PathToTest)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Loading offline hive for user '$User' to HKU\$TempKey"

				# NOTE: Invoke-Process is needed to make the command finish it's job and print status
				$Status = Invoke-Process -NoNewWindow reg.exe -ArgumentList "load HKU\$TempKey $UserRegConfig" -Raw @SessionParams

				Write-Debug -Message "[$($MyInvocation.InvocationName)] reg load status is '$Status'"
				$HKU = "$TempKey\Software\Microsoft\Windows\CurrentVersion\Uninstall"
			}
			else
			{
				$RemoteKey.Dispose()
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to locate user registry config '$UserRegConfig'"
				return
			}
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:\$HKU"
			$RootKey = $RemoteKey.OpenSubkey($HKU, $RegistryPermission, $RegistryRights)

			if (!$RootKey)
			{
				throw [System.Data.ObjectNotFoundException]::new("The following registry key does not exist '$HKU'")
			}
		}
		catch
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Exception opening registry root key: HKU:\$HKU"

			if ($TempKey)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Unload and release hive HKU:$TempKey"

				[gc]::collect()
				$Status = Invoke-Process reg.exe -NoNewWindow -ArgumentList "unload HKU\$TempKey" -Raw @SessionParams
				Write-Debug -Message "[$($MyInvocation.InvocationName)] reg unload status is '$Status'"
			}

			Write-Warning -Message "[$($MyInvocation.InvocationName)] $($_.Exception.Message)"
			$RemoteKey.Dispose()
			return
		}

		foreach ($HKUSubKey in $RootKey.GetSubKeyNames())
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key '$HKUSubKey'"
			$SubKey = $RootKey.OpenSubkey($HKUSubKey)

			if (!$SubKey)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to open registry sub Key '$HKUSubKey'"
				continue
			}

			$InstallLocation = $SubKey.GetValue("InstallLocation")

			if ([string]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to read registry entry $HKUSubKey\InstallLocation"

				# In some instances if key name is GUID, InstallLocation might exist in HKEY_CURRENT_USER\Software\GUID
				# This worked for Motrix program
				$KeyGUID = Split-Path $SubKey.Name -Leaf
				$Match = [regex]::Match($KeyGUID, "[({]?(^([0-9A-Fa-f]{8}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{12})$)[})]?")
				if ($Match.Success)
				{
					$SoftwareKey = $RemoteKey.OpenSubkey("$UserSID\Software\$KeyGUID", $RegistryPermission, $RegistryRights)
					if ($SoftwareKey)
					{
						$InstallLocation = $SoftwareKey.GetValue("InstallLocation")
						$SoftwareKey.Close()
					}
				}

				if ([string]::IsNullOrEmpty($InstallLocation))
				{
					# NOTE: each key accessed after 'reg load' has to be closed to release handle, if not 'reg unload' fails with "Access is denied"
					# TODO: Other functions in ProgramInfo module should implement closing keys to release handles.
					$SubKey.Close()
					continue
				}
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key '$HKUSubKey'"

			# TODO: move all instances to directly format (first call above)
			# NOTE: Avoid spamming
			$InstallLocation = Format-Path $InstallLocation #-Verbose:$false -Debug:$false

			# Get more key entries as needed
			[PSCustomObject]@{
				Domain = $Domain
				Name = $SubKey.GetValue("DisplayName")
				Version = $SubKey.GetValue("DisplayVersion")
				Publisher = $SubKey.GetValue("Publisher")
				InstallLocation = $InstallLocation
				RegistryKey = "HKU:\$HKU"
				PSTypeName = "Ruleset.ProgramInfo"
			}

			$SubKey.Close()
		}

		$RootKey.Close()

		if ($TempKey)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Unload and release hive HKU\$TempKey"

			# NOTE: This is not strictly needed but is recommended before calling reg unload
			[gc]::collect()
			$Status = Invoke-Process reg.exe -NoNewWindow -ArgumentList "unload HKU\$TempKey" -Raw @SessionParams
			Write-Debug -Message "[$($MyInvocation.InvocationName)] reg unload status is '$Status'"
		}

		$RemoteKey.Dispose()
	}
}

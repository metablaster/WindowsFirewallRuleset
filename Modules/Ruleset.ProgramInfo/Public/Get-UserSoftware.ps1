
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
Get a list of programs installed by specific user

.DESCRIPTION
Search installed programs in userprofile for specific user account

.PARAMETER User
User name in form of "USERNAME"

.PARAMETER Domain
NETBIOS Computer name in form of "COMPUTERNAME"

.PARAMETER CimSession
Specifies the CIM session to use

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
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("UserName")]
		[string] $User,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $CimParams = @{}
	if ($PSCmdlet.ParameterSetName -eq "CimSession")
	{
		$Domain = $CimSession.ComputerName
		$CimParams.CimSession = $CimSession
	}
	else
	{
		$Domain = Format-ComputerName $Domain
		$CimParams.ComputerName = $Domain
	}

	if (Test-Computer $Domain)
	{
		$Principal = Get-PrincipalSID $User @CimParams
		if (!$Principal) { return }

		$HKU = $Principal.SID
		$HKU += "\Software\Microsoft\Windows\CurrentVersion\Uninstall"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain)

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
			$RootKey = $RemoteKey.OpenSubkey($HKU, $RegistryPermission, $RegistryRights)

			if (!$RootKey)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Following registry key does not exist: $HKU"
				$RemoteKey.Dispose()
				return
			}
		}
		catch
		{
			if ($RemoteKey)
			{
				$RemoteKey.Dispose()
			}

			Write-Error -ErrorRecord $_
			return
		}

		foreach ($HKUSubKey in $RootKey.GetSubKeyNames())
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKUSubKey"
			$SubKey = $RootKey.OpenSubkey($HKUSubKey)

			if (!$SubKey)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to open registry sub Key: $HKUSubKey"
				continue
			}

			$InstallLocation = $SubKey.GetValue("InstallLocation")

			if ([string]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to read registry entry $HKUSubKey\InstallLocation"
				continue
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKUSubKey"

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
		}

		$RemoteKey.Dispose()
	}
}

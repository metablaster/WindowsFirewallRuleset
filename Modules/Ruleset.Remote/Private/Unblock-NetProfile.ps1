
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Set network profile to private and disable virtual adapter

.DESCRIPTION
To configure WinRM service any network adapter which does not operate on private network profile
should be set to private profile.
Virtual adapters which are configured but not connected cannot be assigned to private profile,
also default Hyper-V switch can't be set to private even if connected, in these cases they need
to be temporarily disabled.

.EXAMPLE
PS> Unblock-NetProfile

.INPUTS
None. You cannot pipe objects to Unblock-NetProfile

.OUTPUTS
None. Unblock-NetProfile does not generate any output

.NOTES
None.
#>
function Unblock-NetProfile
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($script:Workstation)
	{
		[array] $PublicAdapter = Get-NetConnectionProfile |
		Where-Object -Property NetworkCategory -NE Private

		if ($PublicAdapter)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting connected adapters to private network profile"

			# Keep track of previous adapter profile values
			[hashtable] $script:AdapterProfile = @{}

			foreach ($Adapter in $PublicAdapter)
			{
				if ($PSCmdlet.ShouldProcess($Adapter.InterfaceAlias, "Set adapter to private network profile"))
				{
					# NOTE: This will modify following registry key:
					# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles
					# The "Category" value of corresponded NIC:
					# 0 = public
					# 1 = private
					# 2 = domain
					Set-NetConnectionProfile -InterfaceAlias $Adapter.InterfaceAlias -NetworkCategory Private
					$script:AdapterProfile.Add($Adapter.InterfaceAlias, $Adapter.NetworkCategory)
				}
				elseif (!$WhatIfPreference.IsPresent)
				{
					throw [System.OperationCanceledException]::new(
						"not all connected network adapters are operating on private profile")
				}
			}
		}

		[array] $AllVirtualAdapters = Get-NetIPConfiguration | Where-Object { !$_.NetProfile }

		if ($AllVirtualAdapters)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Temporarily disabling virtual or disconnected adapters"

			# Keep track of disabled virtual adapters
			[array] $script:VirtualAdapter = @()

			foreach ($Adapter in $AllVirtualAdapters)
			{
				if ($PSCmdlet.ShouldProcess($Adapter.InterfaceAlias, "Temporarily disable network adapter"))
				{
					Disable-NetAdapter -InterfaceAlias $Adapter.InterfaceAlias -Confirm:$false
					$script:VirtualAdapter += $Adapter.InterfaceAlias
				}
				elseif (!$WhatIfPreference.IsPresent)
				{
					throw [System.OperationCanceledException]::new(
						"not all configured network adapters are operating on private profile")
				}
			}
		}
	}
}

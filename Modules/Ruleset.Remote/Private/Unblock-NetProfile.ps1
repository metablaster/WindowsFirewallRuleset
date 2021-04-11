
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

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
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Force
	)

	if ($script:Workstation)
	{
		[array] $PublicAdapter = Get-NetConnectionProfile |
		Where-Object -Property NetworkCategory -NE Private

		if ($PublicAdapter)
		{
			Write-Warning -Message "Following network adapters need to be set to private network profile to continue"
			foreach ($Alias in $PublicAdapter.InterfaceAlias)
			{
				if ($Force -or $PSCmdlet.ShouldContinue($Alias, "Set adapter to private network profile"))
				{
					Set-NetConnectionProfile -InterfaceAlias $Alias -NetworkCategory Private -Force
				}
				else
				{
					throw [System.OperationCanceledException]::new("not all connected network adapters are not operating on private profile")
				}
			}
		}

		Set-Variable -Name VirtualAdapter -Scope Script -Value (
			Get-NetIPConfiguration | Where-Object { !$_.NetProfile })

		if ($script:VirtualAdapter)
		{
			Write-Warning -Message "Following network adapters need to be temporarily disabled to continue"
			foreach ($Alias in $script:VirtualAdapter.InterfaceAlias)
			{
				if ($Force -or $PSCmdlet.ShouldContinue($Alias, "Temporarily disable network adapter"))
				{
					Disable-NetAdapter -InterfaceAlias $Alias -Confirm:$false
				}
				else
				{
					Set-Variable -Name VirtualAdapter -Scope Script -Value $null
					throw [System.OperationCanceledException]::new("not all configured network adapters are not operating on private profile")
				}
			}
		}
	}
}

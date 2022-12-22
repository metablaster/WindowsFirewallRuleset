
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Re-enable any disabled virtual adapters and restore network profile

.DESCRIPTION
Restore-NetProfile re-enables any disabled virtual adapters and restores network profile previously
disabled by Unblock-NetProfile

.EXAMPLE
PS> Restore-NetProfile

.INPUTS
None. You cannot pipe objects to Restore-NetProfile

.OUTPUTS
None. Restore-NetProfile does not generate any output

.NOTES
None.
#>
function Restore-NetProfile
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($Workstation)
	{
		if ($script:VirtualAdapter)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Re-enabling virtual or disconnected adapters"
			foreach ($Adapter in $script:VirtualAdapter)
			{
				if ($PSCmdlet.ShouldProcess($Adapter, "Re-enable network adapter"))
				{
					Enable-NetAdapter -InterfaceAlias $Adapter
				}
			}

			Set-Variable -Name VirtualAdapter -Scope Script -Value $null -Confirm:$false
		}

		if ($script:AdapterProfile)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restoring adapter network profile"
			foreach ($Adapter in $script:AdapterProfile.GetEnumerator())
			{
				if ($PSCmdlet.ShouldProcess($Adapter.Key, "Restore network profile"))
				{
					# TODO: This will remove options from settings app
					Set-NetConnectionProfile -InterfaceAlias $Adapter.Key -NetworkCategory $Adapter.Value
				}
			}

			Set-Variable -Name AdapterProfile -Scope Script -Value $null -Confirm:$false
		}
	}
}

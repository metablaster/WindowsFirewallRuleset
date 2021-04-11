
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
Re-enable any disabled virtual adapters

.DESCRIPTION
Re-enable any disabled virtual adapters previously disabled by Unblock-NetProfile

.PARAMETER Force
The description of Force parameter.

.EXAMPLE
PS> Restore-NetProfile

.INPUTS
None. You cannot pipe objects to Restore-NetProfile

.OUTPUTS
None. Restore-NetProfile does not generate any output

.NOTES
TODO: Handle restoring network profile
TODO: Handle restoring only modified adapters
#>
function Restore-NetProfile
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Force
	)

	if ($script:Workstation -and $script:VirtualAdapter)
	{
		foreach ($Alias in $VirtualAdapter.InterfaceAlias)
		{
			if ($Force -or $PSCmdlet.ShouldContinue($Alias, "Re-enable network adapter"))
			{
				Enable-NetAdapter -InterfaceAlias $Alias
			}
		}

		Set-Variable -Name VirtualAdapter -Scope Script -Value $null
	}
}

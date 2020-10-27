
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
Update context for Approve-Execute function
.DESCRIPTION
Execution context is shown in the console every time Approve-Execute is called.
It helps to know the state and progress of execution.
.PARAMETER Root
First context string before . (dot)
.PARAMETER Section
Second context string after . (dot)
.PARAMETER Subsection
Additional string after -> (arrow)
.EXAMPLE
PS> Update-Context "IPv4" "Outbound" "RuleGroup"

[IPv4.Outbound -> RuleGroup]
.INPUTS
None. You cannot pipe objects to Update-Context
.OUTPUTS
None. Script scope context variable is updated.
.NOTES
None.
#>
function Update-Context
{
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Update-Context.md")]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Root,

		[Parameter(Mandatory = $true)]
		[string] $Section,

		[Parameter(Mandatory = $false)]
		[string] $Subsection = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("PowerShell host", "Update execution context"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting context"

		$NewContext = $Root + "." + $Section
		if (![string]::IsNullOrEmpty($Subsection))
		{
			$NewContext += " -> " + $Subsection
		}

		Set-Variable -Name Context -Scope Script -Value $NewContext
		Write-Debug -Message "Context set to '$NewContext'"
	}
}

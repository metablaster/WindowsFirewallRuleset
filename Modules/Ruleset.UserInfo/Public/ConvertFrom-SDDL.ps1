
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
Convert SDDL string to Principal

.DESCRIPTION
Convert one or multiple SDDL strings to Principals

.PARAMETER SDDL
String array of one or more strings of SDDL syntax

.EXAMPLE
PS> ConvertFrom-SDDL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

.EXAMPLE
PS> $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)" | ConvertFrom-SDDL

.INPUTS
[string]

.OUTPUTS
[string]

.NOTES
None.
#>
function ConvertFrom-SDDL
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-SDDL.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $SDDL
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Entry in $SDDL)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing $Entry"

			$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
			$ACLObject.SetSecurityDescriptorSddlForm($Entry)

			Write-Output $ACLObject.Access | Select-Object -ExpandProperty IdentityReference |
			Select-Object -ExpandProperty Value
		}
	}
}

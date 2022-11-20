
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Validate SDDL string

.DESCRIPTION
Test-SDDL checks the syntax of a SDDL string.
It does not check the existence of a principal which the SDDL represents.

.PARAMETER SDDL
SDDL strings which to test

.EXAMPLE
PS> Test-SDDL D:(A;;CC;;;S-1-5-21-2050798540-3232431180-3229034493-1002)(A;;CC;;;S-1-5-21-2050798540-3232341180-3229034493-1001)

.INPUTS
None. You cannot pipe objects to Test-SDDL

.OUTPUTS
[string] If SDDL string is valid it's returned, otherwise null

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test-SDDL/Help/en-US/Test-SDDL.md
#>
function Test-SDDL
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-SDDL.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $SDDL
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
		$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
	}
	process
	{
		foreach ($SddlString in $SDDL)
		{
			try
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Testing SDDL '$SddlString'"

				# TODO: See remarks about security:
				# https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setsecuritydescriptorsddlform
				$ACLObject.SetSecurityDescriptorSddlForm($SddlString)
				Write-Output $SddlString
			}
			catch
			{
				Write-Error -Category InvalidArgument -TargetObject $SddlString -Message "Invalid SDDL syntax '$($SddlString)' $($_.Exception.Message)"
			}
		}
	}
}

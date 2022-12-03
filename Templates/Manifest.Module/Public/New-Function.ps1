
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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

# TODO: Remove or update using statement
using namespace System

<#
.SYNOPSIS
A brief description of this function.
This keyword can be used only once in each topic.

.DESCRIPTION
A detailed description of the function.
This keyword can be used only once in each topic.

.PARAMETER ParameterName
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.PARAMETER Force
The description of Force parameter.

.EXAMPLE
PS> New-Function

Repeat ".EXAMPLE" keyword for each example.

.INPUTS
[string[]]
None. You cannot pipe objects to New-Function

.OUTPUTS
None. New-Function does not generate any output

.NOTES
None.
TODO: Update HelpURI and first link
TODO: If this is based on 3rd party function, include file and/or function changes here
TODO: Remove unneeded template code

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.MODULENAME/Help/en-US/FUNCTIONNAME.md
#>
function New-Function
{
	# NOTE: surpress function scope warning example
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "Script scope supression")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.MODULENAME/Help/en-US/FUNCTIONNAME.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $ParameterName,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	}

	process
	{
		foreach ($Value in $ParameterName)
		{
			# TODO: Update confirm parameters
			# "TARGET", "MESSAGE", "OPERATION", [ref]$reason
			# https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.shouldprocessreason?view=powershellsdk-7.0.0
			# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7#quick-parameter-reference
			$CallReason
			if ($PSCmdlet.ShouldProcess("Template TARGET", "Template MESSAGE", "Template OPERATION", [ref] $CallReason))
			{
				# NOTE: Sample output depens on amount of parameters (2, 3 or 4 parameters)
				# Performing the operation "Template MESSAGE" on target "Template TARGET"
				#
				# OR
				#
				# "Template OPERATION"
				# "Template MESSAGE"

				$CallReason
			}
		}
	}

	end
	{
	}
}

#
# Script scope variables, makes sense only for self contained module functions
# ex. when used out of a module context
#

# Template variable
New-Variable -Name TemplateVariable -Scope Script -Value $null

# TODO: Self contained module scripts could have the following code to allow executing them
# outside the context of a module

# Out of a module context
if ($MyInvocation.InvocationName -ne '.')
{
	New-Function -ParameterName $TemplateVariable
}

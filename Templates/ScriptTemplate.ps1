
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Script template

.DESCRIPTION
Use ScriptTemplate.ps1 as a template to write scripts

.PARAMETER ParameterName
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.EXAMPLE
PS> .\ScriptTemplate.ps1

Repeat ".EXAMPLE" keyword for each example.

.INPUTS
None. You cannot pipe objects to ScriptTemplate.ps1

.OUTPUTS
None. ScriptTemplate.ps1 does not generate any output

.NOTES
None.
#>

# TODO: Make Diagnostics attribute is formatted like this in all files
# TODO: Remove or update parameter block
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "", Justification = "This is template script parameter")]
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
[OutputType([void])]
param (
	[Parameter()]
	[string] $ParameterName
)

#region Initialization
#Requires -Version 5.1
# TODO: Adjust path to project settings and elevation requirement
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
# TODO: Include modules and scripts as needed
. $PSScriptRoot\ContextSetup.ps1

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Abort operation, template deny help message"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# Setup local variables
# TODO: define or remove variables
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "", Justification = "This is template variable")]
$TemplateVariable = ""

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
	return $null
}

Update-Log


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

<#PSScriptInfo
TODO: Update script metadata, see Templates\New-PSScriptInfo.ps1 for details
.VERSION 0.9.1

.GUID 66e38822-834d-4a90-b9c6-9e600a472a0a

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Script template.
A brief description of the script.

.DESCRIPTION
Use ScriptTemplate.ps1 as a template to write scripts.
A detailed description of the script.

.PARAMETER Force
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.EXAMPLE
PS> .\ScriptTemplate.ps1

Repeat ".EXAMPLE" keyword for each example

.INPUTS
None. You cannot pipe objects to ScriptTemplate.ps1

.OUTPUTS
None. ScriptTemplate.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

# TODO: Remove using statement and/or elevation requirement
using namespace System
#Requires -Version 5.1
#Requires -RunAsAdministrator

# TODO: Update parameter block
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
# TODO: Adjust path to project settings
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1
Initialize-Project -Strict

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Abort operation, template deny help message"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

# Setup local variables
# TODO: define or remove variables
$TemplateVariable = ""

# TODO: Update confirm parameters
# "TARGET", "MESSAGE", "OPERATION", [ref]$reason
# https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.shouldprocessreason?view=powershellsdk-7.0.0
# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7#quick-parameter-reference
if ($Force -or $PSCmdlet.ShouldProcess("Template TARGET", "Template MESSAGE", "Template OPERATION", [ref] $TemplateVariable))
{
	# NOTE: Sample output depens on amount of parameters (2, 3 or 4 parameters)
	# Performing the operation "Template MESSAGE" on target "Template TARGET"
	#
	# OR
	#
	# "Template OPERATION"
	# "Template MESSAGE"

	$TemplateVariable
}

Update-Log

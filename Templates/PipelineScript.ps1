
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

# TODO: Update script metadata, see Templates\New-PSScriptInfo.ps1 for details
# NOTE: Run [guid]::NewGuid() to generate new guid
<#PSScriptInfo

.VERSION 0.11.0

.GUID 66e38822-834d-4a90-b9c6-9e600a472a0a

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Script template with pipeline support.
A brief description of the script.

.DESCRIPTION
Use PipelineScript.ps1 as a template to write scripts with pipeline support.
A detailed description of the script.

.PARAMETER Force
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.EXAMPLE
PS> .\PipelineScript.ps1

Repeat ".EXAMPLE" keyword for each example

.INPUTS
None. You cannot pipe objects to PipelineScript.ps1

.OUTPUTS
None. PipelineScript.ps1 does not generate any output

.NOTES
None.
Syntax to write scripts with pipeline support is different, for more information about design rules
see notes section in Scripts\BlankTemplate.ps1

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

# TODO: Remove elevation requirement
#Requires -Version 5.1
#Requires -RunAsAdministrator

# TODO: Update parameter block
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $Force
)

DynamicParam
{
	if ($PSCmdlet.ParameterSetName -ne "ExistingParamSet")
	{
		# NOTE: For additional dynamic params add new attribute, add it to collection and to dictionary
		$ThumbPrintAttributes = New-Object -TypeName System.Management.Automation.ParameterAttribute
		$ThumbPrintAttributes.ParameterSetName = "DynamicParamSet"
		$ThumbPrintAttributes.Mandatory = $false

		$AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
		$AttributeCollection.Add($ThumbPrintAttributes)

		$ThumbPrintDynamic = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter(
			"DynamicParamName", [string], $AttributeCollection)

		$ParamDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
		$ParamDictionary.Add("DynamicParamName", $ThumbPrintDynamic)

		return $ParamDictionary
	}
}

begin
{
	#region Initialization
	# TODO: Adjust path to project settings
	. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
	Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Initialize-Project -Strict

	# User prompt
	# TODO: Update command line help messages
	$Accept = "Template accept help message"
	$Deny = "Abort operation, template deny help message"
	if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
	#endregion

	# Setup local variables
	# TODO: define or remove variables
	$TemplateVariable = ""
}

process
{
	# TODO: Update confirm parameters
	# "TARGET", "MESSAGE", "OPERATION", [ref]$reason
	# https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.shouldprocessreason?view=powershellsdk-7.0.0
	# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7#quick-parameter-reference
	if ($PSCmdlet.ShouldProcess("Template TARGET", "Template MESSAGE", "Template OPERATION", [ref] $TemplateVariable))
	{
		# NOTE: Sample output depens on amount of parameters (2, 3 or 4 parameters)
		# Performing the operation "Template MESSAGE" on target "Template TARGET"
		#
		# OR
		#
		# "Template OPERATION"
		# "Template MESSAGE"

		$TemplateVariable
		if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("DynamicParamName"))
		{
			$PSBoundParameters["DynamicParamName"]
		}
	}
}

end
{
	Update-Log
}

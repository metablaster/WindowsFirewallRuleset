
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
Used to ask user if he wants to run script
.DESCRIPTION
In addition to prompt, execution context is shown.
Asking for approval helps to let run master script and only execute specific
scripts, thus loading only needed rules.
.PARAMETER Default
Default prompt action, either 'YES' or 'NO'
.PARAMETER Title
Title of the prompt
.PARAMETER Question
Prompt question
.PARAMETER Accept
Prompt help menu for default action
.PARAMETER Deny
Prompt help menu for deny action
.EXAMPLE
PS> Approve-Execute "No" "Sample title" "Sample question"
.INPUTS
None. You cannot pipe objects to Approve-Execute
.OUTPUTS
None. true if user wants to continue, false otherwise
.NOTES
None.
#>
function Approve-Execute
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Approve-Execute.md")]
	param (
		[Parameter()]
		[ValidateSet("Yes", "No")]
		[string] $Default = "Yes",

		[Parameter()]
		[string] $Title = "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName),

		[Parameter()]
		[string] $Question = "Do you want to run this script?",

		[Parameter()]
		[string] $Accept = "Continue with only the next step of the operation",

		[Parameter()]
		[string] $Deny = "Skip this operation and proceed with the next operation"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Default is: $Default"

	# User prompt default values
	[int32] $DefaultAction = switch ($Default)
	{
		"Yes" { 0 }
		"No" { 1 }
	}

	[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
	$AcceptChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
	$DenyChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&No")

	# Setup choices
	$AcceptChoice.HelpMessage = $Accept
	$DenyChoice.HelpMessage = $Deny
	$Choices += $AcceptChoice # Decision 0
	$Choices += $DenyChoice # Decision 1

	$Title += " [$Context]"

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Default action is: $DefaultAction"

	$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $DefaultAction)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Decision is: $Decision"

	if ($Decision -eq $DefaultAction)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] The user accepted default action"
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] The user refused default action"
	}

	if ($Decision -eq 0)
	{
		return $true
	}
	elseif ($Default -eq "Yes")
	{
		Write-Warning -Message "The operation has been canceled by the user"
	}
	else
	{
		Write-Warning -Message "The operation has been canceled by default"
	}

	return $false
}

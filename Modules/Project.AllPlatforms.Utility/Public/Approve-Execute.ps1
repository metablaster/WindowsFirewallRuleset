
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
.PARAMETER DefaultAction
Default prompt action, either 'YES' or 'NO'
.PARAMETER Title
Title of the prompt
.PARAMETER Question
Prompt question
.EXAMPLE
Approve-Execute "No" "Sample title" "Sample question"
.INPUTS
None. You cannot pipe objects to Approve-Execute
.OUTPUTS
None. true if user wants to continue, false otherwise
.NOTES
TODO: implement help [?]
TODO: make this function more generic
#>
function Approve-Execute
{
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[ValidateSet("Yes", "No")]
		[string] $DefaultAction = "Yes",

		[Parameter(Mandatory = $false)]
		[string] $Title = "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName),

		[Parameter(Mandatory = $false)]
		[string] $Question = "Do you want to run this script?"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Default action is: $DefaultAction"

	$Choices = "&Yes", "&No"
	$Default = 0
	if ($DefaultAction -like "No")
	{
		$Default = 1
	}

	$Title += " [$Context]"
	$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

	if ($Decision -eq $Default)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] User choose default action"
		return $true
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] User refuses default action"
	return $false
}

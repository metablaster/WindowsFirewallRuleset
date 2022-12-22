
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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

using namespace System.Management.Automation.Host

<#
.SYNOPSIS
Customized user prompt to continue

.DESCRIPTION
Prompt user to continue running script or section of code.
In addition to prompt, an optional execution context can be shown.
Help messages for prompt choices can be optionally customized.
Asking for approval can help to run master script and only execute specific set of scripts.

.PARAMETER Title
Prompt title

.PARAMETER Context
Optional context to append to the title.
Context is automatically regenerated if the -Title parameter is empty or not set.
Otherwise previous context is reused.

.PARAMETER ContextLeaf
Optional string to append to context.
If not specified, context leaf is automatically generated if both the -Title and -Context parameters
are not set.
Otherwise if -Title is set without -Context this parameter is ignored.

.PARAMETER Question
Prompt question

.PARAMETER Accept
Custom help message for "Yes" choice

.PARAMETER Deny
Custom help message for "No" choice

.PARAMETER YesToAll
Will be set to true if user selects YesToAll.
If this is already true, Approve-Execute will bypass the prompt and return true.

.PARAMETER NoToAll
Will be set to true if user selects NoToAll.
If this is already true, Approve-Execute will bypass the prompt and return false.

.PARAMETER YesAllHelp
Custom help message for "YesToAll" choice

.PARAMETER NoAllHelp
Custom help message for "NoToAll" choice

.PARAMETER Unsafe
If specified, the command is considered unsafe and the default action is then "No"

.PARAMETER Force
If specified, only module scope last context is set and the function returns true

.EXAMPLE
PS> Approve-Execute -Unsafe -Title "Sample title" -Question "Sample question"

.EXAMPLE
PS> [bool] $YesToAll = $false
PS> [bool] $NoToAll = $false
PS> Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)

.INPUTS
None. You cannot pipe objects to Approve-Execute

.OUTPUTS
[bool] True if operation should be performed, false otherwise

.NOTES
TODO: Help messages and question message needs better description to fit more scenarios
TODO: Implement accepting arbitrary amount of choices, ex. [ChoiceDescription[]] parameter
TODO: Implement timeout to accept default choice, ex. Host.UI.RawUI.KeyAvailable
TODO: Standard parameter for help message should be -Prompt
#>
function Approve-Execute
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Approve-Execute.md")]
	[OutputType([bool])]
	param (
		[Parameter()]
		[string] $Title,

		[Parameter()]
		[string] $Context,

		[Parameter()]
		[string] $ContextLeaf,

		[Parameter()]
		[string] $Question = "Do you want to run this script?",

		[Parameter()]
		[string] $Accept = "Continue with only the next step of the operation",

		[Parameter()]
		[string] $Deny = "Skip this operation and proceed with the next operation",

		[Parameter(Mandatory = $true, ParameterSetName = "ToAll")]
		[ref] $YesToAll,

		[Parameter(Mandatory = $true, ParameterSetName = "ToAll")]
		[ref] $NoToAll,

		[Parameter(ParameterSetName = "ToAll")]
		[string] $YesAllHelp = "Continue with all the steps of the operation",

		[Parameter(ParameterSetName = "ToAll")]
		[string] $NoAllHelp = "Skip this operation and all subsequent operations",

		[Parameter()]
		[switch] $Unsafe,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ([string]::IsNullOrEmpty($Title))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting up title message"
		$Leaf = Split-Path -Path $MyInvocation.ScriptName -Leaf

		if ($PolicyStore -in $LocalStore)
		{
			$Title = "[localhost] Executing: $Leaf"
		}
		else
		{
			$Title = "[$PolicyStore] Executing: $Leaf"
		}

		if ([string]::IsNullOrEmpty($Context))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting up title context"

			$LeafBase = $Leaf -replace "\.\w{2,3}1$"
			$LeafRegex = [regex]::Escape($LeafBase)
			$RootRegex = [regex]::Escape($ProjectRoot)

			$Regex = [regex]::Match("$($MyInvocation.ScriptName)", "(?<=$RootRegex\\)(.+)(?=\\$LeafRegex)")

			if ($Regex.Success)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Regex result: $($Regex.Value)"

				if ($Regex.Value.StartsWith("Rules\"))
				{
					$Regex = [regex]::Match($Regex.Value, "^Rules\\(?<selection>IPv\d\\\w+(?=\\|$))")

					if ($Regex.Success)
					{
						$Context = $Regex.Groups["selection"]
					}
					else
					{
						Write-Error -Category ParserError -TargetObject $Regex -Message "Unable to fine tune context"
						$Context = $Regex.Value -replace "^Rules\\", ""
					}
				}
				else
				{
					$Context = $Regex.Value
				}

				if ([string]::IsNullOrEmpty($ContextLeaf))
				{
					$Context = " [$Context -> $LeafBase]"
				}
				else
				{
					$Context = " [$Context -> $ContextLeaf]"
				}
			}
			else
			{
				Write-Error -Category ParserError -TargetObject $Regex -Message "Unable to set up context"
				Write-Debug -Message "[$($MyInvocation.InvocationName)] LeafBase is '$LeafBase'"
			}
		}
		elseif ([string]::IsNullOrEmpty($ContextLeaf))
		{
			$Context = " [$Context]"
		}
		else
		{
			$Context = " [$Context -> $ContextLeaf]"
		}
	}
	elseif (![string]::IsNullOrEmpty($Context))
	{
		# TODO: Duplicate code
		if ([string]::IsNullOrEmpty($ContextLeaf))
		{
			$Context = " [$Context]"
		}
		else
		{
			$Context = " [$Context -> $ContextLeaf]"
		}
	}

	if (![string]::IsNullOrEmpty($Context))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Context set to '$Context'"
		Set-Variable -Name PreviousContext -Scope Script -Value $Context
	}

	if ($Force)
	{
		# NOTE: PreviousContext should be set regardless of -Force to keep track of context in
		# cases where an error could occur
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning true because 'Force' was specified"
		return $true
	}

	# First run will be null
	if (![string]::IsNullOrEmpty($script:PreviousContext))
	{
		$Title += $script:PreviousContext
	}

	# The index of the label in the Choices to be presented to the user as the default choice
	# NOTE: Converts switch to int32, if Unsafe is specified it's 1, otherwise it's 0
	[int32] $DefaultAction = !!$Unsafe

	# Setup choices
	[ChoiceDescription[]] $Choices = @()
	$AcceptChoice = [ChoiceDescription]::new("&Yes")
	$DenyChoice = [ChoiceDescription]::new("&No")

	$AcceptChoice.HelpMessage = $Accept
	$DenyChoice.HelpMessage = $Deny
	$Choices += $AcceptChoice # Decision 0
	$Choices += $DenyChoice # Decision 1

	if ($PSCmdlet.ParameterSetName -eq "ToAll")
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Previous YesToAll is: $($YesToAll.Value)"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Previous NoToAll is: $($NoToAll.Value)"

		if ($YesToAll.Value -eq $true)
		{
			$NoToAll.Value = $false
			return $true
		}
		if ($NoToAll.Value -eq $true)
		{
			$YesToAll.Value = $false
			return $false
		}

		$YesAllChoice = [ChoiceDescription]::new("Yes To &All")
		$NoAllChoice = [ChoiceDescription]::new("No To A&ll")

		$YesAllChoice.HelpMessage = $YesAllHelp
		$NoAllChoice.HelpMessage = $NoAllHelp

		$Choices += $YesAllChoice # Decision 2
		$Choices += $NoAllChoice # Decision 3
	}

	$Choice = $Host.UI.PromptForChoice($Title, $Question, $Choices, $DefaultAction)
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Choice selection is $Choice"

	[bool] $Continue = switch ($Choice)
	{
		0 { $true; break }
		1 { $false; break }
		2
		{
			$YesToAll.Value = $true
			$NoToAll.Value = $false
			$true
			break
		}
		default
		{
			$NoToAll.Value = $true
			$YesToAll.Value = $false
			$false
		}
	}

	if ($Continue)
	{
		if ($Unsafe)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] The user refused default action"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] The user accepted default action"
		}

		return $true
	}
	elseif ($Unsafe)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] The operation has been canceled by default"
	}
	else
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] The operation has been canceled by the user"
	}

	return $false
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Export WinRM configuration to file

.DESCRIPTION
Export-WinRM exports current WinRM configuration to file to be able to import
settings later and restore changes

.PARAMETER ParameterName
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.PARAMETER Force
The description of Force parameter.

.EXAMPLE
PS> Export-WinRM

Repeat ".EXAMPLE" keyword for each example.

.INPUTS
[string[]]
None. You cannot pipe objects to Export-WinRM

.OUTPUTS
None. Export-WinRM does not generate any output

.NOTES
None.
TODO: Remove unneeded template code

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Export-WinRM.md
#>
function Export-WinRM
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Export-WinRM.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $ParameterName,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
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

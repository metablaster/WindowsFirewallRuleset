
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

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
Write a colored output

.DESCRIPTION
Write-ColorMessage writes colored output, which let's you avoid using Write-Host to
avoid having to suppress code analysis warnings with PSScriptAnalyzer.

.PARAMETER Message
An object such as test which is to be printed or outputted in color

.PARAMETER ForegroundColor
Specifies foreground color

.PARAMETER BackgroundColor
Specifies background color

.EXAMPLE
PS> Write-ColorMessage sample_text Green

sample_text (in green)

.EXAMPLE
PS> Write-ColorMessage sample_text Red -BackGroundColor White

sample_text (in red with white background)

.INPUTS
[string]

.OUTPUTS
[string]

.NOTES
HACK: Should be possible for input object to be any object not just string, but it
works unexpectedly depending on PS edition used.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ColorMessage.md

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshost
#>
function Write-ColorMessage
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ColorMessage.md")]
	[OutputType([string])]
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("InputObject")]
		[string] $Message,

		[Parameter(Position = 1)]
		[ConsoleColor] $ForegroundColor,

		[Parameter()]
		[ConsoleColor] $BackgroundColor
	)

	begin
	{
		# Save previous colors
		$PreviousForegroundColor = $host.UI.RawUI.ForegroundColor
		$PreviousBackgroundColor = $host.UI.RawUI.BackgroundColor

		if ($BackgroundColor)
		{
			$host.UI.RawUI.BackgroundColor = $BackgroundColor
		}

		if ($ForegroundColor)
		{
			$host.UI.RawUI.ForegroundColor = $ForegroundColor
		}
	}

	process
	{
		# Writes a new line
		if (!$Message)
		{
			$Message = ""
		}

		Write-Output -InputObject $Message
	}

	end
	{
		# Restore previous colors
		$host.UI.RawUI.ForegroundColor = $PreviousForegroundColor
		$host.UI.RawUI.BackgroundColor = $PreviousBackgroundColor
	}
}

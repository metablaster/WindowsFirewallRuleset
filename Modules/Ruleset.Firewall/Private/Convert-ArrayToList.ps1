
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes
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

<#
.SYNOPSIS
Convert String array to comma separated list

.DESCRIPTION
Convert String array to comma separated list.
Used by Export-FirewallRules ex. to pack an array of IP addresses into a single string

.PARAMETER InputObject
String array which to convert

.EXAMPLE
PS> Convert-ArrayToList @("192.168.1.1", "192.168.2.1", "172.24.33.100")

"192.168.1.1,192.168.2.1,172.24.33.100"

.INPUTS
[string[]]

.OUTPUTS
[string] comma separated list

.NOTES
Following modifications by metablaster:
August 2020:
- Make Convert-ArrayToList Advanced function
- Change code style to be same as the rest of a project code
September 2020:
- Show warning for unexpected input
- Added Write-* stream
December 2020:
- Add pipline support
- Rename parameter to standard name
#>
function Convert-ArrayToList
{
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[Alias("Array")]
		[string[]] $InputObject
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[string] $Result = ""
	}
	process
	{
		if ($InputObject -and ($InputObject.Length -gt 0))
		{
			foreach ($Value In $InputObject)
			{
				$Result += "$Value,"
			}

			Write-Output $Result.TrimEnd(",")
		}
		else
		{
			Write-Warning -Message "Input is missing, result is empty string"
		}
	}
	end
	{
		Write-Output $Result
	}
}

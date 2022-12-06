
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the Apache license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Apache License

Copyright (C) 2015 Dave Wyatt

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.SYNOPSIS
Increments the version counter in a gpt.ini file.

.DESCRIPTION
Increments the version counter in a gpt.ini file.

.PARAMETER Path
Path to the gpt.ini file that is to be modified.

.PARAMETER PolicyType
Can be set to either 'Machine', 'User', or both.
This affects how the value of the Version number in the ini file is changed.

.EXAMPLE
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType Machine

Increments the Machine version counter of the local GPO.

.EXAMPLE
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType User

Increments the User version counter of the local GPO.

.EXAMPLE
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType Machine, User

Increments both the Machine and User version counters of the local GPO.

.INPUTS
None. This command does not accept pipeline input.

.OUTPUTS
None. This command does not generate output.

.NOTES
A gpt.ini file contains only a single Version value.
However, this represents two separate counters, for machine and user versions.
The high 16 bits of the value are the User counter, and the low 16 bits are the Machine counter.
For example (on PowerShell 3.0 and later), the Version value when the Machine counter is set to 3
and the User counter is set to 5 can be found by evaluating this expression: (5 -shl 16) -bor 3,
which will show up as decimal value 327683 in the INI file.
#>
function Update-GptIniVersion
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				if (Test-Path -LiteralPath $_ -PathType Leaf)
				{
					return $true
				}

				throw "Path '$_' does not exist."
			})]
		[string] $Path,

		[Parameter(Mandatory = $true)]
		[ValidateSet('Machine', 'User')]
		[string[]] $PolicyType
	)

	if ($PSCmdlet.ShouldProcess("gpt.ini file", "Increment the version counter"))
	{
		try
		{
			Update-GptIniVersion @PSBoundParameters
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}

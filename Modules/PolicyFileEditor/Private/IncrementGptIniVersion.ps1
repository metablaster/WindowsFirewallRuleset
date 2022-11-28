
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

function IncrementGptIniVersion
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string] $Path,
		[string[]] $PolicyType
	)

	$foundVersionLine = $false
	$section = ''

	$newContents = @(
		foreach ($line in Get-Content $Path)
		{
			# This might not be the most unreadable regex ever, but it's trying hard to be!
			# It's looking for section lines:  [SectionName]
			if ($line -match '^\s*\[([^\]]+)\]\s*$')
			{
				if ($section -eq 'General')
				{
					if (-not $foundVersionLine)
					{
						$foundVersionLine = $true
						$newVersion = GetNewVersionNumber -Version 0 -PolicyType $PolicyType

						"Version=$newVersion"
					}

					if (-not $foundMachineExtensionLine)
					{
						$foundMachineExtensionLine = $true
						"gPCMachineExtensionNames=$script:MachineExtensionGuids"
					}

					if (-not $foundUserExtensionLine)
					{
						$foundUserExtensionLine = $true
						"gPCUserExtensionNames=$script:UserExtensionGuids"
					}
				}

				$section = $matches[1]
			}
			elseif ($section -eq 'General' -and
				$line -match '^\s*Version\s*=\s*(\d+)\s*$' -and
				$null -ne ($version = $matches[1] -as [uint32]))
			{
				$foundVersionLine = $true
				$newVersion = GetNewVersionNumber -Version $version -PolicyType $PolicyType
				$line = "Version=$newVersion"
			}
			elseif ($section -eq 'General' -and $line -match '^\s*gPC(Machine|User)ExtensionNames\s*=')
			{
				if ($matches[1] -eq 'Machine')
				{
					$foundMachineExtensionLine = $true
				}
				else
				{
					$foundUserExtensionLine = $true
				}

				$line = EnsureAdminTemplateCseGuidsArePresent $line
			}

			$line
		}

		if ($section -eq 'General')
		{
			if (-not $foundVersionLine)
			{
				$foundVersionLine = $true
				$newVersion = GetNewVersionNumber -Version 0 -PolicyType $PolicyType

				"Version=$newVersion"
			}

			if (-not $foundMachineExtensionLine)
			{
				$foundMachineExtensionLine = $true
				"gPCMachineExtensionNames=$script:MachineExtensionGuids"
			}

			if (-not $foundUserExtensionLine)
			{
				$foundUserExtensionLine = $true
				"gPCUserExtensionNames=$script:UserExtensionGuids"
			}
		}
	)

	if ($PSCmdlet.ShouldProcess($Path, 'Increment Version number'))
	{
		Set-Content -Path $Path -Value $newContents -Encoding Ascii -Confirm:$false -WhatIf:$false
	}
}

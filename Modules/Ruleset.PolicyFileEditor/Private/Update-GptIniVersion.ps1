
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

function Update-GptIniVersion
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSProvideCommentHelp", "",
		Scope = "Function", Justification = "This is 3rd party code which needs to be studied")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param (
		[Parameter()]
		[string] $Path,

		[Parameter()]
		[string[]] $PolicyType
	)

	if ($PSCmdlet.ShouldProcess($Path, "Update version number in GPT.ini file"))
	{
		$FoundVersionLine = $false
		$Section = ""

		$NewContents = @(
			foreach ($Line in Get-Content $Path)
			{
				# This might not be the most unreadable regex ever, but it's trying hard to be!
				# It's looking for section lines:  [SectionName]
				if ($Line -match "^\s*\[([^\]]+)\]\s*$")
				{
					if ($Section -eq "General")
					{
						if (-not $FoundVersionLine)
						{
							$FoundVersionLine = $true
							$NewVersion = Get-NewVersionNumber -Version 0 -PolicyType $PolicyType

							"Version=$NewVersion"
						}

						if (-not $FoundMachineExtensionLine)
						{
							$FoundMachineExtensionLine = $true
							"gPCMachineExtensionNames=$script:MachineExtensionGuids"
						}

						if (-not $FoundUserExtensionLine)
						{
							$FoundUserExtensionLine = $true
							"gPCUserExtensionNames=$script:UserExtensionGuids"
						}
					}

					$Section = $matches[1]
				}
				elseif (($section -eq "General") -and
				($line -match "^\s*Version\s*=\s*(\d+)\s*$") -and
				($null -ne ($Version = $matches[1] -as [uint32])))
				{
					$FoundVersionLine = $true
					$NewVersion = Get-NewVersionNumber -Version $Version -PolicyType $PolicyType
					$line = "Version=$NewVersion"
				}
				elseif ($Section -eq "General" -and $line -match "^\s*gPC(Machine|User)ExtensionNames\s*=")
				{
					if ($matches[1] -eq "Machine")
					{
						$FoundMachineExtensionLine = $true
					}
					else
					{
						$FoundUserExtensionLine = $true
					}

					$line = Confirm-AdminTemplateCseGuidsArePresent $line
				}

				$line
			}

			if ($Section -eq "General")
			{
				if (-not $FoundVersionLine)
				{
					$FoundVersionLine = $true
					$NewVersion = Get-NewVersionNumber -Version 0 -PolicyType $PolicyType

					"Version=$NewVersion"
				}

				if (-not $FoundMachineExtensionLine)
				{
					$FoundMachineExtensionLine = $true
					"gPCMachineExtensionNames=$script:MachineExtensionGuids"
				}

				if (-not $FoundUserExtensionLine)
				{
					$FoundUserExtensionLine = $true
					"gPCUserExtensionNames=$script:UserExtensionGuids"
				}
			}
		) # NewContents =

		Set-Content -Path $Path -Value $NewContents -Encoding Ascii -Confirm:$false -WhatIf:$false
	}
}

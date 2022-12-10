
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

# HACK: Pester tests are not compatible with pester 5
Remove-Module Ruleset.PolicyFileEditor -ErrorAction Ignore
$ScriptRoot = Split-Path -Path (Split-Path -Path $PSCommandPath -Parent) -Parent
$Psd1Path = Join-Path $ScriptRoot Ruleset.PolicyFileEditor.psd1

$Module = $null

function New-DefaultGpo
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSProvideCommentHelp", "",
		Scope = "Function", Justification = "This is 3rd party code which needs to be studied")]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
	param (
		[Parameter()]
		[string] $Path
	)

	if ($PSCmdlet.ShouldProcess($Path, "Create new default GPO"))
	{
		$Paths = @(
			$Path
			Join-Path $Path Machine
			Join-Path $Path User
		)

		foreach ($PathItem in $Paths)
		{
			if (!(Test-Path $PathItem -PathType Container))
			{
				New-Item -Path $PathItem -ItemType Directory -ErrorAction Stop
			}
		}

		$Content = @'
[General]
gPCMachineExtensionNames=[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}]
Version=65537
gPCUserExtensionNames=[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}]
'@

		$GptIniPath = Join-Path $Path gpt.ini
		Set-Content -Path $GptIniPath -ErrorAction Stop -Encoding Ascii -Value $Content

		Get-ChildItem -Path $Path -Include registry.pol -Force | Remove-Item -Force
	}
}

function Get-GptIniVersion
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSProvideCommentHelp", "",
		Scope = "Function", Justification = "This is 3rd party code which needs to be studied")]
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $Path
	)

	foreach ($Result in Select-String -Path $Path -Pattern '^\s*Version\s*=\s*(\d+)\s*$')
	{
		foreach ($Match in $Result.Matches)
		{
			$Match.Groups[1].Value
		}
	}
}

try
{
	$Module = Import-Module $Psd1Path -ErrorAction Stop -PassThru -Force
	$GpoPath = 'TestDrive:\TestGpo'
	$GptIniPath = "$GpoPath\gpt.ini"

	Describe 'KeyValueName parsing' {
		InModuleScope Ruleset.PolicyFileEditor {
			$TestCases = @(
				@{
					KeyValueName = 'Left\Right'
					ExpectedKey = 'Left'
					ExpectedValue = 'Right'
					Description = 'Simple'
				}

				@{
					KeyValueName = 'Left\\Right'
					ExpectedKey = 'Left'
					ExpectedValue = 'Right'
					Description = 'Multiple consecutive separators'
				}

				@{
					KeyValueName = '\Left\Right'
					ExpectedKey = 'Left'
					ExpectedValue = 'Right'
					Description = 'Leading separator'
				}

				@{
					KeyValueName = 'Left\Right\'
					ExpectedKey = 'Left\Right'
					ExpectedValue = ''
					Description = 'Trailing separator'
				}

				@{
					KeyValueName = '\\\Left\\\\Right\\\\\'
					ExpectedKey = 'Left\Right'
					ExpectedValue = ''
					Description = 'Ridiculous with trailing separator'
				}

				@{
					KeyValueName = '\\\\\\\\Left\\\\\\\Right'
					ExpectedKey = 'Left'
					ExpectedValue = 'Right'
					Description = 'Ridiculous with no trailing separator'
				}
			)

			It -TestCases $TestCases 'Properly parses KeyValueName with <Description>' {
				param ($KeyValueName, $ExpectedKey, $ExpectedValue)
				$Key, $ValueName = Get-KeyValueName $KeyValueName

				$Key | Should -Be $ExpectedKey
				$ValueName | Should -Be $ExpectedValue
			}
		}
	}

	Describe 'Happy Path' {
		BeforeEach {
			New-DefaultGpo -Path $GpoPath
		}

		Context 'Incrementing GPT.Ini version' {
			# User version is the high 16 bits, Machine version is the low 16 bits.
			# Reference:  http://blogs.technet.com/b/grouppolicy/archive/2007/12/14/understanding-the-gpo-version-number.aspx

			# Default value set in our New-DefaultGpo function is 65537, or (1 -shl 16) + 1 ; Machine and User version both set to 1.
			# Decimal values ard hard-coded here so we can run the tests on PowerShell v2, which didn't have the -shl / -shr operators.
			# This puts the module's internal code which replaces these operators through a test as well.

			$TestCases = @(
				@{
					PolicyType = 'Machine'
					Expected = '65538' # (1 -shl 16) + 2
				}

				@{
					PolicyType = 'User'
					Expected = '131073' # (2 -shl 16) + 1
				}

				@{
					PolicyType = 'Machine', 'User'
					Expected = '131074' # (2 -shl 16) + 2
				}
			)

			It 'Sets the correct value for <PolicyType> updates' -TestCases $TestCases {
				param ($PolicyType, $Expected)

				Update-GptIniVersion -Path $GptIniPath -PolicyType $PolicyType
				$Version = @(Get-GptIniVersion -Path $GptIniPath)

				$Version.Count | Should -Be 1
				$Actual = $Version[0]

				$Actual | Should -Be $Expected
			}
		}

		Context 'Automated modification of gpt.ini' {
			# These tests incidentally also cover the happy path functionality of
			# Set-PolicyFileEntry and Remove-PolicyFileEntry.  We'll cover errors
			# in a different section.

			$TestCases = @(
				@{
					PolicyType = 'Machine'
					ExpectedVersions = '65538', '65539' # (1 -shl 16) + 2, (1 -shl 16) + 2
					NoGptIniUpdate = $false
					Count = 1
				}

				@{
					PolicyType = 'User'
					ExpectedVersions = '131073', '196609' # (2 -shl 16) + 1, (3 -shl 16) + 1
					NoGptIniUpdate = $false
					Count = 1
				}

				@{
					PolicyType = 'Machine'
					ExpectedVersions = '65537', '65537' # (1 -shl 16) + 1, (1 -shl 16) + 1
					NoGptIniUpdate = $true
					Count = 1
				}

				@{
					PolicyType = 'User'
					ExpectedVersions = '65537', '65537' # (1 -shl 16) + 1, (1 -shl 16) + 1
					NoGptIniUpdate = $true
					Count = 1
				}

				@{
					PolicyType = 'User'
					ExpectedVersions = '131073', '196609' # (2 -shl 16) + 1, (3 -shl 16) + 1
					NoGptIniUpdate = $false
					Count = 2
					EntriesToModify = @(
						New-Object PSObject -Property @{
							Key = 'Software\Testing'
							ValueName = 'Value1'
							Type = 'String'
							Data = 'Data'
						}

						New-Object PSObject -Property @{
							Key = 'Software\Testing'
							ValueName = 'Value2'
							Type = 'MultiString'
							Data = 'Multi', 'String', 'Data'
						}
					)
				}
			)

			It 'Behaves properly modifying <Count> entries in a <PolicyType> registry.pol file and NoGptIniUpdate is <NoGptIniUpdate>' -TestCases $TestCases {
				param ($PolicyType, [string[]] $ExpectedVersions, [switch] $NoGptIniUpdate, [object[]] $EntriesToModify)

				if (-not $PSBoundParameters.ContainsKey('EntriesToModify'))
				{
					$EntriesToModify = @(
						New-Object PSObject -Property @{
							Key = 'Software\Testing'
							ValueName = 'TestValue'
							Data = 1
							Type = 'DWord'
						}
					)
				}

				$PolicyPath = Join-Path $GpoPath $PolicyType\registry.pol

				$ScriptBlock = {
					$EntriesToModify | Set-PolicyFileEntry -Path $PolicyPath -NoGptIniUpdate:$NoGptIniUpdate
				}

				# We do this next block of code twice to ensure that when "setting" a value that is already present in the
				# GPO, the version of gpt.ini is not updated.

				# Code is deliberately duplicated (rather then refactored into a loop) so that if we get failures,
				# the line numbers will tell us whether it was on the first or second execution of the duplicated
				# parts.

				$ScriptBlock | Should Not Throw

				$Expected = $ExpectedVersions[0]
				$Version = @(Get-GptIniVersion -Path $GptIniPath)

				$Version.Count | Should -Be 1
				$Actual = $Version[0]

				$Actual | Should -Be $Expected

				$Entries = @(Get-PolicyFileEntry -Path $PolicyPath -All)

				$Entries.Count | Should -Be $EntriesToModify.Count

				$Count = $Entries.Count
				for ($i = 0; $i -lt $Count; $i++)
				{
					$MatchingEntry = $EntriesToModify | Where-Object { $_.Key -eq $Entries[$i].Key -and $_.ValueName -eq $Entries[$i].ValueName }

					$Entries[$i].ValueName | Should -Be $MatchingEntry.ValueName
					$Entries[$i].Key | Should -Be $MatchingEntry.Key
					$Entries[$i].Data | Should -Be $MatchingEntry.Data
					$Entries[$i].Type | Should -Be $MatchingEntry.Type
				}

				$ScriptBlock | Should Not Throw

				$Expected = $ExpectedVersions[0]
				$Version = @(Get-GptIniVersion -Path $GptIniPath)

				$Version.Count | Should -Be 1
				$Actual = $Version[0]

				$Actual | Should -Be $Expected

				$Entries = @(Get-PolicyFileEntry -Path $PolicyPath -All)

				$Entries.Count | Should -Be $EntriesToModify.Count

				$Count = $Entries.Count
				for ($i = 0; $i -lt $Count; $i++)
				{
					$MatchingEntry = $EntriesToModify | Where-Object { $_.Key -eq $Entries[$i].Key -and $_.ValueName -eq $Entries[$i].ValueName }

					$Entries[$i].ValueName | Should -Be $MatchingEntry.ValueName
					$Entries[$i].Key | Should -Be $MatchingEntry.Key
					$Entries[$i].Data | Should -Be $MatchingEntry.Data
					$Entries[$i].Type | Should -Be $MatchingEntry.Type
				}

				# End of duplicated bits; now we make sure that removing the entry
				# works, and still updates the gpt.ini version (if appropriate.)

				$ScriptBlock = {
					$EntriesToModify | Remove-PolicyFileEntry -Path $PolicyPath -NoGptIniUpdate:$NoGptIniUpdate
				}

				$ScriptBlock | Should Not Throw

				$Expected = $ExpectedVersions[1]
				$Version = @(Get-GptIniVersion -Path $GptIniPath)

				$Version.Count | Should -Be 1
				$Actual = $Version[0]

				$Actual | Should -Be $Expected

				$Entries = @(Get-PolicyFileEntry -Path $PolicyPath -All)

				$Entries.Count | Should -Be 0

				# Duplicate the Remove block for the same reasons; make sure the ini file isn't incremented
				# when the value is already missing.

				$ScriptBlock | Should Not Throw

				$Expected = $ExpectedVersions[1]
				$Version = @(Get-GptIniVersion -Path $GptIniPath)

				$Version.Count | Should -Be 1
				$Actual = $Version[0]

				$Actual | Should -Be $Expected

				$Entries = @(Get-PolicyFileEntry -Path $PolicyPath -All)

				$Entries.Count | Should -Be 0
			}
		}

		Context 'Get/Set parity' {
			$TestCases = @(
				@{
					TestName = 'Creates a DWord value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::DWord
					Data = @([uint32] 1)
				}

				@{
					TestName = 'Creates a QWord value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::QWord
					Data = @([UInt64] 0x100000000L)
				}

				@{
					TestName = 'Creates a String value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::String
					Data = @('I am a string')
				}

				@{
					TestName = 'Creates an ExpandString value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::ExpandString
					Data = @('My temp path is %TEMP%')
				}

				@{
					TestName = 'Creates a MultiString value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::MultiString
					Data = [string[]]('I', 'am', 'a', 'multi', 'string')
				}

				@{
					TestName = 'Creates a Binary value properly'
					Type = [Microsoft.Win32.RegistryValueKind]::Binary
					Data = [byte[]] (1..32)
				}

				@{
					TestName = 'Allows hex strings to be assigned to DWord values'
					Type = [Microsoft.Win32.RegistryValueKind]::DWord
					Data = @('0x12345')
					ExpectedData = [uint32] 0x12345
				}

				@{
					TestName = 'Allows hex strings to be assigned to QWord values'
					Type = [Microsoft.Win32.RegistryValueKind]::QWord
					Data = @('0x12345789')
					ExpectedData = [Uint64] 0x123456789L
				}

				@{
					TestName = 'Allows hex strings to be assigned to Binary types'
					Type = [Microsoft.Win32.RegistryValueKind]::Binary
					Data = '0x1', '0xFF', '0x12'
					ExpectedData = [byte[]] (0x1, 0xFF, 0x12)
				}

				@{
					TestName = 'Allows non-string data to be assigned to String values'
					Type = [Microsoft.Win32.RegistryValueKind]::String
					Data = @(12345)
					ExpectedData = '12345'
				}

				@{
					TestName = 'Allows non-string data to be assigned to ExpandString values'
					Type = [Microsoft.Win32.RegistryValueKind]::ExpandString
					Data = @(12345)
					ExpectedData = '12345'
				}

				@{
					TestName = 'Allows non-string data to be assigned to MultiString values'
					Type = [Microsoft.Win32.RegistryValueKind]::MultiString
					Data = 1..5
					ExpectedData = '1', '2', '3', '4', '5'
				}
			)

			It '<TestName>' -TestCases $TestCases {
				param ($TestName, $Type, $Data, $ExpectedData)

				$PolicyPath = Join-Path $GpoPath Machine\registry.pol

				if (-not $PSBoundParameters.ContainsKey('ExpectedData'))
				{
					$ExpectedData = $Data
				}

				$ScriptBlock = {
					Set-PolicyFileEntry -Path $PolicyPath `
						-Key Software\Testing `
						-ValueName TestValue `
						-Data $Data `
						-Type $Type
				}

				$ScriptBlock | Should Not Throw

				$Entries = @(Get-PolicyFileEntry -Path $PolicyPath -All)

				$Entries.Count | Should -Be 1

				$Entries[0].ValueName | Should -Be TestValue
				$Entries[0].Key | Should -Be Software\Testing
				$Entries[0].Type | Should -Be $Type

				$NewData = @($Entries[0].Data)
				$Data = @($Data)

				$Data.Count | Should -Be $NewData.Count

				$Count = $Data.Count
				for ($i = 0; $i -lt $Count; $i++)
				{
					$Data[$i] | Should BeExactly $NewData[$i]
				}
			}

			It 'Gets values by Key and PropertyName successfully' {
				$PolicyPath = Join-Path $GpoPath Machine\registry.pol
				$Key = 'Software\Testing'
				$ValueName = 'TestValue'
				$Data = 'I am a string'
				$Type = ([Microsoft.Win32.RegistryValueKind]::String)

				$ScriptBlock = {
					Set-PolicyFileEntry -Path $PolicyPath `
						-Key $Key `
						-ValueName $ValueName `
						-Data $Data `
						-Type $Type
				}

				$ScriptBlock | Should Not Throw

				$Entry = Get-PolicyFileEntry -Path $PolicyPath -Key $Key -ValueName $ValueName

				$Entry | Should Not Be $null
				$Entry.ValueName | Should -Be $ValueName
				$Entry.Key | Should -Be $Key
				$Entry.Type | Should -Be $Type
				$Entry.Data | Should -Be $Data
			}
		}

		Context 'Automatic creation of gpt.ini' {
			It 'Creates a gpt.ini file if one is not found' {
				Remove-Item $GptIniPath

				$Path = Join-Path $GpoPath Machine\registry.pol

				Set-PolicyFileEntry -Path $Path -Key 'Whatever' -ValueName 'Whatever' -Data 'Whatever' -Type String

				$GptIniPath | Should Exist
				Get-GptIniVersion -Path $GptIniPath | Should -Be 1
			}
		}
	}

	Describe 'Not-so-happy Path' {
		BeforeEach {
			New-DefaultGpo -Path $GpoPath
		}

		$TestCases = @(
			@{
				Type = [Microsoft.Win32.RegistryValueKind]::DWord
				ExpectedMessage = 'When -Type is set to DWord, -Data must be passed a valid UInt32 value.'
			}

			@{
				Type = [Microsoft.Win32.RegistryValueKind]::QWord
				ExpectedMessage = 'When -Type is set to QWord, -Data must be passed a valid UInt64 value.'
			}

			@{
				Type = [Microsoft.Win32.RegistryValueKind]::Binary
				ExpectedMessage = 'When -Type is set to Binary, -Data must be passed a Byte[] array.'
			}
		)

		It 'Gives a reasonable error when non-numeric data is passed to <Type> values' -TestCases $TestCases {
			# BUG: Unable to suppress
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
				"PSReviewUnusedParameter", "Type", Justification = "False Positive")]
			param (
				$Type,

				$ExpectedMessage
			)

			$ScriptBlock = {
				Set-PolicyFileEntry -Path $GpoPath\Machine\registry.pol `
					-Key Software\Testing `
					-ValueName TestValue `
					-Type $Type `
					-Data 'I am not a number' `
					-ErrorAction Stop
			}

			$ScriptBlock | Should Throw $ExpectedMessage
		}
	}
}
finally
{
	if ($null -ne $Module)
	{
		Remove-Module -ModuleInfo $Module -Force
	}
}

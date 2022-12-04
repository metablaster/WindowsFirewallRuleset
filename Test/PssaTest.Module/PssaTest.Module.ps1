
<#
.SYNOPSIS
Unit test for to test PSScriptAnalyzer Settings

.DESCRIPTION
Test correctness Config\PSScriptAnalyzerSettings.psd1, ensure all rules are working and
ensure PowerShell extension makes squigglies in editor.

.EXAMPLE
This file is intentionally associated to "test_file" in vscode settings to avoid generating
PSScriptAnalyzer warnings.
To use it uncomment "test_file" line in .vscode\settings.json and invoke analyzer on module
this way Config/PSScriptAnalyzerSettings.psd1 as well as PS extension squiggles are tested for
code analysis.

.INPUTS
None. You cannot pipe objects to Test-PSAnalyzerSettings.ps1.ps1

.OUTPUTS
None. Test-PSAnalyzerSettings.ps1.ps1 does not generate any output

.NOTES
TODO: Testing shows that not all rules works or there might be misconfiguration.

.LINK
https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSProvideCommentHelp", "",
	Justification = "To remove squiggles and better see what doesn't work")]
[CmdletBinding()]
param ()

. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

#
# CmdletDesign
#

# PSSA: pass, PS: pass
"PSUseApprovedVerbs"
function Change-Item
{
}

# TODO: PSSA: fail, PS: fail
"PSReservedCmdletChar"
function MyFunction[1]
{
}

# PSSA: pass, PS: pass
"PSReservedParams"
function Test
{
	[CmdletBinding()]
	Param
	(
		$ErrorVariable,
		$Parameter2
	)

	$ErrorVariable
	$Parameter2
}

# TODO: PSSA: fail, PS: fail
"PSShouldProcess"
# If a cmdlet declares the SupportsShouldProcess attribute, then it should also call ShouldProcess
function Set-File
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param
	(
		# Path to file
		[Parameter(Mandatory = $true)]
		$Path
	)

	"String" | Out-File -FilePath $Path
}

# PSSA: pass, PS: pass
"PSUseSingularNouns"
# cmdlets should use singular nouns and not plurals
function Get-Files
{
}

# PSSA: pass, PS: pass
"PSAvoidDefaultValueSwitchParameter"
function Test-Script
{
	[CmdletBinding()]
	Param
	(
		[switch] $Switch = $True
	)

	$Switch | Out-Null
}

# PSSA: pass, PS: pass
"PSAvoidMultipleTypeAttributes"
function Test-Script
{
	[CmdletBinding()]
	Param
	(
		[switch] [int] $Switch
	)

	$Switch | Out-Null
}

#
# ScriptFunctions
#

# PSSA: pass, PS: pass
"PSAvoidUsingCmdletAliases"
gps | Where-Object { $_.WorkingSet -gt 20000000 }

# PSSA: pass, PS: pass
"PSAvoidUsingWMICmdlet"
Get-WmiObject -Query 'Select * from Win32_Process where name LIKE "myprocess%"' | Remove-WmiObject | Out-Null
Invoke-WmiMethod -Class Win32_Process -Name "Create" -ArgumentList @{ CommandLine = "notepad.exe" } | Out-Null

# PSSA: pass, PS: pass
"PSAvoidUsingEmptyCatchBlock"
try
{
	1 / 0
}
catch [DivideByZeroException]
{
}

# TODO: PSSA: fail, PS: fail
"PSUseCmdletCorrectly"
Function Test-SetTodaysDate ()
{
	Set-Date
}

# PSSA: pass, PS: pass
"PSUseShouldProcessForStateChangingFunctions"
function Set-ServiceObject
{
	[CmdletBinding()]
	param
	(
		[string] $Parameter1
	)

	$Parameter1 | Out-Null
}

"PSAvoidUsingPositionalParameters"
Get-Command ChildItem Microsoft.PowerShell.Management | Out-Null

# PSSA: pass, PS: pass
"PSAvoidGlobalVars"
$Global:var1 = $null
function Test-NotGlobal ($var)
{
	$var + $var1 | Out-Null
}

# PSSA: pass, PS: pass
"PSUseDeclaredVarsMoreThanAssignments"
function Test
{
	$declaredVar = "Declared just for fun"
	$declaredVar2 = "Not used"
	$declaredVar | Out-Null
}

# PSSA: pass, PS: pass
"PSAvoidUsingInvokeExpression"
Invoke-Expression "Get-Process" | Out-Null

#
# ScriptingStyle
#

# NOTE: This works and is suppressed
"PSProvideCommentHelp"

# PSSA: pass, PS: pass
"PSAvoidUsingWriteHost"
function Get-MeaningOfLife
{
	Write-Host "Write-Host"
}

# NOTE: This works but is disabled in settings
"PSAvoidUsingDoubleQuotesForConstantString"
$constantValue = "I Love PowerShell"
$constantValue | Out-Null

# PSSA: pass, PS: pass
"PSUseUsingScopeModifierInNewRunspaces"
$var = "foo"
1..2 | ForEach-Object -Parallel { $var } | Out-Null

# PSSA: pass, PS: pass
"PSAvoidSemicolonsAsLineTerminators"
$a = 1 + $b;
$a | Out-Null

#
# ScriptSecurity
#

# PSSA: pass, PS: pass
"PSAvoidUsingPlainTextForPassword"
function Test-Script
{
	[CmdletBinding()]
	Param
	(
		[string] $Password
	)

	$Password | Out-Null
}

# PSSA: pass, PS: pass
"PSAvoidUsingComputerNameHardcoded"
Function Invoke-MyRemoteCommand ()
{
	Invoke-Command -Port 343 -ComputerName "hardcoderemotehostname"
}

# PSSA: pass, PS: pass
"PSUsePSCredentialType"
function Credential([String] $Credential)
{
}

# PSSA: pass, PS: pass
"PSAvoidUsingConvertToSecureStringWithPlainText"
$UserInput = Read-Host "Please enter your secure code"
$EncryptedInput = ConvertTo-SecureString -String $UserInput -AsPlainText -Force

"PSAvoidUsingUserNameAndPasswordParams"
function Test-Script
{
	[CmdletBinding()]
	Param
	(
		[String] $Username,
		[SecureString] $Password
	)

	$Username | Out-Null
	$Password | Out-Null
}

# PSSA: pass, PS: pass
"PSAvoidUsingBrokenHashAlgorithms"
Get-FileHash foo.txt -Algorithm MD5

#
# Rules not includes in samples
#

# PSSA: pass, PS: pass
"PSAvoidAssignmentToAutomaticVariable"
function foo($Error) { }

# PSSA: pass, PS: pass
"PSAvoidDefaultValueForMandatoryParameter"
function Test
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true)]
		$Parameter1 = 'default Value'
	)

	$Parameter1 | Out-Null
}

# TODO: PSSA: fail, PS: fail
"PSAvoidGlobalAliases"
New-Alias -Name Name -Value Value -Scope Global

# TODO: PSSA: fail, PS: fail
"PSAvoidGlobalFunctions"
function global:functionName {}

# PSSA: pass, PS: pass
"PSAvoidInvokingEmptyMembers"
$MyString = "abc"
$MyString.('len' + 'gth')

# NOTE: This works but is disabled in settings
# "PSAvoidLongLines"

# PSSA: pass, PS: pass
"PSAvoidOverwritingBuiltInCmdlets"
function Test-Path
{
}

# PSSA: pass, PS: pass
"PSAvoidNullOrEmptyHelpMessageAttribute"
Function BadFuncEmptyHelpMessageEmpty
{
	Param(
		[Parameter(HelpMessage = '')]
		[String] $Param
	)

	$Param | Out-Null
}

Function BadFuncEmptyHelpMessageNull
{
	Param(
		[Parameter(HelpMessage = $null)]
		[String] $Param
	)

	$Param | Out-Null
}

Function BadFuncEmptyHelpMessageNoAssignment
{
	Param(
		[Parameter(HelpMessage)]
		[String] $Param
	)

	$Param | Out-Null
}

# PSSA: pass, PS: pass
"PSAvoidShouldContinueWithoutForce"
Function Test-ShouldContinue
{
	[CmdletBinding()]
	Param
	()

	if ($PsCmdlet.ShouldContinue("ShouldContinue Query", "ShouldContinue Caption"))
	{
	}
}

# NOTE: Add trailing whitespace to test
"PSAvoidTrailingWhitespace"

# NOTE: Add space after backtick to test
# Checks that lines don't end with a backtick followed by whitespace.
"PSMisleadingBacktick"
function Test-PSMisleadingBacktick
{
	Get-Alias -Name ac | Out-Null `
		"test" | Out-Null
}

# TODO: PSSA: fail, PS: fail
"PSPossibleIncorrectComparisonWithNull"
function Test-CompareWithNull
{
	if ($DebugPreference -eq $null)
	{
	}
}

# PSSA: pass, PS: pass
"PSPossibleIncorrectUsageOfAssignmentOperator"
if ($a = $b)
{
}

# PSSA: pass, PS: pass
"PSPossibleIncorrectUsageOfRedirectionOperator"
if ($a > $b)
{
}

# PSSA: pass, PS: pass
"PSReviewUnusedParameter"
function Test-Parameter
{
	Param (
		# this parameter is never called in the function
		$Parameter
	)
}

# PSSA: pass, PS: pass
"PSUseLiteralInitializerForHashtable"
$hashtable = [hashtable]::new() | Out-Null

# PSSA: pass, PS: pass
"PSUseOutputTypeCorrectly"
function Get-Foo
{
	[CmdletBinding()]
	[OutputType([int32])]
	Param(
	)

	return "bad output"
}

# PSSA: pass, PS: pass
"PSUseProcessBlockForPipelineCommand"
Function Get-Number
{
	[CmdletBinding()]
	Param(
		[Parameter(ValueFromPipeline)]
		[int] $Number
	)

	$Number | Out-Null
}

# PSSA: pass, PS: pass
"PSUseSupportsShouldProcess"
function foo
{
	param(
		$Confirm,
		$WhatIf
	)

	$Confirm | Out-Null
	$WhatIf | Out-Null
}

# NOTE: These are disabled
# "PSUseCompatibleCmdlets"
# "PSUseCompatibleCommands"

# NOTE: settings file need to be modified to test
"PSUseCompatibleSyntax"

# NOTE: settings file need to be modified to test
"PSUseCompatibleTypes"

# TODO: unclear which help file to test, also VSCode settings re-encode files to UTF8
# Check if help file uses UTF-8 encoding.
"PSUseUTF8EncodingForHelpFile"

# NOTE: to test save this file to encoding without BOM
# PSSA: pass, PS: pass
"PSUseBOMForUnicodeEncodedFile"
UTF-8 encoded sample plain-text file
‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

#
# Code formatting, Allman
#

# PSSA: pass, PS: pass
"PSPlaceOpenBrace"
function Test-OpenBrace {
}

# PSSA: pass, PS: pass
"PSPlaceCloseBrace"
function Test-CloseBrace
{

}

# PSSA: pass, PS: pass
"PSUseConsistentWhitespace"
function Test-ConsistentWhiteSpace
{
	if ($true) {bar}
	foo{ }
	if(true) {}
	$x=1; $x | Out-Null
	@(1,2,3)
	@{a = 1;b = 2 }
	foo|bar
	foo |bar
	foo -bar $baz  -bat
	# NOTE: IgnoreAssignmentOperatorInsideHashTable option not used
	# ignore whitespace around assignment operators within multi-line hash tables
	$Test = @{
		value1      = 0
		value2      = 1
	}
}

# PSSA: pass, PS: pass
"PSUseConsistentIndentation"
function Test-ConsistentIndentation
{
	foo |
    bar |
    baz
}

# NOTE: This works but is disabled in settings
# "PSAlignAssignmentStatement"

# PSSA: pass, PS: pass
"PSUseCorrectCasing"
get-command Test-Path | Out-Null


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Unit test to test script info metadata

.DESCRIPTION
Verifies that scripts accurately describe the contents of all the scripts in repository

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-ScriptInfo.ps1

.INPUTS
None. You cannot pipe objects to Test-ScriptInfo.ps1

.OUTPUTS
None. Test-ScriptInfo.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

# GUID cache
[string[]] $GUID = @()

$Scripts = Get-ChildItem -Recurse -Path "$ProjectRoot\Scripts" -Filter *.ps1 -Exclude *.ps1xml

foreach ($Script in $Scripts)
{
	$ScriptInfo = Test-ScriptFileInfo -Path $Script.FullName

	if ($ScriptInfo)
	{
		$RelativePath = $Script.FullName.Remove(0, ([string] $ProjectRoot).Length + 1)
		Write-Debug -Message "Processing script $RelativePath"

		if ($ScriptInfo.Version -ne $ProjectVersion)
		{
			Write-Error -Category InvalidResult -TargetObject $ScriptInfo `
				-Message "Script version does not match project version"
		}

		if ($ScriptInfo.GUID)
		{
			# Check no script with duplicate GUID exists among scripts
			if ([array]::Find($GUID, [System.Predicate[string]] { $ScriptInfo.GUID -eq $args[0] }))
			{
				Write-Error -Category InvalidData -TargetObject $ScriptInfo -Message "Duplicate GUID '$($ScriptInfo.GUID)' in '$RelativePath' script"
			}

			# Add current script GUID to cache
			$GUID += $ScriptInfo.GUID
		}

		if ([string]::IsNullOrEmpty($ScriptInfo.Author))
		{
			Write-Error -Category InvalidResult -TargetObject $ScriptInfo `
				-Message "ScriptInfo is missing author field"
		}
	}

	# Must be set to null because if Test-ScriptFileInfo results in an error ScriptInfo variable
	# would be pointing to previous script
	$ScriptInfo = $null
}

Update-Log
Exit-Test

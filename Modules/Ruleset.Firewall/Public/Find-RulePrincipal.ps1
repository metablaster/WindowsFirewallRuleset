
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
Get all firewall rules with or without LocalUser value

.DESCRIPTION
Get all rules which are either missing or not missing LocalUser value, and save the result
into a JSON file.
Rules which are missing LocalUser are considered weak and need to be updated.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, which is json file into which result is saved

.PARAMETER Append
Append rules to existing file instead of replacing

.PARAMETER Weak
If specified, returns rules with no local user value,
Otherwise only rules with local user are returned

.PARAMETER Direction
Firewall rule direction, default is '*' both directions

.EXAMPLE
PS> Find-RulePrincipal -Empty

.INPUTS
None. You cannot pipe objects to Find-RulePrincipal

.OUTPUTS
[System.Void]

.NOTES
None.
#>
function Find-RulePrincipal
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Find-RulePrincipal.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[string] $FileName = "PrincipalRules",

		[Parameter()]
		[switch] $Append,

		[Parameter()]
		[switch] $Weak,

		[Parameter()]
		[ValidateSet("Inbound", "Outbound", "*")]
		[string] $Direction = "*"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Getting rules from GPO..."

	$SelectRules = Get-RegistryRule -GroupPolicy |
	Where-Object {
		# Exclude rules for store apps and services
		$null -eq $_.Owner -and
		$null -eq $_.Service -and
		$_.Direction -like $Direction
	}

	# Exclude rules with LocalUser set\unset
	if ($Weak)
	{
		$SelectRules = $SelectRules | Where-Object { $null -eq $_.LocalUser }
	}
	else
	{
		$SelectRules = $SelectRules | Where-Object { $null -ne $_.LocalUser }
	}

	$SelectRules = $SelectRules | Select-Object -Property DisplayName, DisplayGroup, Direction, LocalUser |
	Sort-Object -Property Direction, DisplayGroup

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: In total there are $(($SelectRules | Measure-Object).Count) rules in the result"

	$Path = Resolve-FileSystemPath $Path -Create
	if (!$Path)
	{
		# Errors if any, reported by Resolve-FileSystemPath
		return
	}

	# NOTE: Split-Path -Extension is not available in Windows PowerShell
	$FileExtension = [System.IO.Path]::GetExtension($FileName)

	# Save result to JSON file
	if (!$FileExtension -or ($FileExtension -ne ".json"))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
		$FileName += ".json"
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting result to $Path\$FileName"

	if ($Append)
	{
		if (Test-Path -PathType Leaf -Path "$Path\$FileName")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Appending result to JSON file"
			$JsonFile = ConvertFrom-Json -InputObject (Get-Content -Path "$Path\$FileName" -Raw)

			@($JsonFile; $SelectRules) | ConvertTo-Json |
			Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
		else
		{
			Write-Warning -Message "Not appending result to file because no existing file"
			$SelectRules | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in JSON file"
		$SelectRules | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
	}
}

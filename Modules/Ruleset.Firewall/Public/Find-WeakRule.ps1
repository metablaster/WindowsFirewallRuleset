
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Get potentially weak firewall rules

.DESCRIPTION
Find-WeakRule gets all rules which are not restrictive enough, and saves the result into a JSON file.
Intended purpose of this function is to find potentially weak rules to be able to quickly sport
incomplete rules to update them as needed for security reasons.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, which is json file into which result is saved

.PARAMETER Direction
Firewall rule direction, default is '*' both directions

.EXAMPLE
PS> Find-WeakRule -Path $Exports -Direction Outbound -FileName "WeakRules"

.EXAMPLE
PS> Find-WeakRule -Path $Exports -FileName "WeakRules"

.INPUTS
None. You cannot pipe objects to Find-WeakRule

.OUTPUTS
[System.Void]

.NOTES
None.
#>
function Find-WeakRule
{
	[CmdletBinding(DefaultParameterSetName = "None", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Find-WeakRule.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[string] $FileName = "WeakRules",

		[Parameter()]
		[ValidateSet("Inbound", "Outbound", "*")]
		[string] $Direction = "*"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	[array] $RegistryRules = Get-RegistryRule -GroupPolicy | Where-Object {
		$_.Direction -like $Direction
	}

	# Counter for progress
	[int32] $RuleCount = 0
	[array] $SelectRules = @()

	foreach ($Rule in $RegistryRules)
	{
		Write-Progress -Activity "Filtering rules" `
			-CurrentOperation "$($Rule.Direction)\$($Rule.DisplayName)" `
			-PercentComplete (++$RuleCount / $RegistryRules.Length * 100) `
			-SecondsRemaining (($RegistryRules.Length - $RuleCount + 1) / 10 * 60)

		# Select rules without protocol, remote address and local or remote port
		# Block rules are not included because there are always strong
		if (([string]::IsNullOrEmpty($Rule.RemoteAddress)) -and ([string]::IsNullOrEmpty($Rule.Protocol)) -and ($Rule.Action -ne "Block"))
		{
			if (($Rule.Direction -eq "Outbound") -and [string]::IsNullOrEmpty($Rule.RemotePort))
			{
				$RuleAdded = $true
				$SelectRules += $Rule
			}
			elseif ([string]::IsNullOrEmpty($Rule.LocalPort))
			{
				$RuleAdded = $true
				$SelectRules += $Rule
			}

			if ($RuleAdded -and ![string]::IsNullOrEmpty($Rule.LocalUser))
			{
				$Rule.LocalUser = (ConvertFrom-SDDL $Rule.LocalUser).Principal
			}
		}
	}

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: In total there are $($SelectRules.Length) rules in the result"

	if ($SelectRules.Length -eq 0) { return }

	$SelectRules = $SelectRules |
	Select-Object -Property DisplayName, DisplayGroup, Direction, Protocol, RemoteAddress, LocalPort, RemotePort, LocalUser, Program |
	Sort-Object -Property Direction, DisplayGroup

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
	$SelectRules | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
}

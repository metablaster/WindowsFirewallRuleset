
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Get all firewall rules without or with specified LocalUser value

.DESCRIPTION
Get all rules which are either missing missing LocalUser value or rules which match specified
LocalUser value, and save the result into a JSON file.
Intended purpose of this function is to find rules without LocalUser value set to be able
to quickly sport incomplete rules and assign LocalUser value for security reasons.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, which is json file into which result is saved

.PARAMETER User
User for which to obtain rules

.PARAMETER Group
Group for which to obtain rules

.PARAMETER Direction
Firewall rule direction, default is '*' both directions

.EXAMPLE
PS> Find-RulePrincipal -Path $Exports -Direction Outbound -FileName "PrincipalRules" -Group "Users"

.EXAMPLE
PS> Find-RulePrincipal -Path $Exports -FileName "NoPrincipalRules"

.INPUTS
None. You cannot pipe objects to Find-RulePrincipal

.OUTPUTS
[System.Void]

.NOTES
TODO: Should be able to query rules for multiple users or groups
#>
function Find-RulePrincipal
{
	[CmdletBinding(DefaultParameterSetName = "None", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Find-RulePrincipal.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[string] $FileName = "PrincipalRules",

		[Parameter(Mandatory = $true, ParameterSetName = "User")]
		[Parameter(ParameterSetName = "Group")]
		[Alias("UserName")]
		[string] $User,

		[Parameter(Mandatory = $true, ParameterSetName = "Group")]
		[Alias("UserGroup")]
		[string] $Group,

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

		# Exclude rules for store app and services matching direction
		# Block rules are not included because there are always strong
		if (([string]::IsNullOrEmpty($Rule.Owner)) -and ([string]::IsNullOrEmpty($Rule.Service)) -and ($Rule.Action -ne "Block"))
		{
			# Exclude rules with LocalUser set\unset
			$SearchSDDL = $true

			if ($PSCmdlet.ParameterSetName -eq "User")
			{
				$SDDL = Get-SDDL -User $User
			}
			elseif ($PSCmdlet.ParameterSetName -eq "Group")
			{
				$SDDL = Get-SDDL -Group $Group
			}
			else
			{
				$SearchSDDL = $false

				if ([string]::IsNullOrEmpty($Rule.LocalUser))
				{
					$SelectRules += $Rule
				}
			}

			if ($SearchSDDL -and (![string]::IsNullOrEmpty($Rule.LocalUser)))
			{
				if ($Rule.LocalUser -like "*$SDDL*")
				{
					$Rule.LocalUser = (ConvertFrom-SDDL $Rule.LocalUser).Principal
					$SelectRules += $Rule
				}
			}
		}
	}

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: In total there are $($SelectRules.Length) rules in the result"

	if ($SelectRules.Length -eq 0) { return }

	$SelectRules = $SelectRules | Select-Object -Property DisplayName, DisplayGroup, Direction, LocalUser, Program |
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

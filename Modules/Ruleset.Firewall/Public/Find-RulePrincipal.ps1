
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
This operation is slow, intended for debugging.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, which is json file into which result is saved

.PARAMETER Append
Append exported rules to existing file instead of replacing

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
		[string] $FileName = "NoPrincipalRules",

		[Parameter()]
		[switch] $Append,

		[Parameter()]
		[switch] $Weak,

		[Parameter()]
		[ValidateSet("Inbound", "Outbound", "*")]
		[string] $Direction = "*"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$StopWatch = [System.Diagnostics.Stopwatch]::new()
	$StopWatch.Start()

	# Exclude rules for store apps
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Getting rules from GPO..."
	$GPORules = Get-NetFirewallRule -PolicyStore $PolicyStore |
	Where-Object {
		$null -eq $_.Owner -and
		$_.Direction -like $Direction
	}

	# Exclude rules with LocalUser set\unset
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Applying security filter..."

	if ($Weak)
	{
		$UserFilter = $GPORules | Get-NetFirewallSecurityFilter |
		Where-Object -Property LocalUser -EQ Any
	}
	else
	{
		$UserFilter = $GPORules | Get-NetFirewallSecurityFilter |
		Where-Object -Property LocalUser -NE Any
	}

	# Exclude rules for services because these can't have LocalUser property set
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Applying service filter..."
	$ServiceFilter = $UserFilter | Get-NetFirewallRule |
	Get-NetFirewallServiceFilter | Where-Object -Property Service -EQ Any

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Selecting properties..."
	$ResultRules = $ServiceFilter | Get-NetFirewallRule |
	Select-Object -Property DisplayName, DisplayGroup, Direction |
	Sort-Object -Property DisplayGroup

	$StopWatch.Stop()
	$TotalHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
	$TotalMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
	$TotalMinutes += $TotalHours * 60

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Time needed to find weak rules was: $TotalMinutes minutes"

	# Replace 1 and 2 with Inbound and Outbound
	$TargetRules = @()
	foreach ($Rule in $ResultRules)
	{
		$TargetRules += [PSCustomObject]@{
			DisplayName = $Rule.DisplayName
			DisplayGroup = $Rule.DisplayGroup
			Direction = if ($Rule.Direction -eq 1) { "Inbound" } else { "Outbound" }
		}
	}

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

			@($JsonFile; $TargetRules) | ConvertTo-Json |
			Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
		else
		{
			Write-Warning -Message "Not appending result to file because no existing file"
			$TargetRules | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in JSON file"
		$TargetRules | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
	}
}

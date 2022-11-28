
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
	[CmdletBinding()]
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

	if (Get-Command [G]et-CallerPreference -CommandType Function -Module PreferenceVariables)
	{
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}

	try
	{
		IncrementGptIniVersion @PSBoundParameters
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}
}


<#
.SYNOPSIS
Removes a value from a .pol file.

.DESCRIPTION
Removes a value from a .pol file.
By default, also updates the version number in the policy's gpt.ini file.

.PARAMETER Path
Path to the .pol file that is to be modified.

.PARAMETER Key
The registry key inside the .pol file from which you want to remove a value.

.PARAMETER ValueName
The name of the registry value to be removed.
May be set to an empty string to remove the default value of a key.

.PARAMETER NoGptIniUpdate
When this switch is used, the command will not attempt to update the version number in the gpt.ini file

.EXAMPLE
Remove-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue

Removes the value Software\Policies\Something\SomeValue from the local computer Machine GPO, if present.
Updates the Machine version counter in $env:systemroot\system32\GroupPolicy\gpt.ini

.EXAMPLE
$Entries = @(
    New-Object psobject -Property @{ ValueName = 'MaxXResolution'; Data = 1680 }
    New-Object psobject -Property @{ ValueName = 'MaxYResolution'; Data = 1050 }
)
$Entries | Remove-PolicyFileEntry -Path $env:SystemRoot\system32\GroupPolicy\Machine\registry.pol `
    -Key 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'

Example of using pipeline input to remove multiple values at once.
The advantage to this approach is that the .pol file on disk (and the GPT.ini file) will be updated
if _any_ of the specified settings had to be removed, and will be left alone if the file already
did not contain any of those values.

The Key property could have also been specified via the pipeline objects instead of on the command line,
but since both values shared the same Key, this example shows that you can pass the value in either way.

.INPUTS
The Key and ValueName properties may be bound via the pipeline by property name.

.OUTPUTS
None. This command does not generate output.

.NOTES
If the specified policy file is already not present in the .pol file,
the file will not be modified, and the gpt.ini file will not be updated.
#>
function Remove-PolicyFileEntry
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
		[string] $Key,

		[Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)]
		[string] $ValueName,

		[switch] $NoGptIniUpdate
	)

	begin
	{
		if (Get-Command [G]et-CallerPreference -CommandType Function -Module PreferenceVariables)
		{
			Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		}

		$dirty = $false

		try
		{
			$policyFile = OpenPolicyFile -Path $Path -ErrorAction Stop
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}

	process
	{
		$entry = $policyFile.GetValue($Key, $ValueName)

		if ($null -eq $entry)
		{
			Write-Verbose "Entry '$Key\$ValueName' is already not present in file '$Path'."
			return
		}

		Write-Verbose "Removing entry '$Key\$ValueName' from file '$Path'"
		$policyFile.DeleteValue($Key, $ValueName)
		$dirty = $true
	}

	end
	{
		if ($dirty)
		{
			$doUpdateGptIni = -not $NoGptIniUpdate

			try
			{
				# SavePolicyFile contains the calls to $PSCmdlet.ShouldProcess, and will inherit our
				# WhatIfPreference / ConfirmPreference values from here.
				SavePolicyFile -PolicyFile $policyFile -UpdateGptIni:$doUpdateGptIni -ErrorAction Stop
			}
			catch
			{
				$PSCmdlet.ThrowTerminatingError($_)
			}
		}
	}
}

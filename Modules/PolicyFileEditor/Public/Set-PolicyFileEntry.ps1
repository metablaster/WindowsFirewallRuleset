
<#
.SYNOPSIS
Creates or modifies a value in a .pol file.

.DESCRIPTION
Creates or modifies a value in a .pol file.
By default, also updates the version number in the policy's gpt.ini file.

.PARAMETER Path
Path to the .pol file that is to be modified.

.PARAMETER Key
The registry key inside the .pol file that you want to modify.

.PARAMETER ValueName
The name of the registry value.
May be set to an empty string to modify the default value of a key.

.PARAMETER Data
The new value to assign to the registry key / value.
Cannot be $null, but can be set to an empty string or empty array.

.PARAMETER Type
The type of registry value to set in the policy file.
Cannot be set to Unknown or None, but all other values of the RegistryValueKind enum are legal.

.PARAMETER NoGptIniUpdate
When this switch is used, the command will not attempt to update the version number in the gpt.ini file

.EXAMPLE
Set-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
	-Key Software\Policies\Something -ValueName SomeValue -Data 'Hello, World!' -Type String

Assigns a value of 'Hello, World!' to the String value Software\Policies\Something\SomeValue in the local computer Machine GPO.
Updates the Machine version counter in $env:systemroot\system32\GroupPolicy\gpt.ini

.EXAMPLE
Set-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
	-Key Software\Policies\Something -ValueName SomeValue -Data 'Hello, World!' -Type String -NoGptIniUpdate

Same as example 1, except this one does not update gpt.ini right away.
This can be useful if you want to set multiple
values in the policy file and only trigger a single Group Policy refresh.

.EXAMPLE
et-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
	-Key Software\Policies\Something -ValueName SomeValue -Data '0x12345' -Type DWord

Example demonstrating that strings with valid numeric data (including hexadecimal strings beginning with 0x)
can be assigned to the numeric types DWord, QWord and Binary.

.EXAMPLE
$entries = @(
	New-Object psobject -Property @{ ValueName = 'MaxXResolution'; Data = 1680 }
	New-Object psobject -Property @{ ValueName = 'MaxYResolution'; Data = 1050 }
)

$entries | Set-PolicyFileEntry -Path $env:SystemRoot\system32\GroupPolicy\Machine\registry.pol `
	-Key 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Type DWord

Example of using pipeline input to set multiple values at once.
The advantage to this approach is that the .pol file on disk (and the GPT.ini file) will be updated
if _any_ of the specified settings had to be modified,
and will be left alone if the file already contained all of the correct values.

The Key and Type properties could have also been specified via the pipeline objects instead of on the
command line, but since both values shared the same Key and Type, this example shows that you can
pass the values in either way.

.INPUTS
The Key, ValueName, Data, and Type properties may be bound via the pipeline by property name.

.OUTPUTS
None. This command does not generate output.

.NOTES
If the specified policy file already contains the correct value, the file will not be modified,
and the gpt.ini file will not be updated.

.LINK
Get-PolicyFileEntry

.LINK
Remove-PolicyFileEntry

.LINK
Update-GptIniVersion

.LINK
about_PolicyFileEditor.Help.txt
#>
function Set-PolicyFileEntry
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
		[string] $Key,

		[Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string] $ValueName,

		[Parameter(Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[AllowEmptyCollection()]
		[object] $Data,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateScript({
				if ($_ -eq [Microsoft.Win32.RegistryValueKind]::Unknown)
				{
					throw 'Unknown is not a valid value for the Type parameter'
				}

				if ($_ -eq [Microsoft.Win32.RegistryValueKind]::None)
				{
					throw 'None is not a valid value for the Type parameter'
				}

				return $true
			})]
		[Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::String,

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
		$existingEntry = $policyFile.GetValue($Key, $ValueName)

		if ($null -ne $existingEntry -and $Type -eq (PolEntryTypeToRegistryValueKind $existingEntry.Type))
		{
			$existingData = GetEntryData -Entry $existingEntry -Type $Type
			if (DataIsEqual $Data $existingData -Type $Type)
			{
				Write-Verbose "Policy setting '$Key\$ValueName' is already set to '$Data' of type '$Type'."
				return
			}
		}

		Write-Verbose "Configuring '$Key\$ValueName' to value '$Data' of type '$Type'."

		try
		{
			switch ($Type)
			{
                ([Microsoft.Win32.RegistryValueKind]::Binary)
				{
					$bytes = $Data -as [byte[]]
					if ($null -eq $bytes)
					{
						$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'When -Type is set to Binary, -Data must be passed a Byte[] array.'
						$PSCmdlet.ThrowTerminatingError($errorRecord)
					}
					else
					{
						$policyFile.SetBinaryValue($Key, $ValueName, $bytes)
					}

					break
				}

                ([Microsoft.Win32.RegistryValueKind]::String)
				{
					$array = @($Data)

					if ($array.Count -ne 1)
					{
						$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'When -Type is set to String, -Data must be passed a scalar value or single-element array.'
						$PSCmdlet.ThrowTerminatingError($errorRecord)
					}
					else
					{
						$policyFile.SetStringValue($Key, $ValueName, $array[0].ToString())
					}

					break
				}

                ([Microsoft.Win32.RegistryValueKind]::ExpandString)
				{
					$array = @($Data)

					if ($array.Count -ne 1)
					{
						$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'When -Type is set to ExpandString, -Data must be passed a scalar value or single-element array.'
						$PSCmdlet.ThrowTerminatingError($errorRecord)
					}
					else
					{
						$policyFile.SetStringValue($Key, $ValueName, $array[0].ToString(), $true)
					}

					break
				}

                ([Microsoft.Win32.RegistryValueKind]::DWord)
				{
					$array = @($Data)
					$dword = ($array | Select-Object -First 1) -as [UInt32]
					if ($null -eq $dword -or $array.Count -ne 1)
					{
						$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'When -Type is set to DWord, -Data must be passed a valid UInt32 value.'
						$PSCmdlet.ThrowTerminatingError($errorRecord)
					}
					else
					{
						$policyFile.SetDWORDValue($key, $ValueName, $dword)
					}

					break
				}

                ([Microsoft.Win32.RegistryValueKind]::QWord)
				{
					$array = @($Data)
					$qword = ($array | Select-Object -First 1) -as [UInt64]
					if ($null -eq $qword -or $array.Count -ne 1)
					{
						$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'When -Type is set to QWord, -Data must be passed a valid UInt64 value.'
						$PSCmdlet.ThrowTerminatingError($errorRecord)
					}
					else
					{
						$policyFile.SetQWORDValue($key, $ValueName, $qword)
					}

					break
				}

                ([Microsoft.Win32.RegistryValueKind]::MultiString)
				{
					$strings = [string[]] @(
						foreach ($item in @($Data))
						{
							$item.ToString()
						}
					)

					$policyFile.SetMultiStringValue($Key, $ValueName, $strings)

					break
				}
			} # switch ($Type)

			$dirty = $true
		}
		catch
		{
			throw
		}
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

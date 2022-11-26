
function GetTargetResourceCommon
{
	param (
		[string] $Path,
		[string] $KeyValueName
	)

	$configuration = @{
		KeyValueName = $KeyValueName
		Ensure = 'Absent'
		Data = $null
		Type = [Microsoft.Win32.RegistryValueKind]::Unknown
	}

	if (Test-Path -LiteralPath $path -PathType Leaf)
	{
		$key, $valueName = ParseKeyValueName $KeyValueName
		$entry = Get-PolicyFileEntry -Path $Path -Key $key -ValueName $valueName

		if ($entry)
		{
			$configuration['Ensure'] = 'Present'
			$configuration['Type'] = $entry.Type
			$configuration['Data'] = @($entry.Data)
		}
	}

	return $configuration
}

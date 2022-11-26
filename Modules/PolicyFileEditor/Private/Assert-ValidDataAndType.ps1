
function Assert-ValidDataAndType
{
	param (
		[string[]] $Data,
		[Microsoft.Win32.RegistryValueKind] $Type
	)

	if ($Type -ne [Microsoft.Win32.RegistryValueKind]::MultiString -and
		$Type -ne [Microsoft.Win32.RegistryValueKind]::Binary -and
		$Data.Count -gt 1)
	{
		$errorRecord = InvalidDataTypeCombinationErrorRecord -Message 'Do not pass arrays with multiple values to the -Data parameter when -Type is not set to either Binary or MultiString.'
		throw $errorRecord
	}
}

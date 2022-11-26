
function TestTargetResourceCommon
{
	[OutputType([bool])]
	param (
		[string] $Path,
		[string] $KeyValueName,
		[string] $Ensure,
		[string[]] $Data,
		[Microsoft.Win32.RegistryValueKind] $Type
	)

	if ($null -eq $Data) { $Data = @() }

	try
	{
		Assert-ValidDataAndType -Data $Data -Type $Type
	}
	catch
	{
		Write-Error -ErrorRecord $_
		return $false
	}

	$key, $valueName = ParseKeyValueName $KeyValueName

	$fileExists = Test-Path -LiteralPath $Path -PathType Leaf

	if ($Ensure -eq 'Present')
	{
		if (-not $fileExists) { return $false }
		$entry = Get-PolicyFileEntry -Path $Path -Key $key -ValueName $valueName

		return $null -ne $entry -and $Type -eq $entry.Type -and (DataIsEqual $entry.Data $Data -Type $Type)
	}
	else # Ensure is 'Absent'
	{
		if (-not $fileExists) { return $true }
		$entry = Get-PolicyFileEntry -Path $Path -Key $key -ValueName $valueName

		return $null -eq $entry
	}
}

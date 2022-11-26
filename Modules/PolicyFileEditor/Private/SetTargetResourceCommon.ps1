
function SetTargetResourceCommon
{
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
		return
	}

	$key, $valueName = ParseKeyValueName $KeyValueName

	if ($Ensure -eq 'Present')
	{
		Set-PolicyFileEntry -Path $Path -Key $key -ValueName $valueName -Data $Data -Type $Type
	}
	else
	{
		Remove-PolicyFileEntry -Path $Path -Key $key -ValueName $valueName
	}
}

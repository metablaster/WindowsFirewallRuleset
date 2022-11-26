
function DataIsEqual
{
	param (
		[object] $First,
		[object] $Second,
		[Microsoft.Win32.RegistryValueKind] $Type
	)

	if ($Type -eq [Microsoft.Win32.RegistryValueKind]::String -or
		$Type -eq [Microsoft.Win32.RegistryValueKind]::ExpandString -or
		$Type -eq [Microsoft.Win32.RegistryValueKind]::DWord -or
		$Type -eq [Microsoft.Win32.RegistryValueKind]::QWord)
	{
		return @($First)[0] -ceq @($Second)[0]
	}

	# If we get here, $Type is either MultiString or Binary, both of which need to compare arrays.
	# The PolicyFileEditor module never returns type Unknown or None.

	$First = @($First)
	$Second = @($Second)

	if ($First.Count -ne $Second.Count) { return $false }

	$count = $First.Count
	for ($i = 0; $i -lt $count; $i++)
	{
		if ($First[$i] -cne $Second[$i]) { return $false }
	}

	return $true
}

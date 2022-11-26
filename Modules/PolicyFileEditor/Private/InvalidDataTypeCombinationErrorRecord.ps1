
function InvalidDataTypeCombinationErrorRecord($Message)
{
	$exception = New-Object System.Exception($Message)
	return New-Object System.Management.Automation.ErrorRecord(
		$exception, 'InvalidDataTypeCombination', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null
	)
}

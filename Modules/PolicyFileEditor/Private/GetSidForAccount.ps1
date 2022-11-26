
function GetSidForAccount($Account)
{
	$acc = $Account
	if ($acc -notlike '*\*') { $acc = "$env:COMPUTERNAME\$acc" }

	try
	{
		$ntAccount = [System.Security.Principal.NTAccount]$acc
		return $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
	}
	catch
	{
		$message = "Could not translate account '$acc' to a security identifier."
		$exception = New-Object System.Exception($message, $_.Exception)
		$errorRecord = New-Object System.Management.Automation.ErrorRecord(
			$exception,
			'CouldNotGetSidForAccount',
			[System.Management.Automation.ErrorCategory]::ObjectNotFound,
			$Acc
		)

		throw $errorRecord
	}
}

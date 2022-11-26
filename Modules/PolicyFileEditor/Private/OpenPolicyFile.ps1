
function OpenPolicyFile
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Path
	)

	$policyFile = New-Object TJX.PolFileEditor.PolFile
	$policyFile.FileName = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)

	if (Test-Path -LiteralPath $policyFile.FileName)
	{
		try
		{
			$policyFile.LoadFile()
		}
		catch [TJX.PolFileEditor.FileFormatException]
		{
			$message = "File '$Path' is not a valid POL file."
			$exception = New-Object System.Exception($message)

			$errorRecord = New-Object System.Management.Automation.ErrorRecord(
				$exception, 'InvalidPolFileContents', [System.Management.Automation.ErrorCategory]::InvalidData, $Path
			)

			throw $errorRecord
		}
		catch
		{
			$errorRecord = $_
			$message = "Error loading policy file at path '$Path': $($errorRecord.Exception.Message)"
			$exception = New-Object System.Exception($message, $errorRecord.Exception)

			$newErrorRecord = New-Object System.Management.Automation.ErrorRecord(
				$exception, 'FailedToOpenPolicyFile', [System.Management.Automation.ErrorCategory]::OperationStopped, $Path
			)

			throw $newErrorRecord
		}
	}

	return $policyFile
}

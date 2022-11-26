
function SavePolicyFile
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[TJX.PolFileEditor.PolFile] $PolicyFile,

		[switch] $UpdateGptIni
	)

	if ($PSCmdlet.ShouldProcess($PolicyFile.FileName, 'Save new settings'))
	{
		$parentPath = Split-Path $PolicyFile.FileName -Parent
		if (-not (Test-Path -LiteralPath $parentPath -PathType Container))
		{
			try
			{
				$null = New-Item -Path $parentPath -ItemType Directory -ErrorAction Stop -Confirm:$false -WhatIf:$false
			}
			catch
			{
				$errorRecord = $_
				$message = "Error creating parent folder of path '$Path': $($errorRecord.Exception.Message)"
				$exception = New-Object System.Exception($message, $errorRecord.Exception)

				$newErrorRecord = New-Object System.Management.Automation.ErrorRecord(
					$exception, 'CreateParentFolderError', $errorRecord.CategoryInfo.Category, $Path
				)

				throw $newErrorRecord
			}
		}

		try
		{
			$PolicyFile.SaveFile()
		}
		catch
		{
			$errorRecord = $_
			$message = "Error saving policy file to path '$($PolicyFile.FileName)': $($errorRecord.Exception.Message)"
			$exception = New-Object System.Exception($message, $errorRecord.Exception)

			$newErrorRecord = New-Object System.Management.Automation.ErrorRecord(
				$exception, 'FailedToSavePolicyFile', [System.Management.Automation.ErrorCategory]::OperationStopped, $PolicyFile
			)

			throw $newErrorRecord
		}
	}

	if ($UpdateGptIni)
	{
		if ($policyFile.FileName -match '^(.*)\\+([^\\]+)\\+[^\\]+$' -and
			$Matches[2] -eq 'User' -or $Matches[2] -eq 'Machine')
		{
			$iniPath = Join-Path $Matches[1] GPT.ini

			if (Test-Path -LiteralPath $iniPath -PathType Leaf)
			{
				if ($PSCmdlet.ShouldProcess($iniPath, 'Increment version number in INI file'))
				{
					IncrementGptIniVersion -Path $iniPath -PolicyType $Matches[2] -Confirm:$false -WhatIf:$false
				}
			}
			else
			{
				if ($PSCmdlet.ShouldProcess($iniPath, 'Create new gpt.ini file'))
				{
					NewGptIni -Path $iniPath -PolicyType $Matches[2]
				}
			}
		}
	}
}

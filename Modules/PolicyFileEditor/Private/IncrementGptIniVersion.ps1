
function IncrementGptIniVersion
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string] $Path,
		[string[]] $PolicyType
	)

	$foundVersionLine = $false
	$section = ''

	$newContents = @(
		foreach ($line in Get-Content $Path)
		{
			# This might not be the most unreadable regex ever, but it's trying hard to be!
			# It's looking for section lines:  [SectionName]
			if ($line -match '^\s*\[([^\]]+)\]\s*$')
			{
				if ($section -eq 'General')
				{
					if (-not $foundVersionLine)
					{
						$foundVersionLine = $true
						$newVersion = GetNewVersionNumber -Version 0 -PolicyType $PolicyType

						"Version=$newVersion"
					}

					if (-not $foundMachineExtensionLine)
					{
						$foundMachineExtensionLine = $true
						"gPCMachineExtensionNames=$script:MachineExtensionGuids"
					}

					if (-not $foundUserExtensionLine)
					{
						$foundUserExtensionLine = $true
						"gPCUserExtensionNames=$script:UserExtensionGuids"
					}
				}

				$section = $matches[1]
			}
			elseif ($section -eq 'General' -and
				$line -match '^\s*Version\s*=\s*(\d+)\s*$' -and
				$null -ne ($version = $matches[1] -as [uint32]))
			{
				$foundVersionLine = $true
				$newVersion = GetNewVersionNumber -Version $version -PolicyType $PolicyType
				$line = "Version=$newVersion"
			}
			elseif ($section -eq 'General' -and $line -match '^\s*gPC(Machine|User)ExtensionNames\s*=')
			{
				if ($matches[1] -eq 'Machine')
				{
					$foundMachineExtensionLine = $true
				}
				else
				{
					$foundUserExtensionLine = $true
				}

				$line = EnsureAdminTemplateCseGuidsArePresent $line
			}

			$line
		}

		if ($section -eq 'General')
		{
			if (-not $foundVersionLine)
			{
				$foundVersionLine = $true
				$newVersion = GetNewVersionNumber -Version 0 -PolicyType $PolicyType

				"Version=$newVersion"
			}

			if (-not $foundMachineExtensionLine)
			{
				$foundMachineExtensionLine = $true
				"gPCMachineExtensionNames=$script:MachineExtensionGuids"
			}

			if (-not $foundUserExtensionLine)
			{
				$foundUserExtensionLine = $true
				"gPCUserExtensionNames=$script:UserExtensionGuids"
			}
		}
	)

	if ($PSCmdlet.ShouldProcess($Path, 'Increment Version number'))
	{
		Set-Content -Path $Path -Value $newContents -Encoding Ascii -Confirm:$false -WhatIf:$false
	}
}


function NewGptIni
{
	param (
		[string] $Path,
		[string[]] $PolicyType
	)

	$parent = Split-Path $Path -Parent

	if (-not (Test-Path $parent -PathType Container))
	{
		$null = New-Item -Path $parent -ItemType Directory -ErrorAction Stop
	}

	$version = GetNewVersionNumber -Version 0 -PolicyType $PolicyType

	Set-Content -Path $Path -Encoding Ascii -Value @"
[General]
gPCMachineExtensionNames=$script:MachineExtensionGuids
Version=$version
gPCUserExtensionNames=$script:UserExtensionGuids
"@
}


function EnsureAdminTemplateCseGuidsArePresent
{
	param ([string] $Line)

	# These lines contain pairs of GUIDs in "registry" format (with the curly braces), separated by nothing, with
	# each pair of GUIDs wrapped in square brackets.  Example:

	# gPCMachineExtensionNames=[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}]

	# Per Darren Mar-Elia, these GUIDs must be in alphabetical order, or GP processing will have problems.

	if ($Line -notmatch '\s*(gPC(?:Machine|User)ExtensionNames)\s*=\s*(.*)$')
	{
		throw "Malformed gpt.ini line: $Line"
	}

	$valueName = $matches[1]
	$guidStrings = @($matches[2] -split '(?<=\])(?=\[)')

	if ($matches[1] -eq 'gPCMachineExtensionNames')
	{
		$toolExtensionGuid = $script:MachineExtensionGuids
	}
	else
	{
		$toolExtensionGuid = $script:UserExtensionGuids
	}

	$guidList = @(
		$guidStrings
		$toolExtensionGuid
	)

	$newGuidString = ($guidList | Sort-Object -Unique) -join ''

	return "$valueName=$newGuidString"
}

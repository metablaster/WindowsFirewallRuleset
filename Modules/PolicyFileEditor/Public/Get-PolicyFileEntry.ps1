
<#
.SYNOPSIS
Retrieves the current setting(s) from a .pol file.

.DESCRIPTION
Retrieves the current setting(s) from a .pol file.

.PARAMETER Path
Path to the .pol file that is to be read.

.PARAMETER Key
The registry key inside the .pol file that you want to read.

.PARAMETER ValueName
The name of the registry value.
May be set to an empty string to read the default value of a key.

.PARAMETER All
Switch indicating that all entries from the specified .pol file should be output,
instead of searching for a specific key\ValueName pair.

.EXAMPLE
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue

Reads the value of Software\Policies\Something\SomeValue from the Machine admin templates of the local GPO.
Either returns an object with the data and type of this registry value (if present),
or returns nothing, if not found.

.EXAMPLE
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol -All

Outputs all of the registry values from the local machine Administrative Templates

.INPUTS
None. This command does not accept pipeline input.

.OUTPUTS
If the specified registry value is found, the function outputs a PSCustomObject with the following properties:
ValueName: The same value that was passed to the -ValueName parameter
Key: The same value that was passed to the -Key parameter
Data: The current value assigned to the specified Key\ValueName in the .pol file.
Type: The RegistryValueKind type of the specified Key\ValueName in the .pol file.
If the specified registry value is not found in the .pol file, the command returns nothing. No error is produced.

.NOTES
None.
#>
function Get-PolicyFileEntry
{
	[CmdletBinding(DefaultParameterSetName = 'ByKeyAndValue')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByKeyAndValue')]
		[string] $Key,

		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'ByKeyAndValue')]
		[string] $ValueName,

		[Parameter(Mandatory = $true, ParameterSetName = 'All')]
		[switch] $All
	)

	if (Get-Command [G]et-CallerPreference -CommandType Function -Module PreferenceVariables)
	{
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}

	try
	{
		$policyFile = OpenPolicyFile -Path $Path -ErrorAction Stop
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}

	if ($PSCmdlet.ParameterSetName -eq 'ByKeyAndValue')
	{
		$entry = $policyFile.GetValue($Key, $ValueName)

		if ($null -ne $entry)
		{
			PolEntryToPsObject -PolEntry $entry
		}
	}
	else
	{
		foreach ($entry in $policyFile.Entries)
		{
			PolEntryToPsObject -PolEntry $entry
		}
	}
}

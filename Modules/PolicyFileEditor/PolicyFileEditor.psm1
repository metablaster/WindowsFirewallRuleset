
#region Initialization
param (
	[Parameter()]
	[switch] $ListPreference
)

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$dllPath = Join-Path $scriptRoot PolFileEditor.dll
Add-Type -Path $dllPath -ErrorAction Stop

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule -ListPreference:$ListPreference

if ($ListPreference)
{
	# NOTE: Preferences defined in caller scope are not inherited, only those defined in
	# Config\ProjectSettings.ps1 are pulled into module scope
	Write-Debug -Message "[$ThisModule] InformationPreference in module: $InformationPreference" -Debug
	Show-Preference # -All
	Remove-Module -Name Dynamic.Preference
}
#endregion

#
# Script imports
#

$PrivateScripts = @(
	"Assert-ValidDataAndType"
	"DataIsEqual"
	"EnsureAdminTemplateCseGuidsArePresent"
	"GetEntryData"
	"GetNewVersionNumber"
	"GetPolFilePath"
	"GetSidForAccount"
	"GetTargetResourceCommon"
	"IncrementGptIniVersion"
	"InvalidDataTypeCombinationErrorRecord"
	"NewGptIni"
	"OpenPolicyFile"
	"ParseKeyValueName"
	"PolEntryToPsObject"
	"PolEntryTypeToRegistryValueKind"
	"SavePolicyFile"
	"SetTargetResourceCommon"
	"TestTargetResourceCommon"
	"UInt16PairToUInt32"
	"UInt32ToUInt16Pair"
)

foreach ($Script in $PrivateScripts)
{
	try
	{
		. "$PSScriptRoot\Private\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Private\$Script.ps1' $($_.Exception.Message)"
	}
}

$PublicScripts = @(
	"Get-PolicyFileEntry"
	"Get-PolicyFileEntry"
	"Set-PolicyFileEntry"
	"Update-GptIniVersion"
)

foreach ($Script in $PublicScripts)
{
	try
	{
		. "$PSScriptRoot\Public\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Public\$Script.ps1' $($_.Exception.Message)"
	}
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

New-Variable -Name MachineExtensionGuids -Scope Script -Value "[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}]"
New-Variable -Name UserExtensionGuids -Scope Script -Value "[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}]"

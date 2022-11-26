
function PolEntryToPsObject
{
	param (
		[TJX.PolFileEditor.PolEntry] $PolEntry
	)

	$type = PolEntryTypeToRegistryValueKind $PolEntry.Type
	$data = GetEntryData -Entry $PolEntry -Type $type

	return New-Object psobject -Property @{
		Key = $PolEntry.KeyName
		ValueName = $PolEntry.ValueName
		Type = $type
		Data = $data
	}
}

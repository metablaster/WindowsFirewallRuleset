
function ParseKeyValueName
{
	param ([string] $KeyValueName)

	$key = $KeyValueName -replace '^\\+|\\+$'
	$valueName = ''

	if ($KeyValueName -match '^\\*(?<Key>.+?)\\+(?<ValueName>[^\\]*)$')
	{
		$key = $matches['Key'] -replace '\\{2,}', '\'
		$valueName = $matches['ValueName']
	}

	return $key, $valueName
}

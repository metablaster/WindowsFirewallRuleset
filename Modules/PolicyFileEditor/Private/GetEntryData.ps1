
function GetEntryData
{
	param (
		[TJX.PolFileEditor.PolEntry] $Entry,
		[Microsoft.Win32.RegistryValueKind] $Type
	)

	switch ($type)
	{
        ([Microsoft.Win32.RegistryValueKind]::Binary)
		{
			return $Entry.BinaryValue
		}

        ([Microsoft.Win32.RegistryValueKind]::DWord)
		{
			return $Entry.DWORDValue
		}

        ([Microsoft.Win32.RegistryValueKind]::ExpandString)
		{
			return $Entry.StringValue
		}

        ([Microsoft.Win32.RegistryValueKind]::MultiString)
		{
			return $Entry.MultiStringValue
		}

        ([Microsoft.Win32.RegistryValueKind]::QWord)
		{
			return $Entry.QWORDValue
		}

        ([Microsoft.Win32.RegistryValueKind]::String)
		{
			return $Entry.StringValue
		}
	}
}

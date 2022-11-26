
function PolEntryTypeToRegistryValueKind
{
	param ([TJX.PolFileEditor.PolEntryType] $PolEntryType)

	switch ($PolEntryType)
	{
        ([TJX.PolFileEditor.PolEntryType]::REG_NONE)
		{
			return [Microsoft.Win32.RegistryValueKind]::None
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_DWORD)
		{
			return [Microsoft.Win32.RegistryValueKind]::DWord
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_DWORD_BIG_ENDIAN)
		{
			return [Microsoft.Win32.RegistryValueKind]::DWord
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_BINARY)
		{
			return [Microsoft.Win32.RegistryValueKind]::Binary
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_EXPAND_SZ)
		{
			return [Microsoft.Win32.RegistryValueKind]::ExpandString
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_MULTI_SZ)
		{
			return [Microsoft.Win32.RegistryValueKind]::MultiString
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_QWORD)
		{
			return [Microsoft.Win32.RegistryValueKind]::QWord
		}

        ([TJX.PolFileEditor.PolEntryType]::REG_SZ)
		{
			return [Microsoft.Win32.RegistryValueKind]::String
		}
	}
}

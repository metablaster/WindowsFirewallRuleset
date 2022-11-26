
function GetPolFilePath
{
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'PolicyType')]
		[string] $PolicyType,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[string] $Account
	)

	if ($PolicyType)
	{
		switch ($PolicyType)
		{
			'Machine'
			{
				return Join-Path $env:SystemRoot System32\GroupPolicy\Machine\registry.pol
			}

			'User'
			{
				return Join-Path $env:SystemRoot System32\GroupPolicy\User\registry.pol
			}

			'Administrators'
			{
				# BUILTIN\Administrators well-known SID
				return Join-Path $env:SystemRoot System32\GroupPolicyUsers\S-1-5-32-544\User\registry.pol
			}

			'NonAdministrators'
			{
				# BUILTIN\Users well-known SID
				return Join-Path $env:SystemRoot System32\GroupPolicyUsers\S-1-5-32-545\User\registry.pol
			}
		}
	}
	else
	{
		try
		{
			$sid = $Account -as [System.Security.Principal.SecurityIdentifier]

			if ($null -eq $sid)
			{
				$sid = GetSidForAccount $Account
			}

			return Join-Path $env:SystemRoot "System32\GroupPolicyUsers\$($sid.Value)\User\registry.pol"
		}
		catch
		{
			throw
		}
	}
}

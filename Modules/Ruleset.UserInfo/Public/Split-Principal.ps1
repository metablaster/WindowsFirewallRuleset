
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Split principal to either user name or domain

.DESCRIPTION
Split principal, either UPN or NETBIOS name to user name or domain name

.PARAMETER Principal
One or more principals in form of UPN or NetBIOS Name.

.PARAMETER DomainName
If specified, the result is domain name instead of user name

.EXAMPLE
PS> Split-Principal COMPUTERNAME\USERNAME

.EXAMPLE
PS> @(SERVER\USER, user@domain.lan, SERVER2\USER2) | Split-Principal -DomainName

.INPUTS
[string]

.OUTPUTS
[string]

.NOTES
None.
#>
function Split-Principal
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Split-Principal.md")]
	[OutputType([string])]
	param(
		[Alias("Account")]
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[string[]] $Principal,

		[Parameter()]
		[switch] $DomainName
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Account in $Principal)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user name for account: $Account"

			# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d
			if ($Account -match "^\w[-|\w|\s]*\w\\\w[\s|\w]*\w$")
			{
				if ($DomainName) { $Index = 0 }
				else { $Index = 1 }

				$Account.Split("\")[$Index]
			}
			elseif (Test-UPN $Account -EA SilentlyContinue)
			{
				if ($DomainName) { $Index = 1 }
				else { $Index = 0 }

				# https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
				$Account.Split("@")[$Index]
			}
			else
			{
				# TODO: Test-NBUserName would make this redundant
				Write-Error -Category InvalidArgument -TargetObject $Account `
					-Message "The account '$Account' is not a valid principal name"
			}
		}
	}
}

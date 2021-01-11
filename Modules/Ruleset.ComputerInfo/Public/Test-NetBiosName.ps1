
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Validate NETBIOS name syntax

.DESCRIPTION
Test if NETBIOS computer name and/or user name has correct syntax

.PARAMETER Name
Computer NETBIOS name which is to be checked

.PARAMETER Target
Specifies the kind of name checking to perform on -Name parameter as follows:

- User: Name parameter is logon name
- Domain: Name parameter is domain name
- Principal: Name parameter is in form of DOMAIN\USERNAME

The default is Principal.

.PARAMETER Strict
If specified, domain name must conform to IBM specifications.
By default verification conforms only to Microsoft specifications.
This switch is experimental.

.PARAMETER Quiet
If specified, name syntax errors are not shown, only true or false is returned.

.PARAMETER Force
If specified, domain name isn't checked against reserved words

.EXAMPLE
PS> Test-NetBiosName "*SERVER" -Target Domain
False

.EXAMPLE
PS> Test-NetBiosName "-SERVER-01" -Quiet -Strict -Target Domain
True

.EXAMPLE
PS> Test-NetBiosName "-Server-01\UserName"
True

.EXAMPLE
PS> Test-NetBiosName "User+Name" -Target User -Strict -Quiet
False

.INPUTS
[string[]]

.OUTPUTS
[bool]

.NOTES
According to Microsoft:
NetBIOS computer names can't contain the following characters \ / : * ? " < > |
Computers names can contain a period (.) but the name can't start with a period.
Computers that are members of an AD domain can't have names that are composed completely of numbers
Computer name must not be reserved word.
Minimum computer name length: 1 character
Maximum computer name length: 15 characters
Logon names can be up to 104 characters.
However, it isn't practical to use logon names that are longer than 64 characters.
Logon names can't contain following characters " / \ [ ] : ; | = , + * ? < >
Logon names can contain all other special characters, including spaces, periods, dashes, and underscores.
But it's generally not a good idea to use spaces in account names.

According to IBM:
NetBIOS names are always converted to uppercase when sent to other
systems, and may consist of any character, except:
- Any character less than a space (0x20)
- the characters " . / \ [ ] : | < > + = ; ,
The name should not start with an asterisk (*)
The NetBIOS name is 16 ASCII characters, however Microsoft limits the host name to 15 characters and
reserves the 16th character as a NetBIOS Suffix

Microsoft allows the dot, while IBM does not
Space character may work on Windows system as well even though it's not allowed, it may be useful
for domains such as NT AUTHORITY\NETWORK SERVICE
Important to understand is, the choice of name used by a higher-layer protocol or application is up
to that protocol or application and not NetBIOS.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d

.LINK
http://www.asciitable.com/

.LINK
https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou

.LINK
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10)

.LINK
https://en.wikipedia.org/wiki/NetBIOS
#>
function Test-NetBiosName
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string[]] $Name,

		[Parameter()]
		[ValidateSet("Domain", "User", "Principal")]
		[string] $Target = "Principal",

		[Parameter()]
		[switch] $Strict,

		[Parameter()]
		[switch] $Quiet,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# Reserved computer name
		$ReservedName = @(
			"ANONYMOUS"
			"AUTHENTICATED USER"
			"BATCH"
			"BUILTIN"
			"CREATOR GROUP"
			"CREATOR GROUP SERVER"
			"CREATOR OWNER"
			"CREATOR OWNER SERVER"
			"DIALUP"
			"DIGEST AUTH"
			"INTERACTIVE"
			"INTERNET"
			"LOCAL"
			"LOCAL SYSTEM"
			"NETWORK"
			"NETWORK SERVICE"
			"NT AUTHORITY"
			"NT DOMAIN"
			"NTLM AUTH"
			"NULL"
			"PROXY"
			"REMOTE INTERACTIVE"
			"RESTRICTED"
			"SCHANNEL AUTH"
			"SELF"
			"SERVER"
			"SERVICE"
			"SYSTEM"
			"TERMINAL SERVER"
			"THIS ORGANIZATION"
			"USERS"
			"WORLD"
		)

		if ($Quiet)
		{
			$WriteError = "SilentlyContinue"
		}
		else
		{
			$WriteError = $ErrorActionPreference
		}

		if ($Strict)
		{
			[regex] $BadDomain = '[".\\/\[\]:|<>+=;,\s]'
		}
		else
		{
			[regex] $BadDomain = '[\\/:*?"<>|]'
		}

		[regex] $BadLogon = '["/\\\[\]:;|=,+*?<>]'
		[regex] $NameRegex = "^(?<domain>.+(?=\\))(?<separator>\\)(?<user>.+)$"
	}
	process
	{
		foreach ($NameEntry in $Name)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing NETBIOS name: '$NameEntry'"

			[string] $UserName = $null
			[string] $DomainName = $null

			if ($Target -eq "Principal")
			{
				$FullName = $NameRegex.Match($NameEntry)

				if ($FullName.Success)
				{
					# $Separator = $FullName.Groups["separator"]
					$Domain = $FullName.Groups["domain"]
					$User = $FullName.Groups["user"]
				}
				else
				{
					Write-Error -Category InvalidArgument -TargetObject $NameEntry -ErrorAction $WriteError `
						-Message "Specified NETBIOS name '$NameEntry' is not a valid principal name"
					Write-Output $false
					continue
				}

				$UserName = $User.Value
				$DomainName = $Domain.Value
			}
			elseif ($Target -eq "Domain")
			{
				$DomainName = $NameEntry
			}
			else
			{
				$UserName = $NameEntry
			}

			if ($Target -ne "User")
			{
				if ($DomainName.StartsWith("."))
				{
					Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
						-Message "NETBIOS computer name '$DomainName' must not begin with period (.)"
					Write-Output $false
					continue
				}

				$BadMatch = $BadDomain.Match($DomainName)
				if ($BadMatch.Success)
				{
					Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
						-Message "NETBIOS computer name '$DomainName' contains invalid character '$($BadMatch.Value)'"
					Write-Output $false
					continue
				}

				if ($DomainName.Length -gt 15)
				{
					Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
						-Message "NETBIOS computer name '$DomainName' is $($DomainName.Length) characters long, but limit is 15 characters"
					Write-Output $false
					continue
				}

				if ($Strict)
				{
					if ($DomainName.StartsWith("*"))
					{
						Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
							-Message "NETBIOS computer name '$DomainName' must not begin with an asterisk (*)"
						Write-Output $false
						continue
					}

					$CharArray = $DomainName.ToCharArray()
					for ($Index = 0; $Index -lt $CharArray.Count; ++$Index)
					{
						# ASCII decimal 32 is SPACE
						if ([byte][char] $CharArray[$Index] -lt 32)
						{
							Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
								-Message "NETBIOS name '$DomainName' contains non printable character '$($CharArray[$Index])' at position ($Index)"
							Write-Output $false
							continue
						}
					}
				}

				if (!$Force -and ($ReservedName -contains $DomainName))
				{
					Write-Error -Category SyntaxError -TargetObject $DomainName -ErrorAction $WriteError `
						-Message "NETBIOS computer name '$DomainName' is reserved word"
					Write-Output $false
					continue
				}

				$BadMatch = [regex]::Match($DomainName, "^\d+$")
				if ($BadMatch.Success)
				{
					Write-Warning -Message "NETBIOS computer name '$DomainName' is not valid for AD membership"
				}
			}

			if ($Target -ne "Domain")
			{
				$BadMatch = $BadLogon.Match($UserName)
				if ($BadMatch.Success)
				{
					Write-Error -Category SyntaxError -TargetObject $UserName -ErrorAction $WriteError `
						-Message "NETBIOS user name '$UserName' contains invalid character '$($BadMatch.Value)'"
					Write-Output $false
					continue
				}

				if ($UserName.Length -gt 104)
				{
					Write-Error -Category SyntaxError -TargetObject $UserName -ErrorAction $WriteError `
						-Message "NETBIOS user name '$UserName' is $($UserName.Length) characters long, but limit is 104 characters"
					Write-Output $false
					continue
				}

				if ($UserName.Length -gt 64)
				{
					Write-Warning -Message "NETBIOS user name '$UserName' isn't practical to use because it's longer than 64 characters"
				}

				if ($UserName.Contains(" "))
				{
					Write-Warning -Message "NETBIOS user name '$UserName' it's generally not a good idea to use spaces in account names"
				}
			}

			Write-Output $true
		}
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Validate DNS domain name syntax

.DESCRIPTION
Test if DNS domain name has correct syntax.
The validation is valid at Windows 2000 DNS and the Windows Server 2003 DNS and later Windows
systems in Active Direcotry.

.PARAMETER Name
DNS domain name which is to be checked

.PARAMETER Strict
If specified, unicode characters are not valid.
By default unicode characters are valid for systems mentioned in description.

.PARAMETER Quiet
If specified, syntax errors are not shown, only true or false is returned.

.PARAMETER Force
If specified, domain name isn't checked against reserved words

.EXAMPLE
PS> Test-DnsName

Repeat ".EXAMPLE" keyword for each example.

.INPUTS
[string[]]

.OUTPUTS
[bool]

.NOTES
TODO: Following are syntax rules which need to be implemented:
DNS names can contain only alphabetical characters (A-Z), numeric characters (0-9),
the minus sign (-), and the period (.)
Period characters are allowed only when they are used to delimit the components of domain style names.

In the Windows 2000 domain name system (DNS) and the Windows Server 2003 DNS, Unicode characters are supported.
Other implementations of DNS don't support Unicode characters.

DNS domain names can't contain the following characters:
, ~ : ! @ # $ % ^ & ' . ( ) { } _ SPACE

The underscore has a special role. It's permitted for the first character in SRV records by RFC definition.
But newer DNS servers may also allow it anywhere in a name.
All characters preserve their case formatting except for ASCII characters.
The first character must be alphabetical or numeric.
The last character must not be a minus sign or a period.
Minimum name length: 2 characters
Maximum name length: 255 characters
The maximum length of the host name and of the fully qualified domain name (FQDN) is 63 bytes per label and 255 characters per FQDN.
The latter is based on the maximum path length possible with an Active Directory Domain name with the
paths needed in SYSVOL, and it needs to obey to the 260 character MAX_PATH limitation.

An example path in SYSVOL contains:
\\<FQDN domain name>\sysvol\<FQDN domain name>\policies\{<policy GUID>}\[user|machine]\<CSE-specific path>

Single-label DNS names can't be registered by using an Internet registrar.
The DNS Server service may not be used to locate domain controllers in domains that have single-label DNS names.
Don't use top-level Internet domain names on the intranet, such as .com, .net, and .org.
TODO: There a best practices list on MS site, for which we should generate a warning.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-DnsName.md

.LINK
https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou

.LINK
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10)
#>
function Test-DnsName
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSUseDeclaredVarsMoreThanAssignments", "", Scope = "Function", Justification = "This function lacks implementation")]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-DnsName.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $Name,

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

		if ($Quiet)
		{
			$WriteError = "SilentlyContinue"
		}
		else
		{
			$WriteError = $ErrorActionPreference
		}

		[regex] $BadRegex = "[,~:!@#$%^&'.(){}_\s]"
		# TODO: This is for FQDN, but it may be shorter or lacking some parts
		[regex] $NameRegex = "^(?<domain1>\\\\.+(?=\\))(?<separator>\\)(?<sysvol>.+(?=\\))(?<separator>\\)(?<domain2>.+(?=\\))(?<separator>\\)(?<policies>.+(?=\\))(?<separator>\\)(?<guid>.+(?=\\))(?<separator>\\)(?<user>.+(?=\\))(?<separator>\\)(?<cse>.+)$"
	}

	process
	{
		foreach ($DnsName in $Name)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing NETBIOS name: '$NameEntry'"

			[string] $DomainName1 = $null
			[string] $Sysvol = $null
			[string] $DomainName2 = $null
			[string] $Policies = $null
			[string] $GUID = $null
			[string] $UserName = $null
			[string] $CSE = $null

			Write-Output $true
		}
	}
}

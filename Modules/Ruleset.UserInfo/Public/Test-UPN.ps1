
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Validate Universal Principal Name syntax

.DESCRIPTION
Test if Universal Principal Name (UPN) has valid syntax.
UPN consists of user account name, also known as the logon name and
UPN suffix, also known as the domain name. (or an IP address)

.PARAMETER Name
Universal Principal Name in form of: user@domain.com
If -Prefix is specified, domain name can be omitted.
If -Suffix is specified, logon name can be omitted.

.PARAMETER Prefix
If specified, validate only the user name portion of a User Principal Name

.PARAMETER Suffix
If specified, validate only the domain name portion of a User Principal Name

.PARAMETER Quiet
If specified, UPN syntax errors are not shown, only true or false is returned.

.EXAMPLE
PS> Test-UPN Administrator@machine.lan
True or False

.EXAMPLE
PS> Test-UPN "Use!r" -Prefix
False

.EXAMPLE
PS> Test-UPN "user@192.8.1.1"
False

.EXAMPLE
PS> Test-UPN "user@[192.8.1.1]"
True

.EXAMPLE
PS> Test-UPN "User@site.domain.-com" -Suffix
False

.INPUTS
[string[]]

.OUTPUTS
[bool]

.NOTES
User Principal Name (UPN)
A user account name (sometimes referred to as the user logon name) and a domain name identifying the
domain in which the user account is located.
This is the standard usage for logging on to a Windows domain.
The format is: someone@example.com (as for an email address).
TODO: There is a thing such as: "MicrosoftAccount\TestUser@domain.com"

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md

.LINK
https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
#>
function Test-UPN
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string[]] $Name,

		[Parameter(ParameterSetName = "Prefix")]
		[switch] $Prefix,

		[Parameter(ParameterSetName = "Suffix")]
		[switch] $Suffix,

		[Parameter()]
		[switch] $Quiet
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# Reserved characters that must be escaped: [ ] ( ) . \ ^ $ | ? * + { }
		[regex] $SeparatorRegex = ("@")

		# Invalid characters: ~ ! # $ % ^ & * ( ) + = [ ] { } \ / | ; : " < > ? ,
		[regex] $NameRegex = '(\~|\!|\#|\$|\%|\^|\&|\*|\(|\)|\+|\=|\[|\]|\{|\}|\\|\/|\||\;|\:|"|\<|\>|\?|\,)'

		# DomainRegex break down:
		# TODO: Needs testing and/or simplification
		# NOTE: (?( EXPRESSION ) YES | NO )
		# Matches YES if the regular expression pattern designated by EXPRESSION matches; otherwise, matches the optional NO part.
		# IF: (?(\[)
		# YES (match IP address): (\[
		# (\d{1,3}\.){3}\d{1,3}
		# \])
		# |
		# NO (match ex: site.domain.com): (
		# 	([0-9a-zA-Z][-0-9a-zA-Z]*[0-9a-zA-Z]*\.)+
		#	[0-9a-zA-Z][-0-9a-zA-Z]{0,22}[0-9a-zA-Z]
		# )
		# )$
		[regex] $DomainRegex = "(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-0-9a-zA-Z]*[0-9a-zA-Z]*\.)+[0-9a-zA-Z][-0-9a-zA-Z]{0,22}[0-9a-zA-Z]))$"

		if ($Quiet)
		{
			$WriteError = "SilentlyContinue"
		}
		else
		{
			$WriteError = $ErrorActionPreference
		}
	}
	process
	{
		foreach ($UPN in $Name)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing UPN: '$UPN'"

			$SeparatorCount = $SeparatorRegex.Matches($UPN).Count

			$User = $null
			$Domain = $null

			if ($Prefix)
			{
				if ($SeparatorCount -eq 0)
				{
					$User = $UPN
				}
				elseif ($SeparatorCount -eq 1)
				{
					$User = $UPN.Split("@")[0]
				}
				else
				{
					Write-Error -Category SyntaxError -TargetObject $UPN -ErrorAction $WriteError `
						-Message "Count of separator '@' for user name only validation must be 0 or 1 but $SeparatorCount present: '$UPN'"
					return $false
				}

				if ([string]::IsNullOrEmpty($User))
				{
					Write-Error -Category InvalidArgument -TargetObject $UPN -ErrorAction $WriteError `
						-Message "Unable to validate logon name because it's empty: '$UPN'"
					return $false
				}
			}
			elseif ($Suffix)
			{
				if ($SeparatorCount -eq 0)
				{
					$Domain = $UPN
				}
				elseif ($SeparatorCount -eq 1)
				{
					$Domain = $UPN.Split("@")[1]
				}
				else
				{
					Write-Error -Category SyntaxError -TargetObject $UPN -ErrorAction $WriteError `
						-Message "Count of separator '@' for domain name only validation must be 0 or 1 but $SeparatorCount present: '$UPN'"
					return $false
				}

				if ([string]::IsNullOrEmpty($Domain))
				{
					Write-Error -Category InvalidArgument -TargetObject $UPN -ErrorAction $WriteError `
						-Message "Unable to validate domain name because it's empty: '$UPN'"
					return $false
				}
			}
			elseif ($SeparatorCount -ne 1)
			{
				Write-Error -Category SyntaxError -TargetObject $UPN -ErrorAction $WriteError `
					-Message "Count of separator '@' must be 1 but $SeparatorCount present: '$UPN'"
				return $false
			}
			else
			{
				$User = $UPN.Split("@")[0]
				$Domain = $UPN.Split("@")[1]

				if ([string]::IsNullOrEmpty($User) -or [string]::IsNullOrEmpty($Domain))
				{
					Write-Error -Category InvalidArgument -TargetObject $UPN -ErrorAction $WriteError `
						-Message "Unable to validate UPN because of incomplete UPN: '$UPN'"
					return $false
				}
			}

			if ($User)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Validating user name '$User'"

				# Validate the user name portion of a User Principal Name
				if ($User -match "^(\.|-)|(\.|-)$")
				{
					Write-Error -Category SyntaxError -TargetObject $User -ErrorAction $WriteError `
						-Message "Logon name '$User' must not begin or end with: '.' or '-'"
					return $false
				}
				elseif ($User -match "\.{2,}")
				{
					Write-Error -Category SyntaxError -TargetObject $User -ErrorAction $WriteError `
						-Message "Logon name '$User' must not contain 2 or more subsequent dots '..'"
					return $false
				}
				elseif ($NameRegex.Matches($User).Count -ne 0)
				{
					Write-Error -Category SyntaxError -TargetObject $User -ErrorAction $WriteError `
						-Message "Invalid logon name syntax: '$User'"
					return $false
				}
			}

			if ($Domain)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Validating domain name '$Domain'"

				# Validate the domain name portion of a User Principal Name
				if ($DomainRegex.Matches($Domain).Count -ne 1)
				{
					Write-Error -Category SyntaxError -TargetObject $Domain -ErrorAction $WriteError `
						-Message "Invalid domain name syntax: '$Domain'"
					return $false
				}
			}

			return $true
		}
	}
}

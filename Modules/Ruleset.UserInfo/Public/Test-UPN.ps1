
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Validate User Principal Name

.DESCRIPTION
Validate User Principal Name (UPN) is of valid syntax

.PARAMETER User
Complete User Principal Name.
User account name. Also known as the logon name.
UPN suffix. Also known as the domain name.
If Prefix is specified domain name can be omitted.
If Suffix is specified logon name can be omitted.

.PARAMETER Prefix
If specified, validate only the user name portion of a User Principal Name

.PARAMETER Suffix
If specified, validate only the domain name portion of a User Principal Name

.EXAMPLE
PS> Test-UPN Administrator@machine.lan

.EXAMPLE
PS> Get-GroupPrincipal -Group "Users" | Test-UPN

.INPUTS
[string]

.OUTPUTS
[bool]

.NOTES
TODO: There is a thing such as: "MicrosoftAccount\TestUser@domain.com"
#>
function Test-UPN
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md")]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Alias("UserName")]
		[string[]] $User,

		[Parameter(ParameterSetName = "Prefix")]
		[switch] $Prefix,

		[Parameter(ParameterSetName = "Suffix")]
		[switch] $Suffix
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($UPN in $User)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: '$UPN'"
			$Separator = 0

			foreach ($Char in $UPN.ToCharArray())
			{
				if ($Char -eq "@")
				{
					++$Separator
				}
			}

			$Name = $null
			$Domain = $null

			if ($Prefix -or $Suffix)
			{
				if ($Separator -ne 0)
				{
					Write-Error -Category SyntaxError -TargetObject $User -Message "Count of separator '@' must be 0 but $Separator present"
					return $false
				}
				elseif ($Prefix)
				{
					$Name = $UPN
				}
				else
				{
					$Domain = $UPN
				}
			}
			elseif ($Separator -ne 1)
			{
				Write-Error -Category SyntaxError -TargetObject $User -Message "Count of separator '@' must be 1 but $Separator present"
				return $false
			}
			else
			{
				$Name = $UPN.Split("@")[0]
				$Domain = $UPN.Split("@")[1]
			}

			if ($Name)
			{
				# Validate the user name portion of a User Principal Name
				if ($Name.StartsWith(".") -or $Name.StartsWith("-") -or $Name.EndsWith(".") -or $Name.EndsWith("-"))
				{
					Write-Error -Category SyntaxError -TargetObject $User -Message "Logon name must not begin or end with: '.' or '-'"
					return $false
				}
				elseif ($Name -match "\.\.+")
				{
					Write-Error -Category SyntaxError -TargetObject $User -Message "Logon name must not contain 2 or more subsequent dots '..'"
					return $false
				}
				else
				{
					# Invalid characters: ~ ! # $ % ^ & * ( ) + = [ ] { } \ / | ; : " < > ? ,
					# Reserved characters that must be escaped: [ ] ( ) . \ ^ $ | ? * + { }
					[regex] $Regex = "(\~|\!|\#|\$|\%|\^|\&|\*|\(|\)|\+|\=|\[|\]|\{|\}|\\|\/|\||\;|\:|`"|\<|\>|\?|\,)"

					if ($Regex.Matches($Name).Count -ne 0)
					{
						Write-Error -Category SyntaxError -TargetObject $User -Message "Invalid logon name syntax"
						return $false
					}
				}
			}

			if ($Domain)
			{
				try
				{
					# Validate the domain name portion of a User Principal Name
					# Reserved characters that must be escaped: [ ] ( ) . \ ^ $ | ? * + { }
					[regex] $Regex = "(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-0-9a-zA-Z]*[0-9a-zA-Z]*\.)+[0-9a-zA-Z][-0-9a-zA-Z]{0,22}[0-9a-zA-Z]))$"

					if ($Regex.Matches($Domain).Count -ne 1)
					{
						Write-Error -Category SyntaxError -TargetObject $Domain -Message "Invalid domain name syntax"
						return $false
					}
				}
				catch
				{
					Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
					return $false
				}
			}

			return $true
		}
	}
}


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
Verify NETBIOS name is valid

.DESCRIPTION
Test if NETBIOS computer name has correct syntax

.PARAMETER Name
NETBIOS computer name which to check

.PARAMETER Strict
If specified, name must be all uppercase and must conform to IBM specifications.
By default verification conforms to Microsoft specifications is case insensitive.

.PARAMETER Quiet
if specified errors are not shown, only true or false is returned.

.EXAMPLE
PS> Test-NetBiosName
True

.INPUTS
[string]

.OUTPUTS
[bool]

.NOTES
NetBIOS names are always converted to uppercase when sent to other
systems, and may consist of any character, except:
- Any character less than a space (0x20)
- the characters " . / \ [ ] : | < > + = ; ,
The name should not start with an asterisk (*)

Microsoft allows the dot, while IBM does not
Space character may work on Windows system as well even though it's not allowed, it may be useful
for domains such as NT AUTHORITY\NETWORK SERVICE
Important to understand is, the choice of name used by a higher-layer protocol or application is up
to that protocol or application and not NetBIOS.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d
#>
function Test-NetBiosName
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $Name,

		[Parameter()]
		[switch] $Strict,

		[Parameter()]
		[switch] $Quiet
	)

	begin
	{
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
			# Excludes: white space, dot and name must be uppercase
			[regex] $NameRegex = "^([A-Z0-9\-_]\*?)+$"
		}
		else
		{
			[regex] $NameRegex = "^([A-Z0-9a-z\-_\.\s]\*?)+$"
		}
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($ComputerName in $Name)
		{
			if (!$NameRegex.Match($ComputerName).Success)
			{
				Write-Error -Category SyntaxError -TargetObject $ComputerName -ErrorAction $WriteError `
					-Message "NETBIOS name verification failed for: '$ComputerName'"
				Write-Output $false
				continue
			}

			Write-Output $true
		}
	}
}

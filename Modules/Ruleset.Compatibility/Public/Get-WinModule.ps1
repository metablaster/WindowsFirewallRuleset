
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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
Get a list of the available modules from the compatibility session

.DESCRIPTION
Get a list of the available modules from the compatibility session.
By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session,
a new default session will be created.
This behavior can be overridden using the additional parameters on this command.

.PARAMETER Name
Wildcard pattern to filter module names by

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Credential
The credential to use when creating the compatibility session using the target machine/configuration

.PARAMETER Full
If specified, the complete deserialized module object
will be returned instead of the abbreviated form returned by default.

.EXAMPLE
PS> Get-WinModule *PNP*

Name      Version Description
----      ------- -----------
PnpDevice 1.0.0.0

This example looks for modules in the compatibility session with the string "PNP" in their name.

.INPUTS
None. You cannot pipe objects to Get-WinModule

.OUTPUTS
[PSObject]

.NOTES
Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Get-WinModule.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Get-WinModule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Get-WinModule.md")]
	[OutputType([PSObject])]
	Param (
		[Parameter(Position = 0)]
		[SupportsWildcards()]
		[string[]] $Name = "*",

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[string] $ConfigurationName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
		[switch] $Full
	)

	[bool] $VerboseFlag = $PSBoundParameters["Verbose"]

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Connecting to compatibility session"
	$InitializeWinSessionParameters = @{
		Verbose = $VerboseFlag
		ComputerName = $Domain
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}

	[PSSession] $Session = Initialize-WinSession @InitializeWinSessionParameters

	if ($Name -ne "*")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting the list of available modules matching '$Name'."
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting the list of available modules"
	}

	$PropertiesToReturn = if ($Full) { "*" }
	else { "Name", "Version", "Description" }

	Invoke-Command -Session $Session -ScriptBlock {
		Get-Module -ListAvailable -Name $using:Name |
		Where-Object Name -NotIn $using:NeverImportList |
		Select-Object $using:PropertiesToReturn
	} | Select-Object $PropertiesToReturn | Sort-Object Name
}

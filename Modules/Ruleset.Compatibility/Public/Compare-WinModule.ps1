
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
Compare the set of modules against those in the compatibility session

.DESCRIPTION
Compare the set of modules for this version of PowerShell against those available
in the compatibility session.

.PARAMETER Name
Specifies the names or name patterns of for the modules to compare.
Wildcard characters are supported.

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to
specify the name of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Credential
If needed, use this parameter to specify credentials for the compatibility session

.EXAMPLE
PS> Compare-WinModule

This will return a list of all of the modules available in the compatibility session
that are not currently available in the PowerShell Core environment.

.EXAMPLE
PS> Compare-WinModule A*

This will return a list of all of the compatibility session modules matching the wildcard pattern "A*".

.INPUTS
None. You cannot pipe objects to Compare-WinModule

.OUTPUTS
[PSObject]

.NOTES
Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Added parameter debugging stream

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Compare-WinModule.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Compare-WinModule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Compare-WinModule.md")]
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
		[PSCredential] $Credential
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[bool] $VerboseFlag = $PSBoundParameters["Verbose"]

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Initializing compatibility session"

	$InitializeWinSessionParameters = @{
		Verbose = $VerboseFlag
		ComputerName = $Domain
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}

	[PSSession] $Session = Initialize-WinSession @InitializeWinSessionParameters

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting local modules..."
	$LocalModule = (Get-Module -ListAvailable -Verbose:$false).Where{
		$_.Name -like $Name
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting remote modules..."
	# Use Invoke-Command here instead of the -PSSession option on Get-Module because
	# we're only returning a subset of the data
	$RemoteModule = @(Invoke-Command -Session $Session {
			(Get-Module -ListAvailable).Where{
				$_.Name -notin $using:NeverImportList -and $_.Name -like $using:Name
			} |	Select-Object Name, Version
		})

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Comparing module set..."
	Compare-Object -ReferenceObject $LocalModule -DifferenceObject $RemoteModule -Property Name, Version |
	Where-Object SideIndicator -EQ "=>"
}

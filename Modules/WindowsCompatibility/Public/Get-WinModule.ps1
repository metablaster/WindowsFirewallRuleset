
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
Get a list of the available modules from the compatibility session

.DESCRIPTION
Get a list of the available modules from the compatibility session.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session,
a new default session will be created.
This behavior can be overridden using the additional parameters on this command.

.EXAMPLE
PS> Get-WinModule *PNP*

Name      Version Description
----      ------- -----------
PnpDevice 1.0.0.0

This example looks for modules in the compatibility session with the string 'PNP' in their name.

.INPUTS
None. You cannot pipe objects to Get-WinModule

.OUTPUTS
System.Management.Automation.PSObject

.NOTES
None.
TODO: Update Copyright and start implementing module function
TODO: Update HelpURI
#>
function Get-WinModule
{
	[CmdletBinding()]
	[OutputType([PSObject])]
	Param
	(
		# Pattern to filter module names by
		[Parameter(Mandatory = $false, Position = 0)]
		[String[]]
		$Name = '*',

		# If you don't want to use the default compatibility session, use
		# this parameter to specify the name of the computer on which to create
		# the compatibility session.
		[Alias("cn")]
		[String]
		$ComputerName,

		# Specifies the configuration to connect to when creating the compatibility session
		# (Defaults to 'Microsoft.PowerShell')
		[Parameter()]
		[String]
		$ConfigurationName,

		# The credential to use when creating the compatibility session
		# using the target machine/configuration
		[Parameter()]
		[PSCredential]
		$Credential,

		# If specified, the complete deserialized module object
		# will be returned instead of the abbreviated form returned
		# by default.
		[Parameter()]
		[Switch]
		$Full
	)

	[bool] $verboseFlag = $PSBoundParameters['Verbose']

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Connecting to compatibility session"
	$initializeWinSessionParameters = @{
		Verbose = $verboseFlag
		ComputerName = $ComputerName
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}
	[PSSession] $session = Initialize-WinSession @initializeWinSessionParameters

	if ($name -ne '*')
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting the list of available modules matching '$name'."
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting the list of available modules"
	}

	$propertiesToReturn = if ($Full) { '*' } else { 'Name', 'Version', 'Description' }
	Invoke-Command -Session $session -ScriptBlock {
		Get-Module -ListAvailable -Name $using:Name |
		Where-Object Name -NotIn $using:NeverImportList |
		Select-Object $using:propertiesToReturn
	} | Select-Object $propertiesToReturn |
	Sort-Object Name
}

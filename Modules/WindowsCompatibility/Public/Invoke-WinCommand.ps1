
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
Invoke a ScriptBlock that runs in the compatibility runspace.

.DESCRIPTION
This command takes a ScriptBlock and invokes it in the compatibility session.
Parameters can be passed using the -ArgumentList parameter.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

.EXAMPLE
PS> Invoke-WinCommand {param ($name) "Hello $name, how are you?"; $PSVersionTable.PSVersion} Jeffrey

Hello Jeffrey, how are you?
Major  Minor  Build  Revision PSComputerName
-----  -----  -----  -------- --------------
5      1      17134  1        localhost

In this example, we're invoking a ScriptBlock with 1 parameter in the compatibility session.
This ScriptBlock will simply print a message and then return the version number of the compatibility session.

.EXAMPLE
PS> Invoke-WinCommand {Get-EventLog -Log Application -New 10 }

This examples invokes Get-EventLog in the compatibility session,
returning the 10 newest events in the application log.

.INPUTS
None. You cannot pipe objects to Invoke-WinCommand

.OUTPUTS
System.Management.Automation.PSObject

.NOTES
None.
TODO: Update Copyright and start implementing module function
TODO: Update HelpURI
#>
function Invoke-WinCommand
{
	[CmdletBinding()]
	[OutputType([PSObject])]
	Param
	(
		# The scriptblock to invoke in the compatibility session
		[Parameter(Mandatory, Position = 0)]
		[ScriptBlock]
		$ScriptBlock,

		# If you don't want to use the default compatibility session, use
		# this parameter to specify the name of the computer on which to create
		# the compatibility session.
		[Parameter()]
		[String]
		[Alias("cn")]
		$ComputerName,

		# Specifies the configuration to connect to when creating the compatibility session
		# (Defaults to 'Microsoft.PowerShell')
		[Parameter()]
		[String]
		$ConfigurationName,

		# The credential to use when connecting to the compatibility session.
		[Parameter()]
		[PSCredential]
		$Credential,

		# Arguments to pass to the scriptblock
		[Parameter(ValueFromRemainingArguments)]
		[object[]]
		$ArgumentList
	)

	[void] $PSBoundParameters.Remove('ScriptBlock')
	[void] $PSBoundParameters.Remove('ArgumentList')

	# Make sure the session is initialized
	[PSSession] $session = Initialize-WinSession @PSBoundParameters -PassThru

	# And invoke the scriptblock in the session
	Invoke-Command -Session $session -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
}
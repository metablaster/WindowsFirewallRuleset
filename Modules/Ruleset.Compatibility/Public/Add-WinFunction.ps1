
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
This command defines a global function that always runs in the compatibility session.

.DESCRIPTION
This command defines a global function that always runs in the compatibility session,
returning serialized data to the calling session.
Parameters can be specified using the "param" statement but only positional parameters are supported.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

.PARAMETER Name
The name of the function to define

.PARAMETER ScriptBlock
Scriptblock to use as the body of the function

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Credential
The credential to use when creating the compatibility session using the target machine/configuration

.EXAMPLE
PS> Add-WinFunction myFunction {param ($n) "Hi $n!"; $PSVersionTable.PSEdition }
PS> myFunction Bill

Hi Bill!
Desktop

This example defines a function called "myFunction" with 1 parameter.
When invoked it will print a message then return the PSVersion table from the compatibility session.

.INPUTS
None. You cannot pipe objects to Add-WinFunction

.OUTPUTS
None. Add-WinFunction does not generate any output

.NOTES
Following modifications by metablaster November 2020:
- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Replace double quotes with single quotes
- Added HelpURI link to project location
January 2021:
- Replace cast to [void] with Out-Null

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Add-WinFunction
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WinFunction.md")]
	[OutputType([void])]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("FunctionName")]
		[string] $Name,

		[Parameter(Mandatory = $true, Position = 1)]
		[scriptblock] $ScriptBlock,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[string] $ConfigurationName,

		[Parameter()]
		[PSCredential] $Credential
	)

	# Make sure the session is initialized
	$PSBoundParameters.Remove("Name") | Out-Null
	$PSBoundParameters.Remove("ScriptBlock") | Out-Null

	# the session variable will be captured in the closure
	$Session = Initialize-WinSession @PSBoundParameters -PassThru
	$Wrapper = {
		Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $args
	}

	Set-Item function:Global:$Name $Wrapper.GetNewClosure();
}

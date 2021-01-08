
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
Import a compatibility module

.DESCRIPTION
This command allows you to import proxy modules from a local or remote session.
These proxy modules will allow you to invoke cmdlets that are not directly supported in this version of PowerShell.

There are commands in the Windows PowerShell core modules that don't exist natively in PowerShell Core.
If these modules are imported, proxies will only be created for the missing commands.
Commands that already exist in PowerShell Core will not be overridden.
The modules subject to this restriction are:

- Microsoft.PowerShell.Management
- Microsoft.PowerShell.Utility
- Microsoft.PowerShell.Security
- Microsoft.PowerShell.Diagnostics

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

.PARAMETER Name
Specifies the name of the module to be imported.
Wildcard characters are supported.

.PARAMETER Exclude
A list of wildcard patterns matching the names of modules that should not be imported.

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Prefix
Prefix to prepend to the imported command names

.PARAMETER DisableNameChecking
Disable warnings about non-standard verbs

.PARAMETER NoClobber
Don't overwrite any existing function definitions

.PARAMETER Force
Force reloading the module

.PARAMETER Credential
The credential to use when creating the compatibility session using the target machine/configuration

.PARAMETER PassThru
If present, the ModuleInfo objects will be written to the output pipe
as deserialized (PSObject) objects

.EXAMPLE
PS> Import-WinModule PnpDevice
PS> Get-Command -Module PnpDevice

This example imports the "PnpDevice" module.

.EXAMPLE
PS> Import-WinModule Microsoft.PowerShell.Management; Get-Command Get-EventLog

This example imports one of the core Windows PowerShell modules containing commands
not natively available in PowerShell Core such as "Get-EventLog".
Only commands not already present in PowerShell Core will be imported.

.EXAMPLE
PS> Import-WinModule PnpDevice -Verbose -Force

This example forces a reload of the module "PnpDevice" with verbose output turned on.

.INPUTS
None. You cannot pipe objects to Import-WinModule

.OUTPUTS
[PSObject]

.NOTES
Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Import-WinModule.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Import-WinModule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Import-WinModule.md")]
	[OutputType([PSObject])]
	Param (
		[Parameter(Position = 0)]
		[SupportsWildcards()]
		[string[]] $Name = "*",

		[Parameter()]
		[string[]] $Exclude = "",

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter()]
		[string] $ConfigurationName,

		[Parameter()]
		[string] $Prefix = "",

		[Parameter()]
		[switch] $DisableNameChecking,

		[Parameter()]
		[switch] $NoClobber,

		[Parameter()]
		[switch] $Force,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
		[switch] $PassThru
	)

	[bool] $VerboseFlag = $PSBoundParameters["Verbose"]

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Connecting to compatibility session."
	$InitializeWinSessionParameters = @{
		Verbose = $VerboseFlag
		ComputerName = $Domain
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}

	[PSSession] $Session = Initialize-WinSession @InitializeWinSessionParameters

	# Mapping wildcards to a regex
	$Exclude = ($Exclude -replace "\*", ".*") -join "|"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting module list..."
	$ImportNames = Invoke-Command -Session $Session {
		# Running on the Remote Machine
		$Module = (Get-Module -ListAvailable -Name $using:Name).Where{
			$_.Name -notin $using:NeverImportList
		}

		# These can use wildcards e.g. Az*,x* will probably be common
		if ($using:Exclude)
		{
			$Module = $Module.Where{ $_.Name -NotMatch $using:Exclude }
		}

		$Module.Name | Select-Object -Unique
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Importing modules..."
	$ImportModuleParameters = @{
		Global = $true
		Force = $Force
		Verbose = $VerboseFlag
		PSSession = $Session
		PassThru = $PassThru
		DisableNameChecking = $DisableNameChecking
	}

	if ($Prefix)
	{
		$ImportModuleParameters.Prefix = $Prefix
	}

	if ($PassThru)
	{
		$ImportModuleParameters.PassThru = $PassThru
	}

	if ($ImportNames)
	{
		# Extract the "never clobber" modules from the list
		$NoClobberNames = $ImportNames.Where{ $_ -in $script:NeverClobberList }
		$ImportNames = $ImportNames.Where{ $_ -notin $script:NeverClobberList }

		if ($ImportNames)
		{
			Import-Module -Name $ImportNames -NoClobber:$NoClobber @ImportModuleParameters
		}

		if ($NoClobberNames)
		{
			$ImportModuleParameters.PassThru = $true
			foreach ($name in $NoClobberNames)
			{
				$Module = Import-Module -Name $name -NoClobber @ImportModuleParameters

				# Hack using private reflection to keep the proxy module from shadowing the real module.
				$null = [PSModuleInfo].GetMethod("SetName",
					[System.Reflection.BindingFlags]"Instance, NonPublic").Invoke($Module, @($Module.Name + ".WinModule"))

				if ($PassThru.IsPresent)
				{
					$Module
				}
			}
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] No matching modules were found; nothing was imported"
	}
}

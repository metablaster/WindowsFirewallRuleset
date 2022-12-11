
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

using namespace System.Management.Automation.Runspaces

<#
.SYNOPSIS
Copy modules from the compatibility session that are directly usable in PowerShell Core

.DESCRIPTION
Copy modules from the compatibility session that are directly usable in PowerShell Core.
By default, these modules will be copied to $Home/Documents/PowerShell/Modules.
This can be overridden using the -Destination parameter.
Once these modules have been copied,
they will be available just like the other native modules for PowerShell Core.

Note that if there already is a module in the destination corresponding to the module
to be copied name, it will not be copied.

.PARAMETER Name
Specifies names or name patterns of modules that will be copied.
Wildcard characters are supported.

.PARAMETER Domain
If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

.PARAMETER ConfigurationName
Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

.PARAMETER Credential
If needed, use this parameter to specify credentials for the compatibility session

.PARAMETER Destination
The location where compatible modules should be copied to

.EXAMPLE
PS> Copy-WinModule hyper-v -WhatIf -Verbose

Run the copy command with -WhatIf to see what would be copied to $PSHome/Modules.
Also show Verbose information.

.EXAMPLE
PS> Copy-WinModule hyper-v -Destination ~/Documents/PowerShell/Modules

Copy the specified module to your user module directory.

.INPUTS
None. You cannot pipe objects to Copy-WinModule

.OUTPUTS
None. Copy-WinModule does not generate any output

.NOTES
The Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Added parameter debugging stream

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Copy-WinModule.md

.LINK
https://github.com/PowerShell/WindowsCompatibility
#>
function Copy-WinModule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Copy-WinModule.md")]
	[OutputType([void])]
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
		[string] $Destination
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[bool] $WhatIfFlag = $PSBoundParameters["WhatIf"]
	[bool] $ConfirmFlag = $PSBoundParameters["Confirm"]

	if (!$Destination)
	{
		# If the user hasn't specified a destination, default to the user module directory
		$Parts = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments),
		"PowerShell",
		"Modules"
		$Destination = Join-Path @Parts
	}

	# Resolve the path which also verifies that the path exists
	$ResolvedDestination = Resolve-Path $Destination -ErrorAction SilentlyContinue
	if (!$?)
	{
		throw "The destination path '$Destination' could not be resolved. Please ensure that the path exists and try the command again"
	}

	# Make sure it's a FileSystem location
	if ($ResolvedDestination.Provider.ImplementingType -ne [Microsoft.PowerShell.Commands.FileSystemProvider] )
	{
		throw "Modules can only be installed to paths in the filesystem. Please choose a different location and try the command again"
	}

	$Destination = $ResolvedDestination.Path

	$InitializeWinSessionParameters = @{
		ComputerName = $Domain
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}

	[PSSession] $Session = Initialize-WinSession @InitializeWinSessionParameters

	$CopyItemParameters = @{
		WhatIf = $WhatIfFlag
		Confirm = $ConfirmFlag
		Recurse = $true
	}

	if (($Domain -ne "localhost") -and ($Domain -ne ".") -and ($Domain -eq [System.Environment]::MachineName))
	{
		$CopyItemParameters.FromSession = $Session
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching for compatible modules..."
	$ModulesToCopy = Invoke-Command $Session -ScriptBlock {
		Get-Module -ListAvailable -Name $using:CompatibleModules |
		Select-Object Name, ModuleBase
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching for CIM modules..."
	$ModulesToCopy += Invoke-Command $Session -ScriptBlock {
		Get-Module -ListAvailable |
		Where-Object { $_.NestedModules[0].path -match "\.cdxml$" } |
		Select-Object Name, ModuleBase
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Copying modules to path '$Destination'"

	$ModulesToCopy = $ModulesToCopy | Sort-Object -Unique -Property Name
	foreach ($Module in $ModulesToCopy)
	{
		# Skip modules that aren't on the named module list
		if (!($Name | Where-Object { $Module.Name -like $_ }))
		{
			continue
		}

		$FullDestination = Join-Path $Destination $Module.name
		if (!(Test-Path $FullDestination))
		{
			Copy-Item -Path $Module.ModuleBase -Destination $FullDestination @CopyItemParameters
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Skipping module '$($Module.Name)'; module directory already exists"
		}
	}
}

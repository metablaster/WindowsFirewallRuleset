
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
Copy modules from the compatibility session that are directly usable in PowerShell Core.

.DESCRIPTION
Copy modules from the compatibility session that are directly usable in PowerShell Core.
By default, these modules will be copied to $Home/Documents/PowerShell/Modules.
This can be overridden using the -Destination parameter.
Once these modules have been copied,
they will be available just like the other native modules for PowerShell Core.

Note that if there already is a module in the destination corresponding to the module
to be copied's name, it will not be copied.

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
None.
TODO: Update Copyright and start implementing module function
TODO: Update HelpURI
#>
function Copy-WinModule
{
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([void])]
	Param
	(
		# Specifies names or name patterns of modules that will be copied.
		# Wildcard characters are permitted.
		[Parameter(Mandatory = $false, Position = 0)]
		[String[]]
		$Name = "*",

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

		# If needed, use this parameter to specify credentials for the compatibility session
		[Parameter()]
		[PSCredential]
		$Credential,

		# The location where compatible modules should be copied to
		[Parameter()]
		[String]
		$Destination
	)

	[bool] $verboseFlag = $PSBoundParameters['Verbose']
	[bool] $whatIfFlag = $PSBoundParameters['WhatIf']
	[bool] $confirmFlag = $PSBoundParameters['Confirm']

	if (-not $Destination)
	{
		# If the user hasn't specified a destination, default to the user module directory
		$parts = [environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments),
		"PowerShell",
		"Modules"
		$Destination = Join-Path @parts
	}

	# Resolve the path which also verifies that the path exists
	$resolvedDestination = Resolve-Path $Destination -ErrorAction SilentlyContinue
	if (-not $?)
	{
		throw "The destination path '$Destination' could not be resolved. Please ensure that the path exists and try the command again"
	}
	# Make sure it's a FileSystem location
	if ($resolvedDestination.provider.ImplementingType -ne [Microsoft.PowerShell.Commands.FileSystemProvider] )
	{
		throw "Modules can only be installed to paths in the filesystem. Please choose a different location and try the command again"
	}
	$Destination = $resolvedDestination.Path

	$initializeWinSessionParameters = @{
		Verbose = $verboseFlag
		ComputerName = $ComputerName
		ConfigurationName = $ConfigurationName
		Credential = $Credential
		PassThru = $true
	}
	[PSSession] $session = Initialize-WinSession @initializeWinSessionParameters

	$copyItemParameters = @{
		WhatIf = $whatIfFlag
		Verbose = $verboseFlag
		Confirm = $confirmFlag
		Recurse = $true
	}
	if ($ComputerName -ne "localhost" -and $ComputerName -ne ".")
	{
		$copyItemParameters.FromSession = $session
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching for compatible modules..."
	$modulesToCopy = Invoke-Command $session {
		Get-Module -ListAvailable -Name $using:CompatibleModules |
		Select-Object Name, ModuleBase
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching for CIM modules..."
	$modulesToCopy += Invoke-Command $session {
		Get-Module -ListAvailable |
		Where-Object { $_.NestedModules[0].path -match '\.cdxml$' } |
		Select-Object Name, ModuleBase
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Copying modules to path '$Destination'"

	$modulesToCopy = $modulesToCopy | Sort-Object -Unique -Property Name
	foreach ($m in $modulesToCopy)
	{
		# Skip modules that aren't on the named module list
		if (-not ($name.Where{ $m.Name -like $_ }))
		{
			continue
		}

		$fullDestination = Join-Path $Destination $m.name
		if (-not (Test-Path $fullDestination))
		{
			Copy-Item -Path $m.ModuleBase -Destination $fullDestination @copyItemParameters
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Skipping module '$($m.Name)'; module directory already exists"
		}
	}
}

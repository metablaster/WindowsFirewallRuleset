
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Finds duplicate modules

.DESCRIPTION
Finds duplicate modules installed on system taking care of PS edition being used.

To find duplicate modules for Windows PowerShell, Desktop edition should be used,
otherwise to find duplicates for PS Core, Core edition should be used.

.PARAMETER Name
One or more module names which to check for duplicates.
Wildcard characters are supported.

.PARAMETER Scope
Specifies one or more scopes (installation locations) in which to search for duplicate modules,
possible values are:
Shipping: Modules which are part of PowerShell installation
System: Modules installed for all users
User: Modules installed for current user

.EXAMPLE
Find-DuplicateModule

ModuleType Version    Name                  ExportedCommands
Binary     1.0.0.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     1.4.8.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     3.4.0      Pester                {Describe, Context, It, Should...}
Script     5.3.3      Pester                {Invoke-Pester, Describe, Context, It...}
Script     1.0.0.1    PowerShellGet         {Install-Module, Find-Module, Save-Module, Update-Module...}
Script     2.2.5      PowerShellGet         {Find-Command, Find-DSCResource, Find-Module, Find-RoleCapability...}
Script     2.0.0      PSReadline            {Get-PSReadLineKeyHandler, Get-PSReadLineOption...}
Script     2.2.6      PSReadline            {Get-PSReadLineKeyHandler, Get-PSReadLineOption...}

.EXAMPLE
Find-DuplicateModule -Name PackageMan* -Scope System

ModuleType Version    Name                  ExportedCommands
Binary     1.0.0.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     1.4.8.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}

.INPUTS
None. You cannot pipe objects to Find-DuplicateModule

.OUTPUTS
[PSModuleInfo]

.NOTES
None.
#>
function Find-DuplicateModule
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Find-DuplicateModule.md")]
	[OutputType([PSModuleInfo], [void])]
	param (
		[Parameter()]
		[SupportsWildcards()]
		[string[]] $Name = "*",

		[Parameter()]
		[ValidateSet("Shipping", "System", "User")]
		[string[]] $Scope
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	. $PSScriptRoot\..\Scripts\ModuleDirectories.ps1

	$AllModules = Get-Module -Name $Name -ListAvailable | ForEach-Object {
		$Module = $_
		switch -Wildcard ($_.Path)
		{
			$ShippingPath* { $Module }
			$SystemPath* { $Module }
			$HomePath* { $Module }
			default { break }
		}
	}

	[PSModuleInfo[]] $TargetModules = @()

	if ($Scope)
	{
		if ("Shipping" -in $Scope)
		{
			$TargetModules += $AllModules | Where-Object -Property Path -Like $ShippingPath*
		}

		if ("System" -in $Scope)
		{
			$TargetModules += $AllModules | Where-Object -Property Path -Like $SystemPath*
		}

		if ("User" -in $Scope)
		{
			$TargetModules += $AllModules | Where-Object -Property Path -Like $HomePath*
		}
	}
	else
	{
		$TargetModules = $AllModules
	}

	$ModulesNames = $TargetModules | Select-Object -ExpandProperty Name
	$UniqueModules = $ModulesNames | Select-Object -Unique

	$Duplicates = @()
	if ($ModulesNames -and $UniqueModules)
	{
		$Duplicates = Compare-Object -ReferenceObject $UniqueModules -DifferenceObject $ModulesNames |
		Select-Object -ExpandProperty InputObject
	}

	$TargetModules = $TargetModules | Where-Object -Property Name -In $Duplicates

	if ($TargetModules)
	{
		$TargetModules | Sort-Object -Property Name, Version
	}
	elseif ($Scope)
	{
		$Message = "'"
		foreach ($ScopeName in $Scope)
		{
			$Message += "$ScopeName, "
		}
		$Message = $Message.TrimEnd(", ")
		$Message += "' scope"
		if ($Scope.Count -gt 1) { $Message += "s" }

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: No duplicate modules found for PowerShell $($PSVersionTable.PSEdition) edition in $Message"
	}
	else
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: No duplicate modules found for PowerShell $($PSVersionTable.PSEdition) edition"
	}
}

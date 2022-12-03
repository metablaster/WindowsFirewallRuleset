
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
Default module installation directories

.DESCRIPTION
ModuleDirectories lists installation directories for all editions of PowerShell

.EXAMPLE
PS> .\ModuleDirectories

.INPUTS
None. You cannot pipe objects to ModuleDirectories.ps1

.OUTPUTS
None. ModuleDirectories.ps1 does not generate any output

.NOTES
None.

.LINK
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Settings used by other scripts")]
[CmdletBinding()]
param ()

# Utility or settings scripts don't do anything on their own
if ($MyInvocation.InvocationName -ne '.')
{
	Write-Error -Category NotEnabled -TargetObject $MyInvocation.InvocationName `
		-Message "This is settings script and must be dot sourced where needed" -EA Stop
}

if ($PSVersionTable.PSEdition -eq "Desktop")
{
	# This location is reserved for modules that ship with Windows.
	# C:\Windows\System32\WindowsPowerShell\v1.0
	$ShippingPath = "$PSHome\Modules"

	# This location is for system wide modules install
	# C:\Program Files\WindowsPowerShell\Modules
	$SystemPath = "$env:ProgramFiles\WindowsPowerShell\Modules"

	# This location is for per user modules install
	# C:\Users\USERNAME\Documents\WindowsPowerShell\Modules
	$HomePath = "$Home\Documents\WindowsPowerShell\Modules"
}
else
{
	# C:\Program Files\PowerShell\7\Modules
	$ShippingPath = "$PSHome\Modules"

	# C:\Program Files\PowerShell\Modules
	$SystemPath = "$env:ProgramFiles\PowerShell\Modules"

	# C:\Users\USERNAME\Documents\PowerShell\Modules
	$HomePath = "$Home\Documents\PowerShell\Modules"
}

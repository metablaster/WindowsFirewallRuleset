
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Get store apps installed system wide

.DESCRIPTION
Search system wide installed store apps

.PARAMETER ComputerName
NETBIOS Computer name in form of "COMPUTERNAME"

.EXAMPLE
PS> Get-SystemApps "COMPUTERNAME"

.INPUTS
None. You cannot pipe objects to Get-SystemApps

.OUTPUTS
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

.NOTES
TODO: query remote computer not implemented
TODO: multiple computers
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: it is possible to add -User parameter, what's the purpose? see also StoreApps.ps1
#>
function Get-SystemApps
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-SystemApps.md")]
	[OutputType([Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage])]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		# TODO: show warning instead of error when fail (ex. in non elevated run)
		Get-AppxPackage -PackageTypeFilter Main | Where-Object {
			$_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*"
		}
	}
}

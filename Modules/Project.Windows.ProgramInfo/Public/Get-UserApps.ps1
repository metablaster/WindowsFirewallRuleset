
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
Get store apps for specific user

.DESCRIPTION
Search installed store apps in userprofile for specific user account

.PARAMETER UserName
User name in form of:
- domain\user_name
- user_name@fqn.domain.tld
- user_name
- SID-string

.PARAMETER ComputerName
NETBIOS Computer name in form of "COMPUTERNAME"

.EXAMPLE
PS> Get-UserApps "USERNAME"

.INPUTS
None. You cannot pipe objects to Get-UserApps

.OUTPUTS
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

.NOTES
TODO: query remote computer not implemented
TODO: multiple computers
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: see also -AllUsers and other parameters
https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps
#>
function Get-UserApps
{
	[OutputType([Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-UserApps.md")]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true)]
		[string] $UserName,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		# TODO: show warning instead of error when fail (ex. in non elevated run check is Admin)
		Get-AppxPackage -User $UserName -PackageTypeFilter Bundle
	}
}

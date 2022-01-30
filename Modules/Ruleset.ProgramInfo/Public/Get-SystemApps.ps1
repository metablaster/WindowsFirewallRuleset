
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Search system wide installed store apps, those installed for all users or shipped with system.

.PARAMETER Name
Specifies the name of a particular package.
If specified, function returns results for this package only.
Wildcards are permitted.

.PARAMETER User
User name in form of:

- domain\user_name
- user_name@fqn.domain.tld
- user_name
- SID-string

.PARAMETER Domain
NETBIOS Computer name in form of "COMPUTERNAME"

.EXAMPLE
PS> Get-SystemApps "User" -Domain "Server01"

.EXAMPLE
PS> Get-SystemApps "Administrator"

.INPUTS
None. You cannot pipe objects to Get-SystemApps

.OUTPUTS
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object
[object] In Windows PowerShell
[Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] In PowerShell Core

.NOTES
TODO: Query remote computer not implemented
TODO: Multiple computers
TODO: We should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: Format.ps1xml not applied in Windows PowerShell
#>
function Get-SystemApps
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemApps.md")]
	[OutputType([Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage], [object])]
	param (
		[Parameter()]
		[SupportsWildcards()]
		[string] $Name = "*",

		[Parameter(Mandatory = $true)]
		[Alias("UserName")]
		[string] $User,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-Computer $Domain)
	{
		# TODO: show warning instead of error when fail (ex. in non elevated run)
		# TODO: it is possible to add -User parameter, what's the purpose? see also StoreApps.ps1
		Get-AppxPackage -Name $Name -User $User -PackageTypeFilter Main | Where-Object {
			$_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*"
		} | ForEach-Object {
			# NOTE: This path will be missing for default apps on Windows server
			# It may also be missing in fresh installed OS before connecting to internet
			# TODO: See if "$_.Status" property can be used to determine if app is valid
			if (Test-Path -PathType Container -Path "$env:SystemDrive\Users\$User\AppData\Local\Packages\$($_.PackageFamilyName)\AC")
			{
				# There is no Domain property, so add one, PSComputerName property is of no use here
				Add-Member -InputObject $_ -PassThru -Type NoteProperty -Name Domain -Value $Domain
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Store app '$($_.Name)' is not installed by user '$User' or the app is missing"
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: To fix the problem let this user update all of it's apps in Windows store"
			}
		}
	}
}

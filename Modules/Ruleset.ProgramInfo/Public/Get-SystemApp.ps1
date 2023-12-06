
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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

If not specified gets store apps for all user accounts on the computer

.PARAMETER Domain
NETBIOS Computer name in form of "COMPUTERNAME"

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.EXAMPLE
PS> Get-SystemApp "User" -Domain "Server01"

.EXAMPLE
PS> Get-SystemApp "Administrator"

.INPUTS
None. You cannot pipe objects to Get-SystemApp

.OUTPUTS
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object
[object] In Windows PowerShell
[Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] In PowerShell Core

.NOTES
TODO: Query multiple computers
TODO: We should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: Format.ps1xml not applied in Windows PowerShell

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemApp.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage

.LINK
https://learn.microsoft.com/en-us/windows/msix/package/packaging-uwp-apps

.LINK
https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.package

.LINK
https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.packagesignaturekind

.LINK
https://learn.microsoft.com/en-us/windows/application-management/apps-in-windows-10
#>
function Get-SystemApp
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemApp.md")]
	[OutputType([Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage], [object])]
	param (
		[Parameter(Position = 0)]
		[SupportsWildcards()]
		[string] $Name = "*",

		[Parameter()]
		[Alias("UserName")]
		[string] $User,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($PsCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session
	}
	else
	{
		$Domain = Format-ComputerName $Domain

		# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
		if ($Domain -ne [System.Environment]::MachineName)
		{
			$SessionParams.ComputerName = $Domain
			if ($Credential)
			{
				$SessionParams.Credential = $Credential
			}
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting system apps for '$User' user on computer '$Domain'"

	# TODO: show warning instead of error when fail (ex. in non elevated run)
	# TODO: it is possible to add -User parameter, what's the purpose? see also StoreApps.ps1
	if ($Domain -eq [System.Environment]::MachineName)
	{
		if ([string]::IsNullOrEmpty($User))
		{
			$Apps = Get-AppxPackage -Name $Name -AllUsers -PackageTypeFilter Main
		}
		else
		{
			$Apps = Get-AppxPackage -Name $Name -User $User -PackageTypeFilter Main
		}

		$DomainPath = $env:SystemDrive
	}
	else
	{
		# TODO: Get-PSSession will not work for multiple computers because we have only one session currently
		$Apps = Invoke-Command @SessionParams -ScriptBlock {
			# HACK: This will fail in Windows PowerShell with "The system cannot find the file specified"
			# ISSUE: https://github.com/MicrosoftDocs/windows-powershell-docs/issues/344
			# See also: https://www.reddit.com/r/sysadmin/comments/lrm3nj/will_getappxpackage_allusers_work_in_remote
			if ([string]::IsNullOrEmpty($using:User))
			{
				Get-AppxPackage -Name $using:Name -AllUsers -PackageTypeFilter Main
			}
			else
			{
				Get-AppxPackage -Name $using:Name -User $using:User -PackageTypeFilter Main
			}
		}

		# HACK: Hardcoded, a new functioned needed to get remote shares
		[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem -CimSession $CimServer |
		Select-Object -ExpandProperty SystemDrive

		$SystemDrive = $SystemDrive.TrimEnd(":")
		$DomainPath = "\\$Domain\$SystemDrive$"
	}

	if (!$Apps)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] No apps were found for '$User' user on '$Domain'"
	}

	# Index 0 is this function
	$Caller = (Get-PSCallStack)[1].Command

	foreach ($App in $Apps)
	{
		if ($App.SignatureKind -eq "System")
		{
			if (![string]::IsNullOrEmpty($User))
			{
				# NOTE: This path will be missing for default apps on Windows server
				# It may also be missing in fresh installed OS before connecting to internet
				$RemotePath = "$DomainPath\Users\$User\AppData\Local\Packages\$($App.PackageFamilyName)\AC"
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing app path '$RemotePath'"
			}

			# TODO: See if "$_.Status" property can be used to determine if app is valid
			if ([string]::IsNullOrEmpty($User) -or (Test-Path -PathType Container -Path $RemotePath))
			{
				# There is no Domain property, so add one, PSComputerName property is of no use here
				Add-Member -MemberType NoteProperty -InputObject $App -Name Domain -Value $Domain -PassThru
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Store app '$($App.Name)' is not installed by user '$User' or the app is missing"
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: To fix this problem let this user update all of it's apps in Microsoft Store, then rerun '$Caller' script"
			}
		}
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Outbound firewall rules for store apps

.DESCRIPTION
Outbound rules for store apps

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\StoreApps.ps1

.INPUTS
None. You cannot pipe objects to StoreApps.ps1

.OUTPUTS
None. StoreApps.ps1 does not generate any output

.NOTES
TODO: exclude store apps rules for servers, store app folders seem to exist but empty.
TODO: currently making rules for each user separately, is it possible to make rules for all users?

NOTE: Following "rules" apply for store apps for blocking/allowing users
1. -Owner - Only one explicit user account can be specified (not group, not capability etc...)
2. -LocalUser - Anything can be specified
3. Either -Owner or -LocalUser can be specified, not both which would make the rule not working and useless
4. If the LocalUser is specified and rule is blocking, then another allow rule (with? or without owner) may take precedence over blocking rule
5. If the owner is specified, the rule is well formed and normal "rules" apply as with all other rules
6. Conclusion is, the -LocalUser parameter can be specified instead of -Owner only to allow traffic that was not already
   blocked by rules with owner parameter specified
7. All of this applies only to "Any" and "*" packages, for specific package only -Owner must be
   specified and -LocalUser is not valid for specific packages

TODO: Prompt or refuse running this script on server platforms (platforms with no apps)
TODO: Rule display names don't have all consistent casing (ex. microsoft vs Microsoft)

HACK: in Firewall GUI the rule may state wrong user in "Application packages" window,
but the SID is the same for all users anyway, so OK,
also it doesn't matter because in the GUI, SID radio button is checked, not the package name.

TODO: rules for *some* apps which have not been updated by user will not work,
example solitaire app; need to either update them or detect this case.

NOTE: updating apps will not work unless also "Extension users" are updated in
WindowsServices.ps1, meaning re-run the script.

TODO: We can learn app display name from manifest
TODO: OfficeHub app contains sub app "LocalBridge" which is blocked

NOTE: If OneNote app fails to install, start "Print Spooler" service and try again
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Store Apps"
$ProgramsGroup = "Store Apps - Programs"
$ServicesGroup = "Store Apps - Services"
$SystemGroup = "Store Apps - System"
$Accept = "Outbound rules for store apps will be loaded, required for Windows store apps network access"
$Deny = "Skip operation, outbound rules for store apps will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $SystemGroup -Direction $Direction -ErrorAction Ignore
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $ProgramsGroup -Direction $Direction -ErrorAction Ignore
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $ServicesGroup -Direction $Direction -ErrorAction Ignore

#
# Block Administrators by default
#
$Users = Get-GroupPrincipal "Users"
$Administrators = Get-GroupPrincipal "Administrators"

foreach ($Principal in $Administrators)
{
	foreach ($Entry in $Users)
	{
		if ($Entry.User -eq $Principal.User)
		{
			Write-Warning -Message "[$ThisScript] $($Principal.User) is both Administrator and standard user, this will result in surplus rules for store apps"
		}
	}

	# TODO: Somehow Admin will be able to create MS accounts when this rule is disabled,
	# expected behavior is that default outbound should block (wwahost.exe)
	New-NetFirewallRule -DisplayName "Store apps for $($Principal.User)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Owner (Get-PrincipalSID $Principal.User) -Package * `
		-Description "$($Principal.User) is administrative account,
block $($Principal.User) from network activity for all store apps.
Administrators should have limited or no connectivity at all for maximum security." |
	Format-RuleOutput
}

#
# Create rules for all network apps for each standard user
#
foreach ($Principal in $Users)
{
	#
	# Create rules for apps installed by user
	#

	Get-UserApps -User $Principal.User | ForEach-Object -Process {
		$NetworkCapabilities = $_ | Get-AppCapability -User $Principal.User -Networking

		if (!$NetworkCapabilities)
		{
			return
		}

		[string[]] $RemoteAddress = @()

		foreach ($Capability in $NetworkCapabilities)
		{
			switch -Wildcard ($Capability)
			{
				"Your Internet connection*"
				{
					$RemoteAddress += "Internet4"
					break
				}
				"Your home or work networks"
				{
					$RemoteAddress += "LocalSubnet4"
					break
				}
				"runFullTrust"
				{
					$RemoteAddress += "Internet4"
					break
				}
			}
		}

		if ($RemoteAddress.Count -eq 0)
		{
			return
		}

		$RemoteAddress = $RemoteAddress | Select-Object -Unique
		$PackageSID = Get-AppSID -FamilyName $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			New-NetFirewallRule -DisplayName $_.Name `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program Any -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress $RemoteAddress `
				-LocalPort Any -RemotePort 80, 443 `
				-LocalUser Any `
				-InterfaceType $DefaultInterface `
				-Owner $Principal.SID -Package $PackageSID `
				-Description "Auto generated rule for $($_.Name) used by $($Principal.User)" |
			Format-RuleOutput

			Update-Log
		}
	}

	#
	# Create rules for system apps
	#

	Get-SystemApps -User $Principal.User | ForEach-Object -Process {
		$NetworkCapabilities = $_ | Get-AppCapability -Networking

		if (!$NetworkCapabilities)
		{
			return
		}

		[string[]] $RemoteAddress = @()

		foreach ($Capability in $NetworkCapabilities)
		{
			switch -Wildcard ($Capability)
			{
				"Your Internet connection*"
				{
					$RemoteAddress += "Internet4"
					break
				}
				"Your home or work networks"
				{
					$RemoteAddress += "LocalSubnet4"
					break
				}
				"runFullTrust"
				{
					$RemoteAddress += "Internet4"
					break
				}
			}
		}

		if ($RemoteAddress.Count -eq 0)
		{
			return
		}

		$RemoteAddress = $RemoteAddress | Select-Object -Unique
		$PackageSID = Get-AppSID -FamilyName $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			New-NetFirewallRule -DisplayName $_.Name `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program Any -Group $SystemGroup `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress $RemoteAddress `
				-LocalPort Any -RemotePort 80, 443 `
				-LocalUser Any `
				-InterfaceType $DefaultInterface `
				-Owner $Principal.SID -Package $PackageSID `
				-Description "Auto generated rule for $($_.Name) installed system wide and used by $($Principal.User)" |
			Format-RuleOutput

			Update-Log
		}
	}
}

#
# Following are executables and service rules needed by apps for web authentication
#

$Program = "%SystemRoot%\System32\RuntimeBroker.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Runtime Broker" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $ProgramsGroup `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "The Runtime Broker is responsible for checking if a store app is declaring all of
its permissions and informing the user whether or not its being allowed" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\AuthHost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# Accounts needed for store app web authentication
	$AppAccounts = Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -User "Your Internet connection"
	Merge-SDDL ([ref] $AppAccounts) -From $UsersGroupSDDL

	New-NetFirewallRule -DisplayName "Authentication Host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $ProgramsGroup `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $AppAccounts `
		-InterfaceType $DefaultInterface `
		-Description "Connects Universal Windows Platform (UWP) app to an online identity provider
that uses authentication protocols like OpenID or OAuth, such as Facebook, Twitter, Instagram, etc." |
	Format-RuleOutput
}

New-NetFirewallRule -DisplayName "Windows License Manager Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service LicenseManager -Program $ServiceHost -Group $ServicesGroup `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Provides infrastructure support for the Microsoft Store." |
Format-RuleOutput

# https://docs.microsoft.com/en-us/archive/msdn-magazine/2017/april/uwp-apps-develop-hosted-web-apps-for-uwp
$Program = "%SystemRoot%\System32\wwahost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Microsoft WWA Host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $ProgramsGroup `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $AppAccounts `
		-InterfaceType $DefaultInterface `
		-Description "Microsoft WWA Host (wwahost.exe) is an app container for Web sites,
which has a subset of features, compared to the browser.
Used in scenario when the Web site is running in the context of an app.
This rule is required to connect PC to Microsoft account" |
	Format-RuleOutput
}

# https://docs.microsoft.com/en-us/windows/uwp/launch-resume/web-to-app-linking
$Program = "%SystemRoot%\System32\AppHostRegistrationVerifier.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "App host registration verifier" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $ProgramsGroup `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "App host registration verifier tool tests the configuration of store app and website" |
	Format-RuleOutput
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log


<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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
Make sure to update this list from time to time!
This list is obtained from default windows firewall.

Predefined user apps rule list:

Microsoft.GetHelp
Microsoft.Xbox.TCUI
Microsoft.XboxIdentityProvider
Microsoft.XboxGameOverlay
Microsoft.XboxGamingOverlay
Microsoft.WindowsMaps
Microsoft.WindowsCamera
Microsoft.WindowsCalculator
Microsoft.YourPhone
Microsoft.SkypeApp
Microsoft.Print3D
microsoft.windowscommunicationsapps
Microsoft.XboxApp
Microsoft.Office.OneNote
Microsoft.MicrosoftOfficeHub
Microsoft.BingWeather
Microsoft.OneConnect
Microsoft.MixedReality.Portal
Microsoft.Getstarted
Microsoft.MicrosoftStickyNotes
Microsoft.WindowsStore
Microsoft.MicrosoftSolitaireCollection
Microsoft.Messaging
Microsoft.Wallet
Microsoft.People
Microsoft.Windows.Photos
Microsoft.ZuneMusic
Microsoft.StorePurchaseApp
Microsoft.ZuneVideo
Microsoft.WindowsFeedbackHub
Microsoft.MSPaint
Microsoft.DesktopAppInstaller
Microsoft.Microsoft3DViewer


predefined system apps rule list:

Microsoft.Windows.CloudExperienceHost
Microsoft.XboxGameCallableUI
Microsoft.AAD.BrokerPlugin
Microsoft.Windows.ShellExperienceHost
Microsoft.Windows.PeopleExperienceHost
Microsoft.Windows.SecHealthUI
Microsoft.Windows.Cortana
Microsoft.Windows.Apprep.ChxApp (smartscreen)
Microsoft.LockApp
Microsoft.Windows.SecureAssessmentBrowser
Microsoft.Windows.StartMenuExperienceHost
Microsoft.Windows.NarratorQuickStart
Microsoft.Windows.ParentalControls
Microsoft.MicrosoftEdge
Microsoft.Windows.ContentDeliveryManager
Microsoft.AccountsControl
Microsoft.Win32WebViewHost
Microsoft.PPIProjection
Microsoft.Windows.OOBENetworkCaptivePortal


predefined system apps not cached by our command:

InputApp
#>

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Store Apps"
$SystemGroup = "Store Apps - System"
$Profile = "Private, Public"
$NetworkApps = Get-Content -Path "$PSScriptRoot\..\NetworkApps.txt"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $SystemGroup -Direction $Direction -ErrorAction Ignore @Logs

#
# Firewall predefined rules for Microsoft store Apps
# TODO: exclude store apps rules for servers, store app folders seem to exist but empty.
# TODO: currently making rules for each user separately, is it possible to make rules for all users?
#

#
# Block Administrators by default
# TODO: should group SID be supplied to local user instead of owner?
#

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Store apps for Administrators" -Service Any -Program Any `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Any -InterfaceType $Interface `
	-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-LocalUser Any -Owner (Get-GroupSID "Administrators") -Package "*" `
	-Description "Block admin activity for all store apps.
Administrators should have limited or no connectivity at all for maximum security." @Logs | Format-Output @Logs

#
# Create rules for all network apps for each standard user
# HACK: in Firewall GUI the rule may state wrong user in "Application packages" window, but the SID is the same for all users anyway, so OK,
# also it doesn't matter because in the GUI, SID radio button is checked, not the package name.
# TODO: rules for *some* apps which have not been updated by user will not work, example solitaire app; need to either update them or detect this case.
# NOTE: updating apps will not work unless also "Extension users" are updated in WindowsServices.ps1, meaning re-run the script.
#

$Principals = Get-GroupPrincipals "Users"
foreach ($Principal in $Principals)
{
	#
	# Create rules for apps installed by user
	#

	Get-AppxPackage -User $Principal.User -PackageTypeFilter Bundle | ForEach-Object {

		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			$Enabled = "False"

			# Enable only networking apps
			if ($NetworkApps -contains $_.Name)
			{
				$Enabled = "True"
			}

			New-NetFirewallRule -Platform $Platform `
				-DisplayName $_.Name -Service Any -Program Any `
				-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser Any -Owner $Principal.SID -Package $PackageSID `
				-Description "Store apps generated rule for $($Principal.User)" @Logs | Format-Output @Logs

			Update-Logs
		}
	}

	#
	# Create rules for system apps
	#

	# NOTE: -User parameter is probably not needed here? aded while troubleshooting the hack above.
	Get-AppxPackage -User $Principal.User -PackageTypeFilter Main |
	Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | ForEach-Object {

		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			$Enabled = "False"

			# Enable only networking apps
			if ($NetworkApps -contains $_.Name)
			{
				$Enabled = "True"
			}

			New-NetFirewallRule -Platform $Platform `
				-DisplayName $_.Name -Service Any -Program Any `
				-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $SystemGroup -Profile $Profile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser Any -Owner $Principal.SID -Package $PackageSID `
				-Description "System store apps generated rule for $($Principal.User)" @Logs | Format-Output @Logs

			Update-Logs
		}
	}
}

Update-Logs

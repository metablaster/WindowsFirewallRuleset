
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Outbound firewall rules for OneDrive

.DESCRIPTION
Outbound firewall rules for One Drive

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\OneDrive.ps1

.INPUTS
None. You cannot pipe objects to OneDrive.ps1

.OUTPUTS
None. OneDrive.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
# TODO: Same code in multiple places, it makes sense to have global variable which would
# hold information about remote computer
$ServerTarget = (Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
		-ClassName Win32_OperatingSystem -EA Stop |
	Select-Object -ExpandProperty ProductType) -eq 3

$Group = "Microsoft - One Drive"
$Accept = "Outbound rules for One Drive will be loaded, recommended if One Drive is installed to let it access to network"
$Deny = "Skip operation, outbound rules for One Drive will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force -Unsafe:$ServerTarget)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# One Drive installation directories
# TODO: This path is wrong since one drive become part of system, but we need some path even if wrong
#
$OneDriveRoot = "%ProgramFiles(x86)%\Microsoft OneDrive"

#
# Rules for One Drive
# TODO: does not exist on server platforms
#

# Test if installation exists on system
if ((Confirm-Installation "OneDrive" ([ref] $OneDriveRoot)) -or $ForceLoad)
{
	$Program = "$OneDriveRoot\OneDriveStandaloneUpdater.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# NOTE: According to scheduled task the updating user is SYSTEM
		# TODO: Not sure if rule for SYSTEM account is needed since there is rule for user below
		New-NetFirewallRule -DisplayName "OneDrive Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "Updater for OneDrive" | Format-RuleOutput

		# TODO: Not sure if port 80 is needed
		New-NetFirewallRule -DisplayName "OneDrive Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Updater for OneDrive" | Format-RuleOutput
	}

	# TODO: LocalUser should be explicit user because each user runs it's own instance
	# and if there are multiple instances returned we need multiple rules for each user
	$Program = "$OneDriveRoot\OneDrive.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "OneDrive" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "One drive for syncing user data" | Format-RuleOutput
	}

	$VersionFolder = Invoke-Command -Session $SessionInstance -ScriptBlock {
		$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($using:OneDriveRoot)

		Get-ChildItem -Directory -Path $ExpandedPath -Name -ErrorAction SilentlyContinue | Where-Object {
			$_ -match "(\d+\.?){1,4}"
		}
	}

	if (!$ForceLoad -and [string]::IsNullOrEmpty($VersionFolder))
	{
		Write-Warning -Message "[$ThisScript] Unable to find OneDrive version folder in '$OneDriveRoot'"
	}
	else
	{
		$Program = "$OneDriveRoot\$VersionFolder\FileSyncHelper.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "OneDrive file sync helper" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $LocalSystem `
				-InterfaceType $DefaultInterface `
				-Description "" | Format-RuleOutput
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

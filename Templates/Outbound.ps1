
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# TODO: Include modules you need, update licence Copyright and start writing code

# Includes
# . $PSScriptRoot\..\DirectionSetup.ps1
# . $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ComputerInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Template - TargetProgram"
$FirewallProfile = "Private, Public"
$PackageSID = "*"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# TargetProgram installation directories
#
$TargetProgramRoot = "%ProgramFiles%\TargetProgram"

#
# Rules for TargetProgram
#

# Test if installation exists on system
if ((Test-Installation "TargetProgram" ([ref] $TargetProgramRoot) @Logs) -or $ForceLoad)
{
	$Program = "$TargetProgramRoot\TargetProgram.exe"
	Test-File $Program @Logs

	# Following lines/options are not used:
	# -Name (if used then on first line, DisplayName should be adjusted for 100 col. line)
	# -RemoteUser $RemoteUser -RemoteMachine $RemoteMachine
	# -Authentication NotRequired -Encryption NotRequired -OverrideBlockRules False
	# -InterfaceAlias "loopback" (if used, goes on line with InterfaceType)

	# Following lines/options are used only where appropriate:
	# LocalOnlyMapping $false -LooseSourceMapping $false
	# -Owner $PrincipalSID -Package $PackageSID

	# Outbound TCP template
	New-NetFirewallRule -DisplayName "Outbound TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $EdgeChromiumApp -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $Interface `
		-Description "Outbound TCP template description" `
		@Logs | Format-Output @Logs

	# Outbound UDP template
	New-NetFirewallRule -DisplayName "Outbound UDP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $EdgeChromiumApp -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Outbound UDP template description" `
		@Logs | Format-Output @Logs

	# Outbound ICMP template
	New-NetFirewallRule -DisplayName "Outbound ICMP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $EdgeChromiumApp -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
		-LocalAddress Any -RemoteAddress Any `
		-LocalUser Any `
		-InterfaceType $Interface `
		-Description "Outbound ICMP template description" `
		@Logs | Format-Output @Logs

	# Outbound StoreApp TCP template
	New-NetFirewallRule -DisplayName "Outbound StoreApp TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $EdgeChromiumApp -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $Interface `
		-Owner $PrincipalSID -Package $PackageSID `
		-Description "Outbound StoreApp TCP template description" `
		@Logs | Format-Output @Logs
}

Update-Logs


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

#
# Unit test for Get-Broadcast
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ComputerInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

New-Test "Get-Broadcast"
Get-Broadcast @Logs

New-Test "Get-Broadcast -IncludeDisconnected"
Get-Broadcast -IncludeDisconnected @Logs

New-Test "Get-Broadcast -IncludeVirtual"
Get-Broadcast -IncludeVirtual @Logs

New-Test "Get-Broadcast -IncludeVirtual -IncludeDisconnected"
Get-Broadcast -IncludeVirtual -IncludeDisconnected @Logs

New-Test "Get-Broadcast -IncludeVirtual -IncludeDisconnected -ExcludeHardware"
Get-Broadcast -IncludeVirtual -IncludeDisconnected -ExcludeHardware @Logs

New-Test "Get-Broadcast -IncludeHidden"
Get-Broadcast -IncludeHidden @Logs

New-Test "Get-Broadcast -IncludeAll"
$Broadcast = Get-Broadcast -IncludeAll @Logs
$Broadcast

New-Test "Get-Broadcast -IncludeAll -ExcludeHardware"
Get-Broadcast -IncludeAll -ExcludeHardware @Logs

New-Test "Get-TypeName"
$Broadcast | Get-TypeName @Logs

Update-Logs
Exit-Test

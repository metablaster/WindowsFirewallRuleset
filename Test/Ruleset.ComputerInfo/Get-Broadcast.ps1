
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
Unit test for Get-Broadcast

.DESCRIPTION
Unit test for Get-Broadcast

.EXAMPLE
PS> .\Get-Broadcast.ps1

.INPUTS
None. You cannot pipe objects to Get-Broadcast.ps1

.OUTPUTS
None. Get-Broadcast.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

Start-Test "Get-Broadcast"
Get-Broadcast

Start-Test "Get-Broadcast -IncludeDisconnected"
Get-Broadcast -IncludeDisconnected

Start-Test "Get-Broadcast -IncludeVirtual"
Get-Broadcast -IncludeVirtual

Start-Test "Get-Broadcast -IncludeVirtual -IncludeDisconnected"
Get-Broadcast -IncludeVirtual -IncludeDisconnected

Start-Test "Get-Broadcast -IncludeVirtual -IncludeDisconnected -ExcludeHardware"
Get-Broadcast -IncludeVirtual -IncludeDisconnected -ExcludeHardware

Start-Test "Get-Broadcast -IncludeHidden"
Get-Broadcast -IncludeHidden

Start-Test "Get-Broadcast -IncludeAll"
$Result = Get-Broadcast -IncludeAll
$Result

Start-Test "Get-Broadcast -IncludeAll -ExcludeHardware"
Get-Broadcast -IncludeAll -ExcludeHardware

Test-Output $Result -Command Get-Broadcast

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Unit test for Invoke-Process

.DESCRIPTION
Unit test for Invoke-Process

.EXAMPLE
PS> .\Invoke-Process.ps1

.INPUTS
None. You cannot pipe objects to Invoke-Process.ps1

.OUTPUTS
None. Invoke-Process.ps1 does not generate any output

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

Start-Test "gpupdate.exe /target:computer"
$Result = Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Format
$Result

Test-Output $Result -Command Invoke-Process

Start-Test "path to gpupdate.exe /target:computer -Wait 100"
Invoke-Process "C:\WINDOWS\system32\gpupdate.exe" -NoNewWindow -ArgumentList "/target:computer" -Wait 100

Start-Test "git.exe status"
# TODO: Does not work with Desktop edition
$Result = Invoke-Process "git.exe" -ArgumentList "status" -NoNewWindow
$Result

Test-Output $Result -Command Invoke-Process

Start-Test "Bad path"
Invoke-Process "C:\Program F*\Powe?Shell\777\pwsh.exe" -Format -Wait 5000

Start-Test "Bad file"
Invoke-Process "C:\Program F*\Powe?Shell\badfile.exe" -Format -Wait 5000

Update-Log
Exit-Test

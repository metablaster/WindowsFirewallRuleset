
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\ComputerInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Microsoft Software"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Installation directories for MS software
#

# Computer name
$ComputerName = Get-ComputerName

$VSCodeRoot = "%ProgramFiles%\Microsoft VS Code"
$WebPlatformRoot = "%ProgramFiles%\Microsoft\Web Platform Installer"
$SQLServerRoot = "%ProgramFiles(x86)%\Microsoft SQL Server\140"
$PowerShell64Root = "%SystemRoot%\System32\WindowsPowerShell\v1.0"
$PowerShell86Root = "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
$OneDriveRoot = "%ProgramFiles(x86)%\Microsoft OneDrive"
$HelpViewerRoot = "%ProgramFiles(x86)%\Microsoft Help Viewer\v2.3"

# Get Windows SDK root
# $WindowsSDK = Get-WindowsSDK $ComputerName
# if ($null -ne $WindowsKits)
# {
#     $SDKRoot = $WindowsSDK |
#     Sort-Object -Property Version |
#     Where-Object { $_.InstallPath } |
#     Select-Object -Last 1 -ExpandProperty InstallPath
# }

# Get Windows SDK debuggers root (latest SDK)
$WindowsKits = Get-WindowsKits $ComputerName
if ($null -ne $WindowsKits)
{
    $SDKDebuggers = $WindowsKits |
    Where-Object {$_.Product -like "WindowsDebuggersRoot*"} |
    Sort-Object -Property Product |
    Select-Object -Last 1 -ExpandProperty InstallPath
}

# Get latest NET Framework installation directory
$NETFrameworkRoot = Get-NetFramework $ComputerName
if ($null -ne $NETFrameworkRoot)
{
    $NETFrameworkRoot = $NETFrameworkRoot |
    Sort-Object -Property Version |
    Where-Object {$_.InstallPath} |
    Select-Object -Last 1 -ExpandProperty InstallPath
}

$vcpkgRoot = "%SystemDrive%\Users\User\source\repos\vcpkg"
$ToolsRoot = "%SystemDrive%\tools"

#
# Rules for Microsoft software
#

$global:InstallationStatus = Test-Installation "VSCode" ([ref] $VSCodeRoot) $false

if ($global:InstallationStatus)
{
    $program = "$VSCodeRoot\Code.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Visual Studio Code" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser $UserAccountsSDDL `
    -Description ""
}

if ($null -ne $SDKDebuggers)
{
    $program = "$SDKDebuggers\x86\windbg.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "WinDbg Symbol Server x86" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "WinDbg access to Symbols Server."

    $program = "$SDKDebuggers\x64\windbg.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "WinDbg Symbol Server x64" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "WinDbg access to Symbols Server"

    $program = "$SDKDebuggers\x86\symchk.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Symchk Symbol Server x86" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "WinDbg Symchk access to Symbols Server."

    $program = "$SDKDebuggers\x64\symchk.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Symchk Symbol Server x64" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "WinDbg Symchk access to Symbols Server"
}

# TODO: need installation check, and need to separate these rules
# Assume unfinished checks for all of the above directories exist
Write-Host "NOTE: in this script confirm switch is enabled for unfinished rules, and default is Yes, even for failures!"

$PreviousExecuteStatus = $global:Execute
$global:Execute = $true
$global:InstallationStatus = $true

$program = "$WebPlatformRoot\WebPlatformInstaller.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Web Platform Installer" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$SQLServerRoot\Tools\Binn\ManagementStudio\Ssms.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "SQL Server Management Studio" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$SQLServerRoot\DTS\Binn\DTSWizard.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "SQL Server Import and Export Wizard" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$PowerShell64Root\powershell_ise.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell ISE x64" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Rule to allow update of powershell"

$program = "$PowerShell64Root\powershell.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell x64" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Rule to allow update of powershell"

$program = "$PowerShell86Root\powershell_ise.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell ISE x86" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Rule to allow update of powershell"

$program = "$PowerShell86Root\powershell.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell x86" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Rule to allow update of powershell"

$program = "$OneDriveRoot\OneDriveStandaloneUpdater.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "OneDrive Update" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Updater for OneDrive"

$program = "$OneDriveRoot\OneDrive.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "OneDrive" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$HelpViewerRoot\HlpCtntMgr.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Help Viewer (Content manager)" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$HelpViewerRoot\HlpViewer.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Help Viewer" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description "Review downloadable content."

if ($null -ne $NETFrameworkRoot)
{
    $program = "$NETFrameworkRoot\mscorsvw.exe"
    Test-File $program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "CLR Optimization Service" -Service Any -Program $program `
    -PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
    -LocalUser $UserAccountsSDDL `
    -Description "mscorsvw.exe is precompiling .NET assemblies in the background.
    Once it's done, it will go away. Typically, after you install the .NET Redist,
    it will be done with the high priority assemblies in 5 to 10 minutes and then will wait until your computer is idle to process the low priority assemblies."
}

$program = "$vcpkgRoot\vcpkg.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "install package source code"

# TODO: need to update for all users
$program = "%LOCALAPPDATA%\Temp\vcpkg\vcpkgmetricsuploader-2019.09.12.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg (telemetry)" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "vcpkg sends usage data to Microsoft"

$program = "$vcpkgRoot\downloads\tools\powershell-core-6.2.1-windows\powershell.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg (powershell)" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "vcpkg has it's own powershell"

$program = "$vcpkgRoot\downloads\tools\cmake-3.14.0-windows\cmake-3.14.0-win32-x86\bin\cmake.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg (cmake)" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "vcpkg has it's own cmake"

$program = "$ToolsRoot\nuget.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Nuget CLI" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $UserAccountsSDDL `
-Description ""

$program = "$ToolsRoot\Autoruns\Autoruns64.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals Autoruns" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "Access to VirusTotal"

$program = "$ToolsRoot\ProcessExplorer\procexp64.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals ProcessExplorer" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "Access to VirusTotal"

$program = "$ToolsRoot\ProcessMonitor\Procmon.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals ProcessMonitor" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $UserAccountsSDDL `
-Description "Access to symbols server"

$program = "$ToolsRoot\TCPView\Tcpview.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals TcpView" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 43 `
-LocalUser $UserAccountsSDDL `
-Description "WhoIs access"

$program = "$ToolsRoot\WhoIs\whois64.exe"
Test-File $program
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals WhoIs" -Service Any -Program $program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 43 `
-LocalUser $UserAccountsSDDL `
-Description ""

# set Execute back to previous value
$global:Execute = $PreviousExecuteStatus

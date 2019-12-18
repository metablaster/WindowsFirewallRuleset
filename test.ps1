
. "$PSScriptRoot\Modules\GlobalVariables.ps1"

# Remove previous test
# Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Inbound -ErrorAction SilentlyContinue
# Remove-NetFirewallRule -PolicyStore "localhost" -Group "Test" -Direction Outbound -ErrorAction SilentlyContinue

<# 
New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
-DisplayName "Test Rule" -Service Any -Program Any `
-Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice -LocalPort PlayToDiscovery -RemotePort Any `
-LocalUser Any -EdgeTraversalPolicy Block
 #>

<# New-NetFirewallRule -ErrorAction Stop -PolicyStore "localhost" `
-DisplayName "Test Rule" -Service Any -Program Any `
-Enabled False -Action Allow -Group "Test" -Profile Domain -InterfaceType Any `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress IntranetRemoteAccess -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser "O:SYG:SYD:(A;;CCRC;;;S-1-5-80-1014140700-3308905587-3330345912-272242898-93311788)"
 #>
# ParseSDDL "O:SYG:SYD:(A;;CCRC;;;S-1-5-80-1014140700-3308905587-3330345912-272242898-93311788)"
# ParseSDDL "O:SYG:SYD:(A;;CCRC;;;S-1-5-80-4267341169-2882910712-659946508-2704364837-2204554466)"
# Get-UserSDDL uSER

<# Write-Host "";
Write-Host "PSVersion: $($PSVersionTable.PSVersion)";
Write-Host "";
Write-Host "`$PSCommandPath:";
Write-Host " *   Direct: $PSCommandPath";
Write-Host " * Function: $(ScriptName)";
Write-Host "";
Write-Host "`$MyInvocation.ScriptName:";
Write-Host " *   Direct: $($MyInvocation.ScriptName)";
Write-Host " * Function: $(ScriptName)";
Write-Host "";
Write-Host "`$MyInvocation.MyCommand.Name:";
Write-Host " *   Direct: $($MyInvocation.MyCommand.Name)";
Write-Host " * Function: $(MyCommandName)";
Write-Host "";
Write-Host "`$MyInvocation.MyCommand.Definition:";
Write-Host " *   Direct: $($MyInvocation.MyCommand.Definition)";
Write-Host " * Function: $(MyCommandDefinition)";
Write-Host "";
Write-Host "`$MyInvocation.PSCommandPath:";
Write-Host " *   Direct: $($MyInvocation.PSCommandPath)";
Write-Host " * Function: $(PSCommandPath)";
Write-Host "";
 #>
<# $ScriptPath = Split-Path $MyInvocation.InvocationName

& "$ScriptPath\IPv4\Outbound\WirelessDisplay.ps1"
 #>

$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$ServiceHost = "%SystemRoot%\System32\svchost.exe"
$Direction = "Inbound"

# O:LSD:(A;;CC;;;SY)(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)

<# $sddl = "O:LSD:(A;;CC;;;SY)(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)"
Convert-SDDLToACL $sddl |
    Select-Object -Expand IdentityReference |
    Select-Object -Expand Value
 #>
<#  $NT_AUTHORITY_System = "D:(A;;CC;;;S-1-5-18)"
 $User = "D:(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)"

$sddl = "D:(A;;CC;;;S-1-5-18)(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)"
Convert-SDDLToACL $sddl |
Select-Object -Expand IdentityReference |
Select-Object -Expand Value
 #>

<#  New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "TEST RULE" -Program $ServiceHost -Service Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group "TEST" -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser (Get-SDDLFromAccounts @("NT AUTHORITY\SYSTEM", "NT AUTHORITY\NETWORK SERVICE", "$UserAccount")) `
-Description "Following services need access based on user account:
Cryptographic Services(CryptSvc),
Microsoft Account Sign-in Assistant(wlidsvc),
Windows Update(wuauserv),
Background Intelligent Transfer Service(BITS)"
 #>
 
# 0:0:0:0:0:0:0:1
<# New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "TEST RULE" -Service Any -Program Any `
-Enabled False -Action Allow -Group "TEST" -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress ::1/128 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."
 #>
# (Get-SDDLFromAccounts @("NT AUTHORITY\SYSTEM", "NT AUTHORITY\NETWORK SERVICE", "$UserAccount"))

#  Get-WmiObject -ComputerName "localhost" -Class Win32_UserAccount -Filter "LocalAccount='True'" | Select-Object PSComputername, Name, Status, Disabled, AccountType, Lockout, PasswordRequired, PasswordChangeable, SID
#  Get-WmiObject -class win32_account -Filter 'name="LOCAL SERVICE"'

# $Path = "C:\Program Files\WindowsApps\Microsoft.YourPhone_1.19111.85.0_x64__8wekyb3d8bbwe"

# $Path

# $ACL = Get-ACL $path
# "`n---Access To String:"
# $ACL.AccessToString

# "`n---Access entry details:"
# $ACL.Access | fl *

# "`n---SDDL:"
# $ACL.SDDL

# Call with named parameter binding 
# $ACL | ParseSDDL
# Or call with parameter string
# ParseSDDL $ACL.SDDL

# $Skype = Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} | Select-Object -ExpandProperty PackageFullName
# $SkypeSID = Get-AppSID "$Skype"

# (Get-AppxPackage -Name "*Yourphone*" | Get-AppxPackageManifest).package.applications

# S-1-15-3-1726375552-1729233799-74693324-3851689839-2151781990
# S-1-15-3-1726375552-1729233799-74693324-3851689839-2151781990-3623637752-3611872497
# S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
# S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
# S-1-15-3-1024-3635283841-2530182609-996808640-1887759898-3848208603-3313616867-983405619-2501854204
# S-1-15-3-1024-3635283841-2530182609-996808640-1887759898-3848208603-3313616867-983405619-2501854204

# New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
# -DisplayName "Store apps for Administrators" -Service Any -Program Any `
# -PolicyStore $PolicyStore -Enabled False -Action Block -Group "TEST RULE" -Profile Any -InterfaceType $Interface `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -EdgeTraversalPolicy Block -LocalUser Any -Owner (Get-UserSID("User")) -Package "S-1-15-2-1726375552-1729233799-74693324-3851689839-2151781990-3623637752-3611872497" `
# -Description "Block admin activity for all apps.
# Administrators should have limited or no connectivity at all for maximum security."

# $Skype = Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} | Select-Object -ExpandProperty PackageFullName

# function Find-PackageFullName([string]$PackageSubstring)
# {
#     $PackageFullName = Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*$PackageSubstring*"} | Select-Object -ExpandProperty PackageFullName
#     return $PackageFullName
# }
# # Get-AppxPackage -User User -PackageTypeFilter Bundle | foreach {$_.Name}
# function Get-PackageName([string]$PackageFullName)
# {
#     Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} | Select-Object -ExpandProperty Name
# }

#     $PackageFullName = Get-AppxPackage -User User | Where-Object {$_.Name -like "*$PackageSubstring*"} | Select-Object -ExpandProperty Name
# Get-AppSID

function Set-PackageOutboundRulesTEST()
{
    Get-AppxPackage -User User -PackageTypeFilter Bundle | ForEach-Object {
        
        $PackageName = $_.Name
        $PackageSID = Get-AppSID($_.InstallLocation)
        $PackageSID
    }
}

Set-PackageOutboundRulesTEST

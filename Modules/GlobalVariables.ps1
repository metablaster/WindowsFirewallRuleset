
# Includes
. "$PSScriptRoot\Functions.ps1"
Import-Module -Name $PSScriptRoot\..\Indented.Net.IP

# Project wide variables
$Platform = "10.0+" #Windows 10 and above
$PolicyStore = "localhost" #Local Group Policy
$OnError = "Stop" #Stop executing if error
$Debug = $false #To add rules to firewall for real set to false
$Execute = $false #To prompt for each rule set to true
$ServiceHost = "%SystemRoot%\System32\svchost.exe" #Most used program
$Interface = "Wired, Wireless" #Default network interface card

# Network IP configuration (get only IPv4 config, index 0, if IPv6 is configured it's at index 1)
$NIC_CONFIG = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway -ne $null}
$LocalHost = $NIC_CONFIG.IPAddress[0]
$SubnetMask = $NIC_CONFIG.IPSubnet[0]
$BroadCast = Get-NetworkSummary $LocalHost $SubnetMask | Select-Object -ExpandProperty BroadcastAddress | Select-Object -ExpandProperty IPAddressToString

# NOTE: -LocalUser, -Owner etc. firewall parameters accepts SDDL format only
# For more complete list see: https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
# If link is not valid google out: "well known SID msdn" or similar search string
# Another way to get information of SDDL string is to create a test rule with that string and see what turns out.

if(!(Test-Path variable:global:UserAccounts))
{
    Write-Host "generating users"
    # Get list of user account in form of COMPUTERNAME\USERNAME
    New-Variable -Name UserAccounts -Option Constant -Scope Global -Value (Get-UserAccounts("Users"))
    New-Variable -Name AdminAccounts -Option Constant -Scope Global -Value (Get-UserAccounts("Administrators"))

    # Generate SDDL string for accounts
    New-Variable -Name UserAccountsSDDL -Option Constant -Scope Global -Value (Get-SDDLFromAccounts $UserAccounts)
    New-Variable -Name AdminAccountsSDDL -Option Constant -Scope Global -Value (Get-SDDLFromAccounts $AdminAccounts)

    # Generate array of usernames (get rid of ComputerName)
    $temp = @()
    foreach($Account in $UserAccounts)
    {
        $temp = $temp += $Account.split("\")[1]
    }
    New-Variable -Name UserNames -Option Constant -Scope Global -Value $temp 

    $temp = @()
    foreach($Account in $AdminAccounts)
    {
        $temp = $temp += $Account.split("\")[1]
    }
    New-Variable -Name AdminNames -Option Constant -Scope Global -Value $temp 
}

# System users (Uncomment as needed)
# "D:(A;;CC;;;S-1-5-0)" # Unknown
# $NT_AUTHORITY_DialUp = "D:(A;;CC;;;S-1-5-1)"
# $NT_AUTHORITY_Network = "D:(A;;CC;;;S-1-5-2)"
# $NT_AUTHORITY_Batch = "D:(A;;CC;;;S-1-5-3)"
# $NT_AUTHORITY_Interactive = "D:(A;;CC;;;S-1-5-4)"
# "D:(A;;CC;;;S-1-5-5)" # Unknown
# $NT_AUTHORITY_Service = "D:(A;;CC;;;S-1-5-6)"
# $NT_AUTHORITY_AnonymousLogon = "D:(A;;CC;;;S-1-5-7)"
# $NT_AUTHORITY_Proxy = "D:(A;;CC;;;S-1-5-8)"
# $NT_AUTHORITY_EnterpriseDomainControlers = "D:(A;;CC;;;S-1-5-9)"
# $NT_AUTHORITY_Self = "D:(A;;CC;;;S-1-5-10)"
# $NT_AUTHORITY_AuthenticatedUsers = "D:(A;;CC;;;S-1-5-11)"
# $NT_AUTHORITY_Restricted = "D:(A;;CC;;;S-1-5-12)"
# $NT_AUTHORITY_TerminalServerUser = "D:(A;;CC;;;S-1-5-13)"
# $NT_AUTHORITY_RemoteInteractiveLogon = "D:(A;;CC;;;S-1-5-14)"
# $NT_AUTHORITY_ThisOrganization = "D:(A;;CC;;;S-1-5-15)"
# "D:(A;;CC;;;S-1-5-16)" # Unknown
# $NT_AUTHORITY_Iusr = "D:(A;;CC;;;S-1-5-17)"
$NT_AUTHORITY_System = "D:(A;;CC;;;S-1-5-18)"
$NT_AUTHORITY_LocalService = "D:(A;;CC;;;S-1-5-19)"
$NT_AUTHORITY_NetworkService = "D:(A;;CC;;;S-1-5-20)"
# "D:(A;;CC;;;S-1-5-21)" ENTERPRISE_READONLY_DOMAIN_CONTROLLERS (S-1-5-21-<root domain>-498)
# $NT_AUTHORITY_EnterpriseReadOnlyDomainControlersBeta = "D:(A;;CC;;;S-1-5-22)"
# "D:(A;;CC;;;S-1-5-23)" # Unknown

# Application packages
# $APPLICATION_PACKAGE_AUTHORITY_AllApplicationPackages = "D:(A;;CC;;;S-1-15-2-1)"
# $APPLICATION_PACKAGE_AUTHORITY_AllRestrictedApplicationPackages = "D:(A;;CC;;;S-1-15-2-2)"
# "D:(A;;CC;;;S-1-15-2-3)" #Unknown

# Other System Users
$NT_AUTHORITY_UserModeDrivers = "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

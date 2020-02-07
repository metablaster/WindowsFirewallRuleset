
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# TODO: write function to query system users


# about: get computer accounts for a giver user group
# Input: User group on local computer
# output: Array of enabled user accounts in specified group, in form of COMPUTERNAME\USERNAME
# sample: Get-UserAccounts("Administrators")
function Get-UserAccounts
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [string] $UserGroup
    )

    # Get all accounts from given group
    $AllAccounts = Get-LocalGroupMember -Group $UserGroup | Where-Object {$_.PrincipalSource -eq "Local"} | Select-Object -ExpandProperty Name

    # Get disabled accounts
    $DisabledAccounts = Get-WmiObject -Class Win32_UserAccount -Filter "Disabled=True" | Select-Object -ExpandProperty Caption

    # Assemble enabled accounts into an array
    $EnabledAccounts = @()
    foreach ($Account in $AllAccounts)
    {
        if (!($DisabledAccounts -contains $Account))
        {
            $EnabledAccounts += $Account
        }
    }

    if([string]::IsNullOrEmpty($EnabledAccounts))
    {
        Set-Warning "Get-UserAccounts: Failed to get UserAccounts for group '$UserGroup'"
    }

    return $EnabledAccounts
}

# about: strip computer names out of computer acounts
# Input: Array of user accounts in form of: COMPUTERNAME\USERNAME
# output: String array of usernames in form of: USERNAME
# sample: Get-UserNames(@("DESKTOP_PC\USERNAME", "LAPTOP\USERNAME"))
function Get-UserNames
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateCount(1, 1000)]
        [ValidateLength(1, 100)]
        [string[]] $UserAccounts
    )

    [string[]] $UserNames = @()
    foreach($Account in $UserAccounts)
    {
        $UserNames += $Account.split("\")[1]
    }

    return $UserNames
}

# about: get SID for giver user name
# input: username string
# output: SID (security identifier) as string
# sample: Get-UserSID("TestUser")
function Get-UserSID
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [string] $UserName
    )

    try
    {
        $NTAccount = New-Object System.Security.Principal.NTAccount($UserName)
        return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()  
    }
    catch
    {
        Set-Warning "Get-UserSID: User '$UserName' cannot be resolved to a SID."
    }
}

# about: get SID for giver computer account
# input: computer account string
# output: SID (security identifier) as string
# sample: Get-AccountSID("COMPUTERNAME\USERNAME")
function Get-AccountSID
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [string] $UserAccount
    )

    [string] $Domain = ($UserAccount.split("\"))[0]
    [string] $User = ($UserAccount.split("\"))[1]

    try
    {
        $NTAccount = New-Object System.Security.Principal.NTAccount($Domain, $User)
        return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()    
    }
    catch
    {
        Set-Warning "Get-AccountSID: Account '$UserAccount' cannot be resolved to a SID."
    }
}

# about: return SDDL of specified local user name or multiple users names
# input: String array of user names
# output: SDDL string for given usernames
# sample: Get-UserSDDL user1, user2
function Get-UserSDDL
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateCount(1, 1000)]
        [ValidateLength(1, 100)]
        [string[]] $UserNames
    )
  
    [string] $SDDL = "D:"
  
    foreach($User in $UserNames)
    {
        try
        {
            $SID = Get-UserSID($User)
        }
        catch
        {
            Set-Warning "Get-UserSDDL: User '$User' not found"
            continue
        }

        $SDDL += "(A;;CC;;;{0})" -f $SID
    }

    return $SDDL
}

# about: return SDDL of multiple computer accounts, in form of: COMPUTERNAME\USERNAME
# input: String array of computer accounts
# output: SDDL string for given accounts
# sample: Get-AccountSDDL @("NT AUTHORITY\SYSTEM", "MY_DESKTOP\MY_USERNAME")
function Get-AccountSDDL
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateCount(1, 1000)]
        [ValidateLength(1, 100)]
        [string[]] $UserAccounts
    )

    [string] $SDDL = "D:"

    foreach ($Account in $UserAccounts)
    {
        try
        {
            $SID = Get-AccountSID($Account)
        }
        catch
        {
            Set-Warning "Get-AccountSDDL: User account $UserAccount not found"
            continue
        }
        
        $SDDL += "(A;;CC;;;{0})" -f $SID

    }

    return $SDDL
}

# TODO: add more groups, guests, everyone etc...
# Get list of user account in form of COMPUTERNAME\USERNAME
New-Variable -Name UserAccounts -Option Constant -Scope Global -Value (Get-UserAccounts "Users")
New-Variable -Name AdminAccounts -Option Constant -Scope Global -Value (Get-UserAccounts "Administrators")

# Get list of user names in form of USERNAME
New-Variable -Name UserNames -Option Constant -Scope Global -Value (Get-UserNames $UserAccounts)
New-Variable -Name AdminNames -Option Constant -Scope Global -Value (Get-UserNames $AdminAccounts)

# Generate SDDL string for accounts
New-Variable -Name UserAccountsSDDL -Option Constant -Scope Global -Value (Get-AccountSDDL $UserAccounts)
New-Variable -Name AdminAccountsSDDL -Option Constant -Scope Global -Value (Get-AccountSDDL $AdminAccounts)

#
# System users (define variables as needed)
#

New-Variable -Name NT_AUTHORITY_System -Option Constant -Scope Global -Value "D:(A;;CC;;;S-1-5-18)"
New-Variable -Name NT_AUTHORITY_LocalService -Option Constant -Scope Global -Value "D:(A;;CC;;;S-1-5-19)"
New-Variable -Name NT_AUTHORITY_NetworkService -Option Constant -Scope Global -Value "D:(A;;CC;;;S-1-5-20)"
New-Variable -Name NT_AUTHORITY_UserModeDrivers -Option Constant -Scope Global -Value "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

#
# Function exports
#

Export-ModuleMember -Function Get-UserAccounts
Export-ModuleMember -Function Get-UserNames
Export-ModuleMember -Function Get-UserSID
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function Get-UserSDDL
Export-ModuleMember -Function Get-AccountSDDL

#
# Variable exports
#

Export-ModuleMember -Variable UserAccounts
Export-ModuleMember -Variable AdminAccounts
Export-ModuleMember -Variable UserNames
Export-ModuleMember -Variable AdminNames
Export-ModuleMember -Variable UserAccountsSDDL
Export-ModuleMember -Variable AdminAccountsSDDL

Export-ModuleMember -Variable NT_AUTHORITY_System
Export-ModuleMember -Variable NT_AUTHORITY_LocalService
Export-ModuleMember -Variable NT_AUTHORITY_NetworkService
Export-ModuleMember -Variable NT_AUTHORITY_UserModeDrivers

#
# System users SDDL strings
#

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
# $NT_AUTHORITY_System = "D:(A;;CC;;;S-1-5-18)"
# $NT_AUTHORITY_LocalService = "D:(A;;CC;;;S-1-5-19)"
# $NT_AUTHORITY_NetworkService = "D:(A;;CC;;;S-1-5-20)"
# "D:(A;;CC;;;S-1-5-21)" ENTERPRISE_READONLY_DOMAIN_CONTROLLERS (S-1-5-21-<root domain>-498)
# $NT_AUTHORITY_EnterpriseReadOnlyDomainControlersBeta = "D:(A;;CC;;;S-1-5-22)"
# "D:(A;;CC;;;S-1-5-23)" # Unknown

# Application packages
# $APPLICATION_PACKAGE_AUTHORITY_AllApplicationPackages = "D:(A;;CC;;;S-1-15-2-1)"
# $APPLICATION_PACKAGE_AUTHORITY_AllRestrictedApplicationPackages = "D:(A;;CC;;;S-1-15-2-2)"
# "D:(A;;CC;;;S-1-15-2-3)" #Unknown

# Other System Users
# $NT_AUTHORITY_UserModeDrivers = "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

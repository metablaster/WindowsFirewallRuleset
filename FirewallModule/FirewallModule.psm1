
# Includes
Import-Module -Name $PSScriptRoot\..\Indented.Net.IP

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
        Write-Warning "Get-UserAccounts: Failed to get UserAccounts"
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
        Write-Warning "Get-UserSID: User '$UserName' cannot be resolved to a SID."
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
        return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).Value    
    }
    catch
    {
        Write-Warning "Get-AccountSID: Account '$UserAccount' cannot be resolved to a SID."
    }
}

# about: get store app SID
# input: Username and "PackageFamilyName" string
# output: store app SID (security identifier) as string
# sample: Get-AppSID("User", "Microsoft.MicrosoftEdge_8wekyb3d8bbwe")
function Get-AppSID
{
    param (
        [parameter(Mandatory = $true, Position=0)]
        [ValidateLength(1, 100)]
        [string] $UserName,

        [parameter(Mandatory = $true, Position=1)]
        [ValidateLength(1, 100)]
        [string] $AppName
    )
    
    $ACL = Get-ACL "C:\Users\$UserName\AppData\Local\Packages\$AppName\AC"
    $ACE = $ACL.Access.IdentityReference.Value
    
    $ACE | ForEach-Object {
        # package SID starts with S-1-15-2-
        if($_ -match "S-1-15-2-") {
            return $_
        }
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
            Write-Warning "Get-UserSDDL: User '$User' not found"
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
            Write-Warning "Get-AccountSDDL: User account $UserAccount not found"
            continue
        }
        
        $SDDL += "(A;;CC;;;{0})" -f $SID

    }

    return $SDDL
}

# about: Convert SDDL entries to computer accounts
# input: String array of one or more strings of SDDL syntax
# output: String array of computer accounts
# sample: Convert-SDDLToACL $SDDL1, $SDDL2
function Convert-SDDLToACL
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateCount(1, 1000)]
        [ValidateLength(1, 1000)]
        [string[]] $SDDL
    )

    [string[]] $ACL = @()
    foreach ($Entry in $SDDL)
    {
        $ACLObject = New-Object -Type Security.AccessControl.DirectorySecurity
        $ACLObject.SetSecurityDescriptorSddlForm($Entry)
        $ACL += $ACLObject.Access | Select-Object -ExpandProperty IdentityReference | Select-Object -ExpandProperty Value
    }

    return $ACL
}

# Show-SDDL returns SDDL based on "object"
# Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1/
# sample: see Test\Show-SDDL.ps1 for example

function Show-SDDL
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            valueFromPipelineByPropertyName=$true)] $SDDL
    )

    $SDDLSplit = $SDDL.Split("(")

    Write-Host ""
    Write-Host "SDDL Split:"
    Write-Host "****************"

    $SDDLSplit

    Write-Host ""
    Write-Host "SDDL SID Parsing:"
    Write-Host "****************"

    # Skip index 0 where owner and/or primary group are stored            
    For ($i=1;$i -lt $SDDLSplit.Length;$i++)
    {
        $ACLSplit = $SDDLSplit[$i].Split(";")

        If ($ACLSplit[1].Contains("ID"))
        {
            "Inherited"
        }
        Else
        {
            $ACLEntrySID = $null

            # Remove the trailing ")"
            $ACLEntry = $ACLSplit[5].TrimEnd(")")

            # Parse out the SID using a handy RegEx
            $ACLEntrySIDMatches = [regex]::Matches($ACLEntry,"(S(-\d+){2,8})")
            $ACLEntrySIDMatches | ForEach-Object {$ACLEntrySID = $_.value}

            If ($ACLEntrySID)
            {
                $ACLEntrySID
            }
            Else
            {
                "Not inherited - No SID"
            }
        }
    }
    
    return $null
}

# about: Used to ask user if he want to run script.
# input: string to present the user
# output: true if user wants to continue
# sample: Approve-Execute("sample text")
function Approve-Execute
{
    param (
        [parameter(Mandatory = $false)]
        [ValidateLength(2, 3)]
        [string] $DefaultAction = "Yes",

        [parameter(Mandatory = $false)]
        [string] $title = "Executing: " + ((Split-Path -Leaf $MyInvocation.ScriptName).TrimEnd(".ps1")),

        [parameter(Mandatory = $false)]
        [string] $question = "Are you sure you want to proceed?"
    )

    $choices  = "&Yes", "&No"
    $default = 0
    if ($DefaultAction -like "No") { $default = 1 }

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, $default)

    if ($decision -eq $default)
    {
        return $true
    }

    return $false
}

# about: check if file such as an *.exe exists
# input: path to file
# output: warning message if file not found
# sample: Test-File("C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe")
function Test-File
{
    param (
        [parameter(Mandatory = $true)]
        [bool] $status,

        [parameter(Mandatory = $true)]
        [string] $FilePath
    )

    if ($status)
    {
        $ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)

        if (!([System.IO.File]::Exists($ExpandedPath)))
        {
            $Executable = Split-Path -Path $ExpandedPath -Leaf
            Write-Warning "Executable '$Executable' not found, rule won't have any effect
            Searched path was: $ExpandedPath"
        }
    }
}

# about: find installation directory for given program
# input: predefined program name
# output: installation directory if found, otherwise empty string
# sample: Find-Installation "Office"
function Find-Installation
{
    param (
        [parameter(Mandatory = $true)]
        [string] $Program
    )

    # NOTE: we want to preserve system environment variables for firewall GUI,
    # otherwise firewall GUI will show full paths which is not desired for sorting reasons
    switch -Wildcard ($Program)
    {
        "Office"
        {
            [string] $OfficeRoot = "%ProgramFiles%\Microsoft Office\root\Office16"
            if (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($OfficeRoot)))
            {
                return $OfficeRoot
            }
            $OfficeRoot = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
            if (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($OfficeRoot)))
            {
                return $OfficeRoot
            }
            break
        }
        "TeamViewer"
        {
            [string] $TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"
            if (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($TeamViewerRoot)))
            {
                return $TeamViewerRoot
            }
            break
        }
        Default
        {
            Write-Warning "Parameter '$Program' not recognized"
            return ""
        }
    }

    Write-Warning "Installation directory for '$Program' not found"
    $Script = (Get-PSCallStack)[2].Command

    Write-Host "If you installed $Program elsewhere adjust the path in $Script and re-run this script later again,
otherwise ignore this warning if you don't have $Program installed." -ForegroundColor Green
    if (Approve-Execute "No" "Rule group for $Program" "Do you want to force loading these rules anyway?") { exit }

    return ""
}

# about: test if given installation directory is valid
# input: predefined program name and path to program (excluding executable)
# output: if test OK same path, if not try to update path, else return given path back
# sample: Test-Installation "Office" "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
function Test-Installation
{
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string] $Program,

        [parameter(Mandatory = $true, Position = 1)]
        [ref] $FilePath
    )

    if (!(Test-Path -Path $FilePath))
    {
        $InstallRoot = Find-Installation $Program
        if (![string]::IsNullOrEmpty($InstallRoot))
        {
            $FilePath.Value = $InstallRoot
            return $true
        }

        return $false
    }

    return $true
}

#
# Predefined project wide variables
#

# Windows 10 and above
New-Variable -Name Platform -Option Constant -Scope Global -Value "10.0+"
# Local Group Policy
New-Variable -Name PolicyStore -Option Constant -Scope Global -Value "localhost"
# Stop executing if error
New-Variable -Name OnError -Option Constant -Scope Global -Value "Stop"
# To add rules to firewall for real set to false
New-Variable -Name Debug -Scope Global -Value $true
# To prompt for each rule set to true
New-Variable -Name Execute -Scope Global -Value $false
# Most used program
New-Variable -Name ServiceHost -Option Constant -Scope Global -Value "%SystemRoot%\System32\svchost.exe"
# Default network interface card
New-Variable -Name Interface -Option Constant -Scope Global -Value "Wired, Wireless"

# Network IP configuration (get only IPv4 config, index 0, if IPv6 is configured it's at index 1)
New-Variable -Name NICConfig -Option Constant -Scope Global -Value (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway -ne $null})
New-Variable -Name LocalHost -Option Constant -Scope Global -Value $NICConfig.IPAddress[0]
New-Variable -Name SubnetMask -Option Constant -Scope Global -Value $NICConfig.IPSubnet[0]
New-Variable -Name BroadCast -Option Constant -Scope Global -Value (Get-NetworkSummary $LocalHost $SubnetMask | Select-Object -ExpandProperty BroadcastAddress | Select-Object -ExpandProperty IPAddressToString)

# NOTE: -LocalUser, -Owner etc. firewall parameters accept SDDL format only
# For more complete list see: https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
# If link is not valid google out: "well known SID msdn" or similar search string
# Another way to get information of SDDL string is to create a test rule with that string and see what turns out.

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

#
# Exports
#

Export-ModuleMember -Function Get-UserAccounts
Export-ModuleMember -Function Get-UserNames
Export-ModuleMember -Function Get-UserSID
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function Get-AppSID
Export-ModuleMember -Function Get-UserSDDL
Export-ModuleMember -Function Get-AccountSDDL
Export-ModuleMember -Function Convert-SDDLToACL
Export-ModuleMember -Function Show-SDDL
Export-ModuleMember -Function Approve-Execute
Export-ModuleMember -Function Test-File
Export-ModuleMember -Function Find-Installation
Export-ModuleMember -Function Test-Installation

Export-ModuleMember -Variable Platform
Export-ModuleMember -Variable PolicyStore
Export-ModuleMember -Variable OnError
Export-ModuleMember -Variable Debug
Export-ModuleMember -Variable Execute
Export-ModuleMember -Variable ServiceHost
Export-ModuleMember -Variable Interface

Export-ModuleMember -Variable NICConfig
Export-ModuleMember -Variable LocalHost
Export-ModuleMember -Variable SubnetMask
Export-ModuleMember -Variable BroadCast
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

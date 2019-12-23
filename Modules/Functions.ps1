
# TODO: convert to module, and import where needed

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
    $DisabledAccounts = "" #Get-WmiObject -Class Win32_UserAccount -Filter "Disabled=True" | Select-Object -ExpandProperty Caption

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
# Input: Array of user computer accounts in form of: COMPUTERNAME\USERNAME
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
# input: "PackageFamilyName" string
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

# ParseSDDL returns SDDL based on "object"
# Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1/
# sample: see Test\Parse-SDDL.ps1 for example

function Parse-SDDL
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
# sample: RunThis("sample text")
function RunThis
{
    param (
        [parameter(Mandatory = $false)]
        [ValidateLength(1, 300)]
        [string] $info
    )

    if($info)
    {
        $title = $info
    }
    else
    {
        $title = "Executing: "
        $title += Split-Path -Leaf $MyInvocation.ScriptName
    }

    $question = "Are you sure you want to proceed?"
    $choices  = "&Yes", "&No"

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
    if ($decision -eq 0)
    {
        return $true
    }
    else
    {
        return $false
    }
}

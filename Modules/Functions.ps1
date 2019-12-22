
# TODO: convert to module, and import where needed

# about: get computer accounts for a giver user group
# Input: User group on local computer
# output: Array of enabled user accounts in specified group, in form of COMPUTERNAME\USERNAME
# sample: Get-UserAccounts("Administrators")
# TODO: multiple enabled accounts format
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
            $EnabledAccounts = $EnabledAccounts += $Account
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
        $UserNames = $UserNames += $Account.split("\")[1]
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
# sample: Get-AppSID("Microsoft.MicrosoftEdge_8wekyb3d8bbwe")
function Get-AppSID ($AppName)
{
    $Packages = "C:\Users\$UserName\AppData\Local\Packages"
    $ACL = Get-ACL "$Packages\$AppName\AC"
    $ACE = $ACL.Access.IdentityReference.Value
    
    $ACE | ForEach-Object {
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

# Convert-SDDLToACL returns the ACEs of the generated security descriptor object.
# Credits to: https://stackoverflow.com/questions/48406474/return-user-data-from-sid
# Sample usage:
# You can extract the user/group/principal names from that list like this:

# $sddl = "O:LSD:(A;;CC;;;SY)(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)"
# Convert-SDDLToACL $sddl | 
# Select-Object -Expand IdentityReference |
# Select-Object -Expand Value
function Convert-SDDLToACL
{
    [Cmdletbinding()]
    Param
    (
        #One or more strings of SDDL syntax.
        [string[]] $SDDLString
    )

    foreach ($SDDL in $SDDLString)
    {
        $ACLObject = New-Object -Type Security.AccessControl.DirectorySecurity
        $ACLObject.SetSecurityDescriptorSddlForm($SDDL)
        $ACLObject.Access
    }
}

# ParseSDDL returns SDDL based on "object"
# Sample usage:
# Experiment with these different path values to see what the ACL objects do
# Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1/

<#
$path = "C:\users\User\" #Not inherited
$path = "C:\users\username\desktop\" #Inherited
$path = "HKCU:\" #Not Inherited
$path = "HKCU:\Software" #Inherited
$path = "HKLM:\" #Not Inherited

"`n---Path:"
$Path

$ACL = Get-ACL $path
"`n---Access To string:"
$ACL.AccessToString

"`n---Access entry details:"
$ACL.Access | fl *

"`n---SDDL:"
$ACL.SDDL

# Call with named parameter binding 
$ACL | ParseSDDL
# Or call with parameter string
ParseSDDL $ACL.SDDL
#>
function ParseSDDL
{
    [CmdletBinding()]
    param ([Parameter(valueFromPipelineByPropertyName=$true)]$SDDL)

    $SDDLSplit = $SDDL.Split("(")

    "`n---SDDL Split:"
    $SDDLSplit

    "`n---SDDL SID Parsing:"
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

#
# Used to ask user if he want to run script.
#
function RunThis($str)
{
    if($str)
    {
        $title = $str
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

# This method is deprecated because it doesn't work with system apps, it's here only for reference.
# Function based on ParseSDDL to obtain SID's for store apps
# it takes install location of the app, checks all the SID's of all the stuff in directory
# out of this result it returns only the relevant SID, which is then additionally modified
# It's the ugly hack made of trial and error, it may not work in further windows versions.
function Get-AppSID_Deprecated ($AppName)
{
    $ACL = Get-ACL "$AppName"
    $SDDLSplit = $ACL.SDDL.Split("(")
    $ACLEntrySID = $null

    # Skip index 0 where owner and/or primary group are stored
    For ($i=1; $i -lt $SDDLSplit.Length; $i++)
    {
        $ACLSplit = $SDDLSplit[$i].Split(";")

        if ($ACLSplit[1])
        {
            # if it contains 'ID' it's inherited, ignore
            If (!$ACLSplit[1].Contains("ID"))
            {

                # Remove the trailing ")"
                $ACLEntry = $ACLSplit[5].TrimEnd(")")

                # Parse out the SID using RegEx
                $ACLEntrySIDMatches = [regex]::Matches($ACLEntry,"(S(-\d+){2,10})")
                $ACLEntrySIDMatches | ForEach-Object {$ACLEntrySID = $_.value}

                If ($ACLEntrySID)
                {
                    # Final hack!!
                    $ACLEntrySID = $ACLEntrySID -replace "S-1-15-3", "S-1-15-2"
                    return $ACLEntrySID
                }
            }
        }
    }
}

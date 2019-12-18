
# TODO: convert to module, and import where needed

# Get SID for giver user name, example: Get-UserSID("TestUser")
function Get-UserSID($UserName)
{
    $NTAccount = New-Object System.Security.Principal.NTAccount($UserName)
    $SID = ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()
    return $SID
}

# Returns SDDL of specified local user or multiple users
# Sample usage:
# New-NetFirewallRule -DisplayName "BlockWWW" -Action Block -LocalUser (Get-UserSDDL user1, user2) -Protocol TCP -Direction Outbound -RemotePort 80, 443
# Credits to: https://stackoverflow.com/questions/49608182/powershell-new-netfirewallrule-with-localuser-example
function Get-UserSDDL
{
    param([string[]]$UserName)
  
    $SDDL = 'D:{0}'
  
    $ACEs = foreach($Name in $UserName)
    {
        try
        {
            $LocalUser = Get-LocalUser -Name $UserName -ErrorAction Stop
            '(A;;CC;;;{0})' -f $LocalUser.Sid.Value
        }
        catch
        {
            Write-Warning "Local user '$Username' not found"
            continue
        }
    }
    return $SDDL -f ($ACEs -join '')
}

#
# Returns SDDL from multiple Accounts, in form of: COMPUTERNAME\USERNAME
# Sample usage:
# Get-SDDL-FromAccounts @("NT AUTHORITY\SYSTEM", "MY_DESKTOP\MY_USERNAME")
#
function Get-SDDLFromAccounts($Accounts)
{
    $SDDL = "D:"

    foreach ($UserEntry in $Accounts)
    {
        $Domain = ($UserEntry.split("\"))[0]
        $User = ($UserEntry.split("\"))[1]

        $NTAccount = New-Object System.Security.Principal.NTAccount($Domain, $User)
        $SID = ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).Value
    
        if (!$SID)
        {
            "User $User cannot be resolved to a SID. Does the account exist?"
            continue
        }
    
        $SDDL += '(A;;CC;;;{0})' -f $SID

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
Function Convert-SDDLToACL
{
    [Cmdletbinding()]
    Param
    (
        #One or more strings of SDDL syntax.
        [string[]]$SDDLString
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
"`n---Access To String:"
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

# Function based on ParseSDDL to obtain SID's for store apps
# it takes install location of the app, checks all the SID's of all the stuff in directory
# out of this result it returns only the relevant SID, which is then additionally modified
# It's the ugly hack made of trial and error, it may not work in further windows versions.
function Get-AppSID ($AppName)
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


# TODO: convert to module, and import where needed

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

# Get-UserSDDL sample usage:
# New-NetFirewallRule -DisplayName "BLOCKWWW" -LocalUser (Get-FirewallLocalUserSddl user1,user2) -Direction Outbound -LocalPort 80,443 -Protocol TCP -Action Block

# Credits to: https://stackoverflow.com/questions/48406474/return-user-data-from-sid
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

# Convert-SDDLToACL sample usage:
# The function returns the ACEs of the generated security descriptor object.
# You can extract the user/group/principal names from that list like this:

# $sddl = "O:LSD:(A;;CC;;;SY)(A;;CC;;;S-1-5-21-3400361277-1888300462-2581876478-1002)"
# Convert-SDDLToACL $sddl | 
# Select-Object -Expand IdentityReference |
# Select-Object -Expand Value

  # Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1/
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

# ParseSDDL sample usage:
# Experiment with these different path values to see what the ACL objects do

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

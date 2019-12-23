
# This method is deprecated because it doesn't work with system apps, it's here only for reference.
# Function based on Show-SDDL to obtain SID's for store apps
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

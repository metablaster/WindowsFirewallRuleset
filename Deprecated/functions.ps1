
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems,
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

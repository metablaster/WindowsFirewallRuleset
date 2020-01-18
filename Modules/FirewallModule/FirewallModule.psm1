
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

# about: update context for Approve-Execute
# input: rule traffic direction and rule group
# output: none, global context variable is set
# sample: Update-Context $Direction $Group
function Update-Context
{
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string] $IPVersion,

        [parameter(Mandatory = $true, Position = 1)]
        [string] $Direction,

        [parameter(Mandatory = $false, Position = 2)]
        [string] $Group = $null
    )

    [string] $NewContext = "IPv" + "$IPVersion" + "." + $Direction
    if ($Group)
    {
        $NewContext += " -> " + $Group
    }

    Set-Variable -Name Context -Scope Global -Value $NewContext
}

# about: Used to ask user if he wants to run script.
# input: string to present the user
# output: true if user wants to continue
# sample: Approve-Execute("sample text")
# TODO: implement help [?]
function Approve-Execute
{
    param (
        [parameter(Mandatory = $false)]
        [ValidateLength(2, 3)]
        [string] $DefaultAction = "Yes",

        [parameter(Mandatory = $false)]
        [string] $title = "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName),

        [parameter(Mandatory = $false)]
        [string] $question = "Do you want to load this ruleset?"
    )

    $choices  = "&Yes", "&No"
    $default = 0
    if ($DefaultAction -like "No") { $default = 1 }

    $title += " [$Context]"
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, $default)

    if ($decision -eq $default)
    {
        return $true
    }

    return $false
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


#
# Module variables
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

# Global execution context, used in Approve-Execute
New-Variable -Name Context -Scope Global -Value "Context not set"
# Global variable to tell if all scripts ran clean
New-Variable -Name WarningsDetected -Scope Global -Value $false

#
# Function exports
#

Export-ModuleMember -Function Approve-Execute
Export-ModuleMember -Function Update-Context
Export-ModuleMember -Function Convert-SDDLToACL
Export-ModuleMember -Function Show-SDDL

#
# Variable exports
#

Export-ModuleMember -Variable Platform
Export-ModuleMember -Variable PolicyStore
Export-ModuleMember -Variable OnError
Export-ModuleMember -Variable Debug
Export-ModuleMember -Variable Execute
Export-ModuleMember -Variable ServiceHost
Export-ModuleMember -Variable Interface

Export-ModuleMember -Variable Context
Export-ModuleMember -Variable WarningsDetected

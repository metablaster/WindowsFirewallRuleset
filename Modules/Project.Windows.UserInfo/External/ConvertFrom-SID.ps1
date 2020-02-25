
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame
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

<#
.SYNOPSIS
Convert SID to user or computer account name
.DESCRIPTION
Convert SID to user or computer account name
.PARAMETER SIDArray
One or more SIDs to convert
.EXAMPLE
ConvertFrom-SID S-1-5-21-2139171146-395215898-1246945465-2359
.EXAMPLE
'S-1-5-32-580' | ConvertFrom-SID
.INPUTS
One or multiple SID's
.OUTPUTS
PSObject composed of SID and user or account
.NOTES
SID conversion for well known SIDs from http://support.microsoft.com/kb/243330
Original code link: https://github.com/RamblingCookieMonster/PowerShell

TODO: Need to handle more NT AUTHORITY users and similar
TODO: need to improve to have consitent output ie. DOMAIN\USER, see test results

Changes by metablaster:
add verbose and debug output
remove try and empty catch by setting better approach
rename parameter
format code style to project defaults and added few more comments
removed unnecessary parantheses
#>
function ConvertFrom-SID
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
        [string[]] $SIDArray
    )

    begin
    {
        # well known SIDs name/value map
        # TODO: script scope variable?
        $WellKnownSIDs = @{
            'S-1-0' = 'Null Authority'
            'S-1-0-0' = 'Nobody'
            'S-1-1' = 'World Authority'
            'S-1-1-0' = 'Everyone'
            'S-1-2' = 'Local Authority'
            'S-1-2-0' = 'Local'
            'S-1-2-1' = 'Console Logon'
            'S-1-3' = 'Creator Authority'
            'S-1-3-0' = 'Creator Owner'
            'S-1-3-1' = 'Creator Group'
            'S-1-3-2' = 'Creator Owner Server'
            'S-1-3-3' = 'Creator Group Server'
            'S-1-3-4' = 'Owner Rights'
            'S-1-5-80-0' = 'All Services'
            'S-1-4' = 'Non-unique Authority'
            'S-1-5' = 'NT Authority'
            'S-1-5-1' = 'Dialup'
            'S-1-5-2' = 'Network'
            'S-1-5-3' = 'Batch'
            'S-1-5-4' = 'Interactive'
            'S-1-5-6' = 'Service'
            'S-1-5-7' = 'Anonymous'
            'S-1-5-8' = 'Proxy'
            'S-1-5-9' = 'Enterprise Domain Controllers'
            'S-1-5-10' = 'Principal Self'
            'S-1-5-11' = 'Authenticated Users'
            'S-1-5-12' = 'Restricted Code'
            'S-1-5-13' = 'Terminal Server Users'
            'S-1-5-14' = 'Remote Interactive Logon'
            'S-1-5-15' = 'This Organization'
            'S-1-5-17' = 'This Organization'
            'S-1-5-18' = 'Local System'
            'S-1-5-19' = 'NT Authority'
            'S-1-5-20' = 'NT Authority'
            'S-1-5-21-500' = 'Administrator'
            'S-1-5-21-501' = 'Guest'
            'S-1-5-21-502' = 'KRBTGT'
            'S-1-5-21-512' = 'Domain Admins'
            'S-1-5-21-513' = 'Domain Users'
            'S-1-5-21-514' = 'Domain Guests'
            'S-1-5-21-515' = 'Domain Computers'
            'S-1-5-21-516' = 'Domain Controllers'
            'S-1-5-21-517' = 'Cert Publishers'
            'S-1-5-21-518' = 'Schema Admins'
            'S-1-5-21-519' = 'Enterprise Admins'
            'S-1-5-21-520' = 'Group Policy Creator Owners'
            'S-1-5-21-522' = 'Cloneable Domain Controllers'
            'S-1-5-21-526' = 'Key Admins'
            'S-1-5-21-527' = 'Enterprise Key Admins'
            'S-1-5-21-553' = 'RAS and IAS Servers'
            'S-1-5-21-571' = 'Allowed RODC Password Replication Group'
            'S-1-5-21-572' = 'Denied RODC Password Replication Group'
            'S-1-5-32-544' = 'Administrators'
            'S-1-5-32-545' = 'Users'
            'S-1-5-32-546' = 'Guests'
            'S-1-5-32-547' = 'Power Users'
            'S-1-5-32-548' = 'Account Operators'
            'S-1-5-32-549' = 'Server Operators'
            'S-1-5-32-550' = 'Print Operators'
            'S-1-5-32-551' = 'Backup Operators'
            'S-1-5-32-552' = 'Replicators'
            'S-1-5-64-10' = 'NTLM Authentication'
            'S-1-5-64-14' = 'SChannel Authentication'
            'S-1-5-64-21' = 'Digest Authority'
            'S-1-5-80' = 'NT Service'
            'S-1-5-83-0' = 'NT VIRTUAL MACHINE\Virtual Machines'
            'S-1-16-0' = 'Untrusted Mandatory Level'
            'S-1-16-4096' = 'Low Mandatory Level'
            'S-1-16-8192' = 'Medium Mandatory Level'
            'S-1-16-8448' = 'Medium Plus Mandatory Level'
            'S-1-16-12288' = 'High Mandatory Level'
            'S-1-16-16384' = 'System Mandatory Level'
            'S-1-16-20480' = 'Protected Process Mandatory Level'
            'S-1-16-28672' = 'Secure Process Mandatory Level'
            'S-1-5-32-554' = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'S-1-5-32-555' = 'BUILTIN\Remote Desktop Users'
            'S-1-5-32-556' = 'BUILTIN\Network Configuration Operators'
            'S-1-5-32-557' = 'BUILTIN\Incoming Forest Trust Builders'
            'S-1-5-32-558' = 'BUILTIN\Performance Monitor Users'
            'S-1-5-32-559' = 'BUILTIN\Performance Log Users'
            'S-1-5-32-560' = 'BUILTIN\Windows Authorization Access Group'
            'S-1-5-32-561' = 'BUILTIN\Terminal Server License Servers'
            'S-1-5-32-562' = 'BUILTIN\Distributed COM Users'
            'S-1-5-32-569' = 'BUILTIN\Cryptographic Operators'
            'S-1-5-32-573' = 'BUILTIN\Event Log Readers'
            'S-1-5-32-574' = 'BUILTIN\Certificate Service DCOM Access'
            'S-1-5-32-575' = 'BUILTIN\RDS Remote Access Servers'
            'S-1-5-32-576' = 'BUILTIN\RDS Endpoint Servers'
            'S-1-5-32-577' = 'BUILTIN\RDS Management Servers'
            'S-1-5-32-578' = 'BUILTIN\Hyper-V Administrators'
            'S-1-5-32-579' = 'BUILTIN\Access Control Assistance Operators'
            'S-1-5-32-580' = 'BUILTIN\Remote Management Users'
        }
    }

    process
    {
        Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

        $Result = @()
        # loop through provided SIDs
        foreach($SID in $SIDArray)
        {
            Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $SID"

            # Make a copy since modified SID may not be used
            $FullSID = $SID

            # Check for domain contextual SID's
            $IsDomain = $false

            if ($SID.Length -gt 8)
            {
                if($SID.Remove(8) -eq "S-1-5-21")
                {
                    Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is domain SID"

                    $IsDomain = $true
                    $Suffix = $SID.Substring($SID.Length - 4) # ie. 1003
                    $SID = $SID.Remove(8) + $Suffix
                }
                else
                {
                    Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is not domain SID"
                }
            }

            # Map name to well known sid. If this fails, use .net to get the account
            $Name = $WellKnownSIDs[$SID]

            if($Name)
            {
                Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is well known SID"
            }
            else
            {
                Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is not well known SID"
                if($IsDomain)
                {
                    $SID = $FullSID
                }

                # try to translate the SID to an account
                try
                {
                    Write-Debug -Message "[$($MyInvocation.InvocationName)] Translating SID: $SID"

                    $SIDObject = New-Object System.Security.Principal.SecurityIdentifier($SID)
                    $Name = $SIDObject.Translate([System.Security.Principal.NTAccount]).Value
                }
                catch
                {
                    $Name = "Not a valid SID or could not be identified"
                    Write-Warning -Message "$SID is not a valid SID or could not be identified"
                }
            }

            # Display the results
            $Result += New-Object -TypeName PSObject -Property @{
                SID = $FullSID
                Name = $Name
            }
        }

        return $Result
    }
}

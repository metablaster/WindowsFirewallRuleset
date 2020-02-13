
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

# Includes
Import-Module -Name $PSScriptRoot\..\Indented.Net.IP

# TODO: what happens in Get-AdapterConfig and other functions that call it if there are multiple configured adapters?

<#
.SYNOPSIS
get localhost name
.EXAMPLE
Get-ComputerName
.INPUTS
None. You cannot pipe objects to Get-ComputerName
.OUTPUTS
System.String[] computer name in form of COMPUTERNAME
.NOTES
TODO: implement queriying computers on network by specifying IP address
#>
function Get-ComputerName
{
    return Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Name
}

<#
.SYNOPSIS
helper method to get adapter configuration
.EXAMPLE
Get-AdapterConfig
.INPUTS
None. You cannot pipe objects to Get-AdapterConfig
.OUTPUTS
System.Management.ManagementObject#root\cimv2\Win32_NetworkAdapterConfiguration
.NOTES
TODO: implement queriying computers on network by specifying IP address
#>
function Get-AdapterConfig
{
    return Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway }
}

<#
.SYNOPSIS
helper method to get IP address of local machine
.PARAMETER IPVersion
IP version number, 4 or 6
.EXAMPLE
Get-IPAddress 4
.EXAMPLE
Get-IPAddress 6
.INPUTS
None. You cannot pipe objects to Get-IPAddress
.OUTPUTS
System.String IP Address
.NOTES
TODO: implement queriying computers on network by specifying COMPUTERNAME
#>
function Get-IPAddress
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet(4, 6)]
        [int16] $IPVersion
    )

    $AdapterConfig = Get-AdapterConfig

    # IPv4 address is at index 0, if IPv6 if configured it's at index 1)
    if ($IPVersion -eq 4)
    {
        return $AdapterConfig.IPAddress[0]
    }
    elseif ($AdapterConfig.IPAddress[1])
    {
        return $AdapterConfig.IPAddress[1]
    }
    else
    {
        Write-Error -Category NotEnabled -TargetObject $AdapterConfig -Message "IPv6 not configured on adapter"
        return $null
    }
}

<#
.SYNOPSIS
helper method to get broadcast address
.EXAMPLE
Get-Broadcast
.INPUTS
None. You cannot pipe objects to Get-Broadcast
.OUTPUTS
System.String Broadcast address
#>
function Get-Broadcast
{
    $AdapterConfig = Get-AdapterConfig

    # Broadcast address makes sense only for IPv4
    Get-NetworkSummary $AdapterConfig.IPAddress[0] $AdapterConfig.IPSubnet[0] |
    Select-Object -ExpandProperty BroadcastAddress | Select-Object -ExpandProperty IPAddressToString
}

#
# Module variables
#

# $DebugPreference = "Continue"

#
# Function exports
#

Export-ModuleMember -Function Get-ComputerName
Export-ModuleMember -Function Get-IPAddress
Export-ModuleMember -Function Get-AdapterConfig
Export-ModuleMember -Function Get-Broadcast

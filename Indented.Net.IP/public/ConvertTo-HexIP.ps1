function ConvertTo-HexIP {
    <#
    .SYNOPSIS
        Convert a dotted decimal IP address into a hexadecimal string.
    .DESCRIPTION
        ConvertTo-HexIP takes a dotted decimal IP and returns a single hexadecimal string value.
    .PARAMETER IPAddress
        An IP Address to convert.
    .INPUTS
        System.Net.IPAddress
    .EXAMPLE
        ConvertTo-HexIP 192.168.0.1

        Returns the hexadecimal string c0a80001.
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [IPAddress]$IPAddress
    )

    process {
        $bytes = $IPAddress.GetAddressBytes()
        [Array]::Reverse($bytes)
        '{0:x8}' -f [BitConverter]::ToUInt32($bytes, 0)
    }
}
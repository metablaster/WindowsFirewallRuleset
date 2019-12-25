function ConvertFrom-HexIP {
    <#
    .SYNOPSIS
        Converts a hexadecimal IP address into a dotted decimal string.
    .DESCRIPTION
        ConvertFrom-HexIP takes a hexadecimal string and returns a dotted decimal IP address. An intermediate call is made to ConvertTo-DottedDecimalIP.
    .INPUTS
        System.String
    .EXAMPLE
        ConvertFrom-HexIP c0a80001

        Returns the IP address 192.168.0.1.
    #>

    [CmdletBinding()]
    [OutputType([IPAddress])]
    param (
        # An IP Address to convert.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [ValidatePattern('^(0x)?[0-9a-f]{8}$')]
        [String]$IPAddress
    )

    process {
        [IPAddress][UInt64][Convert]::ToUInt32($IPAddress, 16)
    }
}
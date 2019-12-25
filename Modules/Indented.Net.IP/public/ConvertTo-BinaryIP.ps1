function ConvertTo-BinaryIP {
    <#
    .SYNOPSIS
        Converts a Decimal IP address into a binary format.
    .DESCRIPTION
        ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.
    .INPUTS
        System.Net.IPAddress
    .EXAMPLE
        ConvertTo-BinaryIP 1.2.3.4

        Convert an IP address to a binary format.
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param (
        # An IP Address to convert.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [IPAddress]$IPAddress
    )

    process {
        $binary = foreach ($byte in $IPAddress.GetAddressBytes()) {
            [Convert]::ToString($byte, 2).PadLeft(8, '0')
        }
        $binary -join '.'
    }
}
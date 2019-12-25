function ConvertTo-DecimalIP {
    <#
    .SYNOPSIS
        Converts a Decimal IP address into a 32-bit unsigned integer.
    .DESCRIPTION
        ConvertTo-DecimalIP takes a decimal IP, uses a shift operation on each octet and returns a single UInt32 value.
    .INPUTS
        System.Net.IPAddress
    .EXAMPLE
        ConvertTo-DecimalIP 1.2.3.4

        Converts an IP address to an unsigned 32-bit integer value.
    #>

    [CmdletBinding()]
    [OutputType([UInt32])]
    param (
        # An IP Address to convert.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline )]
        [IPAddress]$IPAddress
    )

    process {
        [UInt32]([IPAddress]::HostToNetworkOrder($IPAddress.Address) -shr 32 -band [UInt32]::MaxValue)
    }
}
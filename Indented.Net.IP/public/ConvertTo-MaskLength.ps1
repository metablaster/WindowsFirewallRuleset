function ConvertTo-MaskLength {
    <#
    .SYNOPSIS
        Convert a dotted-decimal subnet mask to a mask length.
    .DESCRIPTION
        A count of the number of 1's in a binary string.
    .INPUTS
        System.Net.IPAddress
    .EXAMPLE
        ConvertTo-MaskLength 255.255.255.0

        Returns 24, the length of the mask in bits.
    #>

    [CmdletBinding()]
    [OutputType([Int32])]
    param (
        # A subnet mask to convert into length.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [Alias("Mask")]
        [IPAddress]$SubnetMask
    )

    process {
        [Convert]::ToString([IPAddress]::HostToNetworkOrder($SubnetMask.Address), 2).Replace('0', '').Length
    }
}
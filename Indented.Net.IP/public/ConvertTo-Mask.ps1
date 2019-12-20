function ConvertTo-Mask {
    <#
    .SYNOPSIS
        Convert a mask length to a dotted-decimal subnet mask.
    .DESCRIPTION
        ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging between 0 and 32.

        ConvertTo-Mask creates a binary string from the length, converts the string to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.
    .INPUTS
        System.Int32
    .EXAMPLE
        ConvertTo-Mask 24

        Returns the dotted-decimal form of the mask, 255.255.255.0.
    #>

    [CmdletBinding()]
    [OutputType([IPAddress])]
    param (
        # The number of bits which must be masked.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [Alias('Length')]
        [ValidateRange(0, 32)]
        [Byte]$MaskLength
    )

    process {
        [IPAddress][UInt64][Convert]::ToUInt32(('1' * $MaskLength).PadRight(32, '0'), 2)
    }
}
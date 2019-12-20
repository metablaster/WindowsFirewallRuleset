function Get-BroadcastAddress {
    <#
    .SYNOPSIS
        Get the broadcast address for a network range.
    .DESCRIPTION
        Get-BroadcastAddress returns the broadcast address for a subnet by performing a bitwise AND operation against the decimal forms of the IP address and inverted subnet mask.
    .INPUTS
        System.String
    .EXAMPLE
        Get-BroadcastAddress 192.168.0.243 255.255.255.0

        Returns the address 192.168.0.255.
    .EXAMPLE
        Get-BroadcastAddress 10.0.9/22

        Returns the address 10.0.11.255.
    .EXAMPLE
        Get-BroadcastAddress 0/0

        Returns the address 255.255.255.255.
    .EXAMPLE
        Get-BroadcastAddress "10.0.0.42 255.255.255.252"

        Input values are automatically split into IP address and subnet mask. Returns the address 10.0.0.43.
    #>

    [CmdletBinding()]
    [OutputType([IPAddress])]
    param (
        # Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [String]$IPAddress,

        # A subnet mask as an IP address.
        [Parameter(Position = 2)]
        [String]$SubnetMask
    )

    process {
        try {
            $network = ConvertToNetwork @psboundparameters

            $networkAddress = [IPAddress]($network.IPAddress.Address -band $network.SubnetMask.Address)

            return [IPAddress](
                $networkAddress.Address -bor
                -bnot $network.SubnetMask.Address -band
                -bnot ([Int64][UInt32]::MaxValue -shl 32)
            )
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}
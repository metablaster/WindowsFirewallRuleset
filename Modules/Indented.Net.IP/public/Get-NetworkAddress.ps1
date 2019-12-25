function Get-NetworkAddress {
    <#
    .SYNOPSIS
        Get the network address for a network range.
    .DESCRIPTION
        Get-NetworkAddress returns the network address for a subnet by performing a bitwise AND operation against the decimal forms of the IP address and subnet mask.
    .PARAMETER IPAddress
        Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
    .PARAMETER SubnetMask
        A subnet mask as an IP address.
    .INPUTS
        System.String
    .EXAMPLE
        Get-NetworkAddress 192.168.0.243 255.255.255.0

        Returns the address 192.168.0.0.
    .EXAMPLE
        Get-NetworkAddress 10.0.9/22

        Returns the address 10.0.8.0.
    .EXAMPLE
        Get-NetworkAddress "10.0.23.21 255.255.255.224"

        Input values are automatically split into IP address and subnet mask. Returns the address 10.0.23.0.
    #>

    [CmdletBinding()]
    [OutputType([IPAddress])]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [String]$IPAddress,

        [Parameter(Position = 2)]
        [String]$SubnetMask
    )

    process {
        try {
            $network = ConvertToNetwork @psboundparameters

            return [IPAddress]($network.IPAddress.Address -band $network.SubnetMask.Address)
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}
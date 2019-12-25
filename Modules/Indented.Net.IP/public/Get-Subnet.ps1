function Get-Subnet {
    <#
    .SYNOPSIS
        Get a list of subnets of a given size within a defined supernet.
    .DESCRIPTION
        Generates a list of subnets for a given network range using either the address class or a user-specified value.
    .EXAMPLE
        Get-Subnet 10.0.0.0 255.255.255.0 -NewSubnetMask 255.255.255.192

        Four /26 networks are returned.
    .EXAMPLE
        Get-Subnet 0/22 -NewSubnetMask 24

        64 /24 networks are returned.
    .NOTES
        Change log:
            07/03/2016 - Chris Dent - Cleaned up code, added tests.
            12/12/2015 - Chris Dent - Redesigned.
            13/10/2011 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType('Indented.Net.IP.Subnet')]
    param (
        # Any address in the super-net range. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$IPAddress,

        # The subnet mask of the network to split. Mandatory if the subnet mask is not included in the IPAddress parameter.
        [Parameter(Position = 2)]
        [String]$SubnetMask,

        # Split the existing network described by the IPAddress and subnet mask using this mask.
        [Parameter(Mandatory = $true)]
        [String]$NewSubnetMask
    )

    $null = $psboundparameters.Remove('NewSubnetMask')
    try {
        $network = ConvertToNetwork @psboundparameters
        $newNetwork = ConvertToNetwork 0 $NewSubnetMask
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }

    if ($network.MaskLength -gt $newNetwork.MaskLength) {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [ArgumentException]'The subnet mask of the new network is shorter (masks fewer addresses) than the subnet mask of the existing network.',
            'NewSubnetMaskTooShort',
            'InvalidArgument',
            $NewNetwork.MaskLength
        )
        $pscmdlet.ThrowTerminatingError($errorRecord)
    }

    $numberOfNets = [Math]::Pow(2, ($newNetwork.MaskLength - $network.MaskLength))
    $numberOfAddresses = [Math]::Pow(2, (32 - $newNetwork.MaskLength))

    $decimalAddress = ConvertTo-DecimalIP (Get-NetworkAddress $network.ToString())
    for ($i = 0; $i -lt $numberOfNets; $i++) {
        $networkAddress = ConvertTo-DottedDecimalIP $decimalAddress

        ConvertTo-Subnet -IPAddress $networkAddress -SubnetMask $newNetwork.MaskLength

        $decimalAddress += $numberOfAddresses
    }
}
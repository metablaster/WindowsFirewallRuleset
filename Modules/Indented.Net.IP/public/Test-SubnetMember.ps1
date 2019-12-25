function Test-SubnetMember {
    <#
    .SYNOPSIS
        Tests an IP address to determine if it falls within IP address range.
    .DESCRIPTION
        Test-SubnetMember attempts to determine whether or not an address or range falls within another range. The network and broadcast address are calculated the converted to decimal then compared to the decimal form of the submitted address.
    .EXAMPLE
        Test-SubnetMember -SubjectIPAddress 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/16

        Returns true as the subject network can be contained within the object network.
    .EXAMPLE
        Test-SubnetMember -SubjectIPAddress 192.168.0.0/16 -ObjectIPAddress 192.168.0.0/24

        Returns false as the subject network is larger the object network.
    .EXAMPLE
        Test-SubnetMember -SubjectIPAddress 10.2.3.4/32 -ObjectIPAddress 10.0.0.0/8

        Returns true as the subject IP address is within the object network.
    .EXAMPLE
        Test-SubnetMember -SubjectIPAddress 255.255.255.255 -ObjectIPAddress 0/0

        Returns true as the subject IP address is the last in the object network range.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        # A representation of the subject, the network to be tested. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory, Position = 1)]
        [String]$SubjectIPAddress,

        # A representation of the object, the network to test against. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory, Position = 2)]
        [String]$ObjectIPAddress,

        # A subnet mask as an IP address.
        [String]$SubjectSubnetMask,

        # A subnet mask as an IP address.
        [String]$ObjectSubnetMask
    )

    try {
        $subjectNetwork = ConvertToNetwork $SubjectIPAddress $SubjectSubnetMask
        $objectNetwork = ConvertToNetwork $ObjectIPAddress $ObjectSubnetMask
    } catch {
        throw $_
    }

    # A simple check, if the mask is shorter (larger network) then it won't be a subnet of the object anyway.
    if ($subjectNetwork.MaskLength -lt $objectNetwork.MaskLength) {
        return $false
    }

    $subjectDecimalIP = ConvertTo-DecimalIP $subjectNetwork.IPAddress
    $objectDecimalNetwork = ConvertTo-DecimalIP (Get-NetworkAddress $objectNetwork)
    $objectDecimalBroadcast = ConvertTo-DecimalIP (Get-BroadcastAddress $objectNetwork)

    # If the mask is longer (smaller network), then the decimal form of the address must be between the
    # network and broadcast address of the object (the network we test against).
    if ($subjectDecimalIP -ge $objectDecimalNetwork -and $subjectDecimalIP -le $objectDecimalBroadcast) {
        return $true
    } else {
        return $false
    }
}
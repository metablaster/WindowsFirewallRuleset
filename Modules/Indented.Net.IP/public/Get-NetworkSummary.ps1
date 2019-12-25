function Get-NetworkSummary {
    <#
    .SYNOPSIS
        Generates a summary describing several properties of a network range
    .DESCRIPTION
        Get-NetworkSummary uses many of the IP conversion commands to provide a summary of a network range from any IP address in the range and a subnet mask.
    .INPUTS
        System.String
    .EXAMPLE
        Get-NetworkSummary 192.168.0.1 255.255.255.0
    .EXAMPLE
        Get-NetworkSummary 10.0.9.43/22
    .EXAMPLE
        Get-NetworkSummary 0/0
    #>

    [CmdletBinding()]
    [OutputType('Indented.Net.IP.NetworkSummary')]
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
        } catch {
            throw $_
        }

        $decimalIP = ConvertTo-DecimalIP $Network.IPAddress
        $decimalMask = ConvertTo-DecimalIP $Network.SubnetMask
        $decimalNetwork =  $decimalIP -band $decimalMask
        $decimalBroadcast = $decimalIP -bor (-bnot $decimalMask -band [UInt32]::MaxValue)

        $networkSummary = [PSCustomObject]@{
            NetworkAddress    = $networkAddress = ConvertTo-DottedDecimalIP $decimalNetwork
            NetworkDecimal    = $decimalNetwork
            BroadcastAddress  = ConvertTo-DottedDecimalIP $decimalBroadcast
            BroadcastDecimal  = $decimalBroadcast
            Mask              = $network.SubnetMask
            MaskLength        = $maskLength = ConvertTo-MaskLength $network.SubnetMask
            MaskHexadecimal   = ConvertTo-HexIP $network.SubnetMask
            CIDRNotation      = '{0}/{1}' -f $networkAddress, $maskLength
            HostRange         = ''
            NumberOfAddresses = $decimalBroadcast - $decimalNetwork + 1
            NumberOfHosts     = $decimalBroadcast - $decimalNetwork - 1
            Class             = ''
            IsPrivate         = $false
            PSTypeName        = 'Indented.Net.IP.NetworkSummary'
        }

        if ($networkSummary.NumberOfHosts -lt 0) {
            $networkSummary.NumberOfHosts = 0
        }
        if ($networkSummary.MaskLength -lt 31) {
            $networkSummary.HostRange = '{0} - {1}' -f @(
                (ConvertTo-DottedDecimalIP ($decimalNetwork + 1))
                (ConvertTo-DottedDecimalIP ($decimalBroadcast - 1))
            )
        }

        $networkSummary.Class = switch -regex (ConvertTo-BinaryIP $network.IPAddress) {
            '^1111'               { 'E'; break }
            '^1110'               { 'D'; break }
            '^11000000\.10101000' { if ($networkSummary.MaskLength -ge 16) { $networkSummary.IsPrivate = $true } }
            '^110'                { 'C'; break }
            '^10101100\.0001'     { if ($networkSummary.MaskLength -ge 12) { $networkSummary.IsPrivate = $true } }
            '^10'                 { 'B'; break }
            '^00001010'           { if ($networkSummary.MaskLength -ge 8) { $networkSummary.IsPrivate = $true} }
            '^0'                  { 'A'; break }
        }

        $networkSummary
    }
}
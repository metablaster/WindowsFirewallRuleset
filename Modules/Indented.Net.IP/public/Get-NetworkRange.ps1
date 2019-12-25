function Get-NetworkRange {
    <#
    .SYNOPSIS
        Get a list of IP addresses within the specified network.
    .DESCRIPTION
        Get-NetworkRange finds the network and broadcast address as decimal values then starts a counter between the two, returning IPAddress for each.
    .INPUTS
        System.String
    .EXAMPLE
        Get-NetworkRange 192.168.0.0 255.255.255.0

        Returns all IP addresses in the range 192.168.0.0/24.
    .EXAMPLE
        Get-NetworkRange 10.0.8.0/22

        Returns all IP addresses in the range 192.168.0.0 255.255.252.0.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromIPAndMask')]
    [OutputType([IPAddress])]
    param (
        # Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ParameterSetName = 'FromIPAndMask')]
        [String]$IPAddress,

        # A subnet mask as an IP address.
        [Parameter(Position = 2, ParameterSetName = 'FromIPAndMask')]
        [String]$SubnetMask,

        # Include the network and broadcast addresses when generating a network address range.
        [Parameter(ParameterSetName = 'FromIPAndMask')]
        [Switch]$IncludeNetworkAndBroadcast,

        # The start address of a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress]$Start,

        # The end address of a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress]$End
    )

    process {
        if ($pscmdlet.ParameterSetName -eq 'FromIPAndMask') {
            try {
                $null = $psboundparameters.Remove('IncludeNetworkAndBroadcast')
                $network = ConvertToNetwork @psboundparameters
            } catch {
                $pscmdlet.ThrowTerminatingError($_)
            }

            $decimalIP = ConvertTo-DecimalIP $network.IPAddress
            $decimalMask = ConvertTo-DecimalIP $network.SubnetMask

            $startDecimal = $decimalIP -band $decimalMask
            $endDecimal = $decimalIP -bor (-bnot $decimalMask -band [UInt32]::MaxValue)

            if (-not $IncludeNetworkAndBroadcast) {
                $startDecimal++
                $endDecimal--
            }
        } else {
            $startDecimal = ConvertTo-DecimalIP $Start
            $endDecimal = ConvertTo-DecimalIP $End
        }

        for ($i = $startDecimal; $i -le $endDecimal; $i++) {
            [IPAddress]([IPAddress]::NetworkToHostOrder([Int64]$i) -shr 32 -band [UInt32]::MaxValue)
        }
    }
}
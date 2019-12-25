function ConvertTo-Subnet {
    <#
    .SYNOPSIS
        Convert a start and end IP address to the closest matching subnet.
    .DESCRIPTION
        ConvertTo-Subnet attempts to convert a starting and ending IP address from a range to the closest subnet.
    .EXAMPLE
        ConvertTo-Subnet -Start 0.0.0.0 -End 255.255.255.255
    .EXAMPLE
        ConvertTo-Subnet -Start 192.168.0.1 -End 192.168.0.129
    .EXAMPLE
        ConvertTo-Subnet 10.0.0.23/24
    .EXAMPLE
        ConvertTo-Subnet 10.0.0.23 255.255.255.0
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromIPAndMask')]
    [OutputType('Indented.Net.IP.Subnet')]
    param (
        # Any IP address in the subnet.
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'FromIPAndMask')]
        [String]$IPAddress,

        # A subnet mask.
        [Parameter(Position = 2, ParameterSetName = 'FromIPAndMask')]
        [String]$SubnetMask,

        # The first IP address from a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress]$Start,

        # The last IP address from a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress]$End
    )

    if ($pscmdlet.ParameterSetName -eq 'FromIPAndMask') {
        try {
            $network = ConvertToNetwork @psboundparameters
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    } elseif ($pscmdlet.ParameterSetName -eq 'FromStartAndEnd') {
        if ($Start -eq $End) {
            $MaskLength = 32
        } else {
            $DecimalStart = ConvertTo-DecimalIP $Start
            $DecimalEnd = ConvertTo-DecimalIP $End

            if ($DecimalEnd -lt $DecimalStart) {
                $Start = $End
            }

            # Find the point the binary representation of each IP address diverges
            $i = 32
            do {
                $i--
            } until (($DecimalStart -band ([UInt32]1 -shl $i)) -ne ($DecimalEnd -band ([UInt32]1 -shl $i)))

            $MaskLength = 32 - $i - 1
        }

        try {
            $network = ConvertToNetwork $Start $MaskLength
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    $hostAddresses = [Math]::Pow(2, (32 - $network.MaskLength)) - 2
    if ($hostAddresses -lt 0) {
        $hostAddresses = 0
    }

    $subnet = [PSCustomObject]@{
        NetworkAddress   = Get-NetworkAddress $network.ToString()
        BroadcastAddress = Get-BroadcastAddress $network.ToString()
        SubnetMask       = $network.SubnetMask
        MaskLength       = $network.MaskLength
        HostAddresses    = $hostAddresses
        PSTypeName       = 'Indented.Net.IP.Subnet'
    }

    $subnet | Add-Member ToString -MemberType ScriptMethod -Force -Value {
        return '{0}/{1}' -f $this.NetworkAddress, $this.MaskLength
    }

    $subnet
}
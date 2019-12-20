function ConvertToNetwork {
    <#
    .SYNOPSIS
        Converts IP address formats to a set a known styles.
    .DESCRIPTION
        ConvertToNetwork ensures consistent values are recorded from parameters which must handle differing addressing formats. This Cmdlet allows all other the other functions in this module to offload parameter handling.
    .NOTES
        Change log:
            05/03/2016 - Chris Dent - Refactored and simplified.
            14/01/2014 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType('Indented.Net.IP.Network')]
    param (
        # Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$IPAddress,

        # A subnet mask as an IP address.
        [Parameter(Position = 2)]
        [AllowNull()]
        [String]$SubnetMask
    )

    $validSubnetMaskValues =
        "0.0.0.0", "128.0.0.0", "192.0.0.0",
        "224.0.0.0", "240.0.0.0", "248.0.0.0", "252.0.0.0",
        "254.0.0.0", "255.0.0.0", "255.128.0.0", "255.192.0.0",
        "255.224.0.0", "255.240.0.0", "255.248.0.0", "255.252.0.0",
        "255.254.0.0", "255.255.0.0", "255.255.128.0", "255.255.192.0",
        "255.255.224.0", "255.255.240.0", "255.255.248.0", "255.255.252.0",
        "255.255.254.0", "255.255.255.0", "255.255.255.128", "255.255.255.192",
        "255.255.255.224", "255.255.255.240", "255.255.255.248", "255.255.255.252",
        "255.255.255.254", "255.255.255.255"

    $network = [PSCustomObject]@{
        IPAddress  = $null
        SubnetMask = $null
        MaskLength = 0
        PSTypeName = 'Indented.Net.IP.Network'
    }

    # Override ToString
    $network | Add-Member ToString -MemberType ScriptMethod -Force -Value {
        '{0}/{1}' -f $this.IPAddress, $this.MaskLength
    }

    if (-not $psboundparameters.ContainsKey('SubnetMask') -or $SubnetMask -eq '') {
        $IPAddress, $SubnetMask = $IPAddress.Split([Char[]]'\/ ', [StringSplitOptions]::RemoveEmptyEntries)
    }

    # IPAddress

    while ($IPAddress.Split('.').Count -lt 4) {
        $IPAddress += '.0'
    }

    if ([IPAddress]::TryParse($IPAddress, [Ref]$null)) {
        $network.IPAddress = [IPAddress]$IPAddress
    } else {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [ArgumentException]'Invalid IP address.',
            'InvalidIPAddress',
            'InvalidArgument',
            $IPAddress
        )
        $pscmdlet.ThrowTerminatingError($errorRecord)
    }

    # SubnetMask

    if ($null -eq $SubnetMask -or $SubnetMask -eq '') {
        $network.SubnetMask = [IPAddress]$validSubnetMaskValues[32]
        $network.MaskLength = 32
    } else {
        $maskLength = 0
        if ([Int32]::TryParse($SubnetMask, [Ref]$maskLength)) {
            if ($MaskLength -ge 0 -and $maskLength -le 32) {
                $network.SubnetMask = [IPAddress]$validSubnetMaskValues[$maskLength]
                $network.MaskLength = $maskLength
            } else {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]'Mask length out of range (expecting 0 to 32).',
                    'InvalidMaskLength',
                    'InvalidArgument',
                    $SubnetMask
                )
                $pscmdlet.ThrowTerminatingError($errorRecord)
            }
        } else {
            while ($SubnetMask.Split('.').Count -lt 4) {
                $SubnetMask += '.0'
            }
            $maskLength = $validSubnetMaskValues.IndexOf($SubnetMask)

            if ($maskLength -ge 0) {
                $Network.SubnetMask = [IPAddress]$SubnetMask
                $Network.MaskLength = $maskLength
            } else {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]'Invalid subnet mask.',
                    'InvalidSubnetMask',
                    'InvalidArgument',
                    $SubnetMask
                )
                $pscmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }

    $network
}
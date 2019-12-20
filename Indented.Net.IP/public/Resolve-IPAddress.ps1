function Resolve-IPAddress {
    <#
    .SYNOPSIS
        Resolves an IP address expression using wildcard expressions to individual IP addresses.
    .DESCRIPTION
        Resolves an IP address expression using wildcard expressions to individual IP addresses.

        Resolve-IPAddress expands groups and values in square brackets to generate a list of IP addresses or networks using CIDR-notation.

        Ranges of values may be specied using a start and end value using "-" to separate the values.

        Specific values may be listed as a comma separated list.
    .EXAMPLE
        Resolve-IPAddress "10.[1,2].[0-2].0/24"

        Returns the addresses 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.2.0.0/24, and so on.
    #>

    [CmdletBinding()]
    param (
        # The IPAddress expression to resolve.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [String]$IPAddress
    )

    process {
        $groups = [Regex]::Matches($IPAddress, '\[(?:(?<Range>\d+(?:-\d+))|(?<Selected>(?:\d+, *)*\d+))\]|(?<All>\*)').Groups.Captures |
            Where-Object { $_ -and $_.Name -ne '0' } |
            ForEach-Object {
                $group = $_

                $values = switch ($group.Name) {
                    'Range'    {
                        [int]$start, [int]$end = $group.Value -split '-'

                        if ($start, $end -gt 255) {
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [ArgumentException]::new('Value ranges to resolve must use a start and end values between 0 and 255'),
                                'RangeExpressionOutOfRange',
                                'InvalidArgument',
                                $group.Value
                            )
                            $pscmdlet.ThrowTerminatingError($errorRecord)
                        }

                        $start..$end
                    }
                    'Selected' {
                        $values = [int[]]($group.Value -split ', *')

                        if ($values -gt 255) {
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [ArgumentException]::new('All selected values must be between 0 and 255'),
                                'SelectionExpressionOutOfRange',
                                'InvalidArgument',
                                $group.Value
                            )
                            $pscmdlet.ThrowTerminatingError($errorRecord)
                        }

                        $values
                    }
                    'All' {
                        0..255
                    }
                }

                [PSCustomObject]@{
                    Name        = $_.Name
                    Position    = [Int32]$IPAddress.Substring(0, $_.Index).Split('.').Count - 1
                    ReplaceWith = $values
                    PSTypeName  = 'ExpansionGroupInfo'
                }
            }

        if ($groups) {
            GetPermutation $groups -BaseAddress $IPAddress
        } elseif (-not [IPAddress]::TryParse(($IPAddress -replace '/\d+$'), [Ref]$null)) {
            Write-Warning 'The IPAddress argument is not a valid IP address and cannot be resolved'
        } else {
            Write-Debug 'No groups found to resolve'
        }
    }
}
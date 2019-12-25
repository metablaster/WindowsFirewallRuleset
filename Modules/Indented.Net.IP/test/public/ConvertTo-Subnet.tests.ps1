#region:TestFileHeader
param (
    [Boolean]$UseExisting
)

if (-not $UseExisting) {
    $moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\test"))
    $stubBase = Resolve-Path (Join-Path $moduleBase "test*\stub\*")
    if ($null -ne $stubBase) {
        $stubBase | Import-Module -Force
    }

    Import-Module $moduleBase -Force
}
#endregion

InModuleScope Indented.Net.IP {
    Describe 'ConvertTo-Subnet' {
        BeforeAll {
            Mock Get-NetworkSummary {
                return [PSCustomObject]@{} | Add-Member -TypeName 'Indented.Net.IP.NetworkSummary' -PassThru
            }

            $FromIPAndMask = @{
            IPAddress = '0.0.0.0/32'
            }
            $FromStartAndEnd = @{
                Start = '0.0.0.0'
                End   = '255.255.255.255'
            }
        }

        #
        # Default mocks
        #


        #
        # Tests
        #

        It 'Returns a PSObject tagged with the type name Indented.Net.IP.Subnet' {
            $Subnet = ConvertTo-Subnet @FromIPAndMask
            $Subnet.PSTypeNames -contains 'Indented.Net.IP.Subnet' | Should -BeTrue
        }

        It 'Accepts an address and subnet mask, and a start and end address' {
            { ConvertTo-Subnet @FromIPAndMask } | Should -Not -Throw
            { ConvertTo-Subnet @FromStartAndEnd } | Should -Not -Throw
        }

        It 'Converts 192.168.0.225/23 to a subnet' {
            $Subnet = ConvertTo-Subnet 192.168.0.225/23
            $Subnet.NetworkAddress | Should -Be '192.168.0.0'
            $Subnet.HostAddresses | Should -Be 510
        }

        It 'Returns the network 10.0.0.0/24 when passed 10.0.0.10 and 10.0.0.250' {
            (ConvertTo-Subnet -Start 10.0.0.10 -End 10.0.0.250).ToString() | Should -Be '10.0.0.0/24'
        }

        It 'Returns the network 0.0.0.0/0 when passed 0.0.0.0 and 255.255.255.255' {
            (ConvertTo-Subnet -Start 0.0.0.0 -End 255.255.255.255).ToString() | Should -Be '0.0.0.0/0'
        }

        It 'Swaps start and end and calculates the common subnet if end falls -Before start' {
            (ConvertTo-Subnet -Start 10.0.0.20 -End 10.0.0.10).ToString() | Should -Be '10.0.0.0/27'
            (ConvertTo-Subnet -Start 10.0.0.10 -End 10.0.0.20).ToString() | Should -Be '10.0.0.0/27'
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-Subnet).Examples.Example.Code | ForEach-Object -Begin {
                $Number = 1
            } -Process {
                @{ Number = $Number++; Code = $_ }
            }
        ) {
            param (
                $Number,

                $Code
            )

            $ScriptBlock = [ScriptBlock]::Create($Code.Trim())
            $ScriptBlock | Should -Not -Throw
        }
    }
}
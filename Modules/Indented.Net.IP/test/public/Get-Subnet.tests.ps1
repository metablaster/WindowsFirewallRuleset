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

InModuleScope 'Indented.Net.IP' {
    Describe 'Get-Subnet' {
        It 'Returns an object tagged with the type Indented.Net.IP.Subnet' {
            $Subnets = Get-Subnet 0/24 -NewSubnetMask 25
            $Subnets[0].PSTypeNames | Should -Contain 'Indented.Net.IP.Subnet'
        }

        It 'Creates two /26 subnets from 10/25' {
            $Subnets = Get-Subnet 10/25 -NewSubnetMask 26
            $Subnets[0].NetworkAddress | Should -Be '10.0.0.0'
            $Subnets[1].NetworkAddress | Should -Be '10.0.0.64'
        }

        It 'Handles both subnet mask and mask length formats for NewSubnetMask' {
            $Subnets = Get-Subnet 10/24 -NewSubnetMask 26
            $Subnets.Count | Should -Be 4

            $Subnets = Get-Subnet 10/24 -NewSubnetMask 255.255.255.192
            $Subnets.Count | Should -Be 4
        }

        It 'Throws an error if requested to subnet a smaller network into a larger one' {
            { Get-Subnet 0/24 -NetSubnetMask 23 } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Get-Subnet).Examples.Example.Code | ForEach-Object -Begin {
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
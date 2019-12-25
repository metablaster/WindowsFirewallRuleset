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
    Describe 'Get-NetworkSummary' {
        It 'Returns an object tagged with the type Indented.Net.IP.NetworkSummary' {
            $NetworkSummary = Get-NetworkSummary 0/24
            $NetworkSummary.PSTypeNames -contains 'Indented.Net.IP.NetworkSummary' | Should Be $true
        }

        It 'Identifies ranges with a first octet from 0 to 127 as class A' {
            (Get-NetworkSummary 0/24).Class | Should -Be 'A'
            (Get-NetworkSummary 127/24).Class | Should -Be 'A'
        }

        It 'Identifies ranges with a first octet from 128 to 191 as class B' {
            (Get-NetworkSummary 128/24).Class | Should -Be 'B'
            (Get-NetworkSummary 191/24).Class | Should -Be 'B'
        }

        It 'Identifies ranges with a first octet of 192 to 223 as class C' {
            (Get-NetworkSummary 192/24).Class | Should -Be 'C'
            (Get-NetworkSummary 223/24).Class | Should -Be 'C'
        }

        It 'Identifies ranges with a first octet of 224 to 239 as class D' {
            (Get-NetworkSummary 224/24).Class | Should -Be 'D'
            (Get-NetworkSummary 239/24).Class | Should -Be 'D'
        }

        It 'Identifies ranges with a first octet of 240 to 255 as class E' {
            (Get-NetworkSummary 240/24).Class | Should -Be 'E'
            (Get-NetworkSummary 255/24).Class | Should -Be 'E'
        }

        It 'Identifies 10/8 as a private range' {
            (Get-NetworkSummary 10/8).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 10.0.0.0/8).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 10.0.0.0 255.0.0.0).IsPrivate | Should -BeTrue
        }

        It 'Identifies 172.16/12 as a private range' {
            (Get-NetworkSummary 172.16/12).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 172.16.0.0/12).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 172.16.0.0 255.240.0.0).IsPrivate | Should -BeTrue
        }

        It 'Identifies 192.168/16 as a private range' {
            (Get-NetworkSummary 192.168/16).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 192.168.0.0/16).IsPrivate | Should -BeTrue
            (Get-NetworkSummary 192.168.0.0 255.255.0.0).IsPrivate | Should -BeTrue
        }

        It 'Accepts pipeline input' {
            ('20/24' | Get-NetworkSummary).NetworkAddress | Should -Be '20.0.0.0'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { Get-NetworkSummary 'abcd' } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Get-NetworkSummary).Examples.Example.Code | ForEach-Object -Begin {
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
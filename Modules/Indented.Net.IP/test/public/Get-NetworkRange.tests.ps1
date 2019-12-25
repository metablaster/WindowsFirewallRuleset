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
    Describe 'Get-NetworkRange' {
        It 'Returns an array of IPAddress' {
            Get-NetworkRange 1.2.3.4/32 -IncludeNetworkAndBroadcast | Should -BeOfType [IPAddress]
        }

        It 'Returns 255.255.255.255 when passed 255.255.255.255/32' {
            $Range = Get-NetworkRange 0/30
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue

            $Range = Get-NetworkRange 0.0.0.0/30
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue

            $Range = Get-NetworkRange 0.0.0.0 255.255.255.252
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue
        }

        It 'Accepts pipeline input' {
            '20/24' | Get-NetworkRange | Select-Object -First 1 | Should -Be '20.0.0.1'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { Get-NetworkRange 'abcd' } | Should -Throw
        }

        It 'Returns correct values when used with Start and End parameters' {
            $StartIP = [System.Net.IPAddress]'192.168.1.1'
            $EndIP = [System.Net.IPAddress]'192.168.2.10'
            $Assertion = Get-NetworkRange -Start $StartIP -End $EndIP

            $Assertion.Count | Should BeExactly 266
            $Assertion[0].IPAddressToString | Should -Be '192.168.1.1'
            $Assertion[-1].IPAddressToString | Should -Be '192.168.2.10'
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Get-NetworkRange).Examples.Example.Code | ForEach-Object -Begin {
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
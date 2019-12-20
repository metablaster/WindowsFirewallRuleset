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
    Describe 'Get-NetworkAddress' {
        It 'Returns an IPAddress' {
            Get-NetworkAddress 1.2.3.4/24 | Should -BeOfType [IPAddress]
        }

        It 'Returns 255.255.255.255 when passed 255.255.255.255/32' {
            Get-NetworkAddress 255.255.255.255/32 | Should -Be '255.255.255.255'
            Get-NetworkAddress 255.255.255.255 255.255.255.255 | Should -Be '255.255.255.255'
        }

        It 'Returns 1.0.0.15 when passwed 1.0.0.0/28' {
            Get-NetworkAddress 1.0.0.18/28| Should -Be '1.0.0.16'
            Get-NetworkAddress 1.0.0.18 255.255.255.240 | Should -Be '1.0.0.16'
        }

        It 'Returns 0.0.0.0 when passed 0.0.0.0/0' {
            Get-NetworkAddress 0.0.0.0/0 | Should -Be '0.0.0.0'
            Get-NetworkAddress 0/0 | Should -Be '0.0.0.0'
            Get-NetworkAddress 0.0.0.0 0.0.0.0 | Should -Be '0.0.0.0'
        }

        It 'Accepts pipeline input' {
            '20/23' | Get-NetworkAddress | Should -Be '20.0.0.0'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { Get-NetworkAddress 'abcd' -ErrorAction Stop } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Get-NetworkAddress).Examples.Example.Code | ForEach-Object -Begin {
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
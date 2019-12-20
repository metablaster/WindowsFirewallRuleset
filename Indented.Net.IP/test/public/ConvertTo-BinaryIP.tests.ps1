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
    Describe 'ConvertTo-BinaryIP' {
        It 'Returns a string' {
            ConvertTo-BinaryIP 1.2.3.4 | Should -BeOfType [String]
        }

        It 'Converts 1.2.3.4 to 00000001.00000010.00000011.00000100' {
            ConvertTo-BinaryIP 1.2.3.4 | Should -Be '00000001.00000010.00000011.00000100'
        }

        It 'Converts 129.129.129.129 to 10000001.10000001.10000001.10000001' {
            ConvertTo-BinaryIP 129.129.129.129 | Should -Be '10000001.10000001.10000001.10000001'
        }

        It 'Converts 255.255.255.255 to 11111111.11111111.11111111.11111111' {
            ConvertTo-BinaryIP 255.255.255.255 | Should -Be '11111111.11111111.11111111.11111111'
        }

        It 'Converts 0.0.0.0 to 00000000.00000000.00000000.00000000' {
            ConvertTo-BinaryIP 0.0.0.0 | Should -Be '00000000.00000000.00000000.00000000'
        }

        It 'Accepts pipeline input' {
            '1.2.3.4' | ConvertTo-BinaryIP | Should -Be '00000001.00000010.00000011.00000100'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { ConvertTo-BinaryIP 'abcd' } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-BinaryIP).Examples.Example.Code | ForEach-Object -Begin {
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
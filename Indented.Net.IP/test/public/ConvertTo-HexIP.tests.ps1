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
    Describe 'ConvertTo-HexIP' {
        It 'Returns a string' {
            ConvertTo-HexIP 1.2.3.4 | Should -BeOfType [String]
        }

        It 'Converts 0.0.0.0 to 00000000' {
            ConvertTo-HexIP 0.0.0.0 | Should -Be '00000000'
        }

        It 'Converts 255.255.255.255 to FFFFFFFF' {
            ConvertTo-HexIP 255.255.255.255 | Should -Be 'FFFFFFFF'
        }

        It 'Converts 1.2.3.4 to 01020304' {
            ConvertTo-HexIP 1.2.3.4 | Should -Be '01020304'
        }

        It 'Accepts pipeline input' {
            '1.2.3.4' | ConvertTo-HexIP | Should -Be '01020304'
        }

        It 'Throws an error if passed an unrecognised format' {
            { ConvertTo-HexIP abcd -ErrorAction Stop } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-HexIP).Examples.Example.Code | ForEach-Object -Begin {
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
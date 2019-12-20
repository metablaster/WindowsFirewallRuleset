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
    Describe 'ConvertTo-DottedDecimalIP' {
        It 'Converts 00000001.00000010.00000011.00000100 to 1.2.3.4' {
            ConvertTo-DottedDecimalIP '00000001.00000010.00000011.00000100' | Should -Be 1.2.3.4
        }

        It 'Converts 16909060 to 1.2.3.4' {
            ConvertTo-DottedDecimalIP 16909060 | Should -Be 1.2.3.4
        }

        It 'Accepts pipeline input' {
            16909060 | ConvertTo-DottedDecimalIP | Should -Be 1.2.3.4
        }

        It 'Throws an error if passed an unrecognised format' {
            { ConvertTo-DottedDecimalIP abcd -ErrorAction Stop } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-DottedDecimalIP).Examples.Example.Code | ForEach-Object -Begin {
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
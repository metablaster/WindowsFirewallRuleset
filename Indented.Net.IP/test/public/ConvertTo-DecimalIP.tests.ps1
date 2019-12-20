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
    Describe 'ConvertTo-DecimalIP' {
        It 'Returns a unsigned 32-bit integer' {
            ConvertTo-DecimalIP 0.0.0.0 | Should -BeOfType [UInt32]
        }

        It 'Converts 0.0.0.0 to 0' {
            ConvertTo-DecimalIP 0.0.0.0 | Should -Be 0
        }

        It 'Converts 255.255.255.255 to 4294967295' {
            ConvertTo-DecimalIP 255.255.255.255 | Should -Be 4294967295
        }

        It 'Accepts pipeline input' {
            '0.0.0.0' | ConvertTo-DecimalIP | Should -Be 0
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { ConvertTo-DecimalIP 'abcd' } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-DecimalIP).Examples.Example.Code | ForEach-Object -Begin {
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
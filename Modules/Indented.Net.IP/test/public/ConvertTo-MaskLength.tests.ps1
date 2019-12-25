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
    Describe 'ConvertTo-MaskLength' {
        It 'Returns a 32-bit integer' {
            ConvertTo-MaskLength 255.0.0.0 | Should -BeOfType [Int32]
        }

        It 'Converts 0.0.0.0 to 0' {
            ConvertTo-MaskLength 0.0.0.0 | Should -Be 0
        }

        It 'Converts 255.255.224.0 to ' {
            ConvertTo-MaskLength 255.255.224.0 | Should -Be 19
        }

        It 'Converts 255.255.255.255 to 32' {
            ConvertTo-MaskLength 255.255.255.255 | Should -Be 32
        }

        It 'Accepts pipeline input' {
            '128.0.0.0' | ConvertTo-MaskLength | Should -Be 1
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { ConvertTo-MaskLength 'abcd' } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-MaskLength).Examples.Example.Code | ForEach-Object -Begin {
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
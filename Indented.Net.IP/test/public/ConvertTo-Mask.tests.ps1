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
    Describe 'ConvertTo-Mask' {
        It 'Returns an IPAddress' {
            ConvertTo-Mask 1 | Should -BeOfType [IPAddress]
        }

        It 'Converts 0 to 0.0.0.0' {
            ConvertTo-Mask 0 | Should -Be '0.0.0.0'
        }

        It 'Converts 24 to 255.255.255.0' {
            ConvertTo-Mask 24 | Should -Be '255.255.255.0'
        }

        It 'Converts 9 to 255.128.0.0' {
            ConvertTo-Mask 9 | Should -Be '255.128.0.0'
        }

        It 'Converts 32 to 255.255.255.255' {
            ConvertTo-Mask 32 | Should -Be '255.255.255.255'
        }

        It 'Accepts pipeline input' {
            1 | ConvertTo-Mask | Should -Be '128.0.0.0'
        }

        It 'Throws an error if passed an invalid value' {
            { ConvertTo-Mask 33 -ErrorAction Stop } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help ConvertTo-Mask).Examples.Example.Code | ForEach-Object -Begin {
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
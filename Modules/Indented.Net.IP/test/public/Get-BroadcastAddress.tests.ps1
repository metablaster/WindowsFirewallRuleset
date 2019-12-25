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
    Describe 'Get-BroadcastAddress' {
        It 'Returns an IPAddress' {
            Get-BroadcastAddress 1.2.3.4/24 | Should -BeOfType [IPAddress]
        }

        It 'Returns 0.0.0.0 when passed 0.0.0.0/32' {
            Get-BroadcastAddress 0.0.0.0/32 | Should -Be '0.0.0.0'
            Get-BroadcastAddress 0/32 | Should -Be '0.0.0.0'
            Get-BroadcastAddress 0.0.0.0 255.255.255.255 | Should -Be '0.0.0.0'
        }

        It 'Returns 1.0.0.15 when passwed 1.0.0.0/28' {
            Get-BroadcastAddress 1.0.0.0/28| Should -Be '1.0.0.15'
            Get-BroadcastAddress 1/28 | Should -Be '1.0.0.15'
            Get-BroadcastAddress 1.0.0.0 255.255.255.240 | Should -Be '1.0.0.15'
        }

        It 'Returns 255.255.255.255 when passed 0.0.0.0/0' {
            Get-BroadcastAddress 0.0.0.0/0 | Should -Be '255.255.255.255'
            Get-BroadcastAddress 0/0 | Should -Be '255.255.255.255'
            Get-BroadcastAddress 0.0.0.0 0.0.0.0 | Should -Be '255.255.255.255'
        }

        It 'Accepts pipeline input' {
            '20/23' | Get-BroadcastAddress | Should -Be '20.0.1.255'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { Get-BroadcastAddress 'abcd' -ErrorAction Stop } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Get-BroadcastAddress).Examples.Example.Code | ForEach-Object -Begin {
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
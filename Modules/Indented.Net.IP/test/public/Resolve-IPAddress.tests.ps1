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

InModuleScope 'Indented.Net.IP' {
    Describe 'Resolve-IPAddress' {
        It 'Resolves an IPAddress <IPAddress> describing a range' -TestCases @(
            @{ IPAddress = '[1-2].0.0.0';     Expect = @('1.0.0.0', '2.0.0.0') }
            @{ IPAddress = '0.[1-2].0.0';     Expect = @('0.1.0.0', '0.2.0.0') }
            @{ IPAddress = '0.0.[1-2].0';     Expect = @('0.0.1.0', '0.0.2.0') }
            @{ IPAddress = '0.0.0.[1-2]';     Expect = @('0.0.0.1', '0.0.0.2') }
            @{ IPAddress = '[1-2].0.0.[1-2]'; Expect = @('1.0.0.1', '1.0.0.2', '2.0.0.1', '2.0.0.2') }
        ) {
            param (
                $IPAddress,
                $Expect
            )

            Resolve-IPAddress $IPAddress | Should -Be $Expect
        }

        It 'Resolves an IPAddress <IPAddress> describing selected values' -TestCases @(
            @{ IPAddress = '[1,2].0.0.0';     Expect = @('1.0.0.0', '2.0.0.0') }
            @{ IPAddress = '0.[1,2].0.0';     Expect = @('0.1.0.0', '0.2.0.0') }
            @{ IPAddress = '0.0.[1,2].0';     Expect = @('0.0.1.0', '0.0.2.0') }
            @{ IPAddress = '0.0.0.[1,2]';     Expect = @('0.0.0.1', '0.0.0.2') }
            @{ IPAddress = '[1,2].0.0.[1,2]'; Expect = @('1.0.0.1', '1.0.0.2', '2.0.0.1', '2.0.0.2') }
        ) {
            param (
                $IPAddress,
                $Expect
            )

            Resolve-IPAddress $IPAddress | Should -Be $Expect
        }

        It 'Throws RangeExpressionOutOfRange if a value is greater than 255' {
            { Resolve-IPAddress '[1-260].0.0.0' } | Should -Throw -ErrorId 'RangeExpressionOutOfRange'
        }

        It 'Throws SelectionExpressionOutOfRange if a value is greater than 255' {
            { Resolve-IPAddress '[0,260].0.0.0' } | Should -Throw -ErrorId 'SelectionExpressionOutOfRange'
        }

        It 'Supports * as a wildcard for 0 to 255' {
            $addressRange = Resolve-IPAddress '[1,2].*.0.0'

            $addressRange.Count | Should -Be 512
            $addressRange[0] | Should -Be '1.0.0.0'
            $addressRange[255] | Should -Be '1.255.0.0'
            $addressRange[256] | Should -Be '2.0.0.0'
            $addressRange[511] | Should -Be '2.255.0.0'
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Resolve-IPAddress).Examples.Example.Code | ForEach-Object -Begin {
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
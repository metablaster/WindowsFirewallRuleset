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
    Describe 'Test-SubnetMember' {
        It 'Returns a Boolean' {
            Test-SubnetMember 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/8 | Should -BeOfType [Boolean]
        }

        It 'Returns true if the subject falls within the object network' {
            Test-SubnetMember 1.2.3.4 -ObjectIPAddress 1.2.3.0/24 | Should -BeTrue
        }

        It 'Returns false if the subject does fall within the object network' {
            Test-SubnetMember 1.2.3.4 -ObjectIPAddress 2.0.0.0/24 | Should -BeFalse
        }

        It 'Throws an error if passed something other than an IPAddress for Subject or Object' {
            { Test-SubnetMember -SubjectIPAddress 'abcd' -ObjectIPAddress 10.0.0.0/8 } | Should -Throw
            { Test-SubnetMember -SubjectIPAddress 10.0.0.0/8  -ObjectIPAddress 'abcd' } | Should -Throw
        }

        It 'Example <Number> is valid' -TestCases (
            (Get-Help Test-SubnetMember).Examples.Example.Code | ForEach-Object -Begin {
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
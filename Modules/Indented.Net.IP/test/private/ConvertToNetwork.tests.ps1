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
    Describe 'ConvertToNetwork' {
        BeforeAll {
            $maskTable = @(
                @{ MaskLength = 0;  Mask = '0.0.0.0' }
                @{ MaskLength = 1;  Mask = '128.0.0.0' }
                @{ MaskLength = 2;  Mask = '192.0.0.0' }
                @{ MaskLength = 3;  Mask = '224.0.0.0' }
                @{ MaskLength = 4;  Mask = '240.0.0.0' }
                @{ MaskLength = 5;  Mask = '248.0.0.0' }
                @{ MaskLength = 6;  Mask = '252.0.0.0' }
                @{ MaskLength = 7;  Mask = '254.0.0.0' }
                @{ MaskLength = 8;  Mask = '255.0.0.0' }
                @{ MaskLength = 9;  Mask = '255.128.0.0' }
                @{ MaskLength = 10; Mask = '255.192.0.0' }
                @{ MaskLength = 11; Mask = '255.224.0.0' }
                @{ MaskLength = 12; Mask = '255.240.0.0' }
                @{ MaskLength = 13; Mask = '255.248.0.0' }
                @{ MaskLength = 14; Mask = '255.252.0.0' }
                @{ MaskLength = 15; Mask = '255.254.0.0' }
                @{ MaskLength = 16; Mask = '255.255.0.0' }
                @{ MaskLength = 17; Mask = '255.255.128.0' }
                @{ MaskLength = 18; Mask = '255.255.192.0' }
                @{ MaskLength = 19; Mask = '255.255.224.0' }
                @{ MaskLength = 20; Mask = '255.255.240.0' }
                @{ MaskLength = 21; Mask = '255.255.248.0' }
                @{ MaskLength = 22; Mask = '255.255.252.0' }
                @{ MaskLength = 23; Mask = '255.255.254.0' }
                @{ MaskLength = 24; Mask = '255.255.255.0' }
                @{ MaskLength = 25; Mask = '255.255.255.128' }
                @{ MaskLength = 26; Mask = '255.255.255.192' }
                @{ MaskLength = 27; Mask = '255.255.255.224' }
                @{ MaskLength = 28; Mask = '255.255.255.240' }
                @{ MaskLength = 29; Mask = '255.255.255.248' }
                @{ MaskLength = 30; Mask = '255.255.255.252' }
                @{ MaskLength = 31; Mask = '255.255.255.254' }
                @{ MaskLength = 32; Mask = '255.255.255.255' }
            )
        }

        It 'Translates the string 0/0 to 0.0.0.0/0 (mask 0.0.0.0)' {
            $network = ConvertToNetwork 0/0
            $network.IPAddress | Should -Be '0.0.0.0'
            $network.SubnetMask | Should -Be '0.0.0.0'
            $network.MaskLength | Should -Be 0
        }

        It 'Translates the string 1.2/27 to 1.2.0.0/27 (mask 255.255.255.224)' {
            $network = ConvertToNetwork 1.2/27
            $network.IPAddress | Should -Be '1.2.0.0'
            $network.SubnetMask | Should -Be '255.255.255.224'
            $network.MaskLength | Should -Be 27
        }

        It 'Translates a string containing "3.4.5 255.255.0.0" to 3.4.5.0/16 (mask 255.255.0.0)' {
            $network = ConvertToNetwork "3.4.5 255.255.0.0"
            $network.IPAddress | Should -Be '3.4.5.0'
            $network.SubnetMask | Should -Be '255.255.0.0'
            $network.MaskLength | Should -Be 16
        }

        It 'Translates IPAddress argument 1.2.3.4 and SubnetMask argument 24 to 1.2.3.4/24 (mask 255.255.255.0)' {
            $network = ConvertToNetwork 1.2.3.4 -SubnetMask 24
            $network.IPAddress | Should -Be '1.2.3.4'
            $network.SubnetMask | Should -Be '255.255.255.0'
            $network.MaskLength | Should -Be 24
        }

        It 'Translates IPAddress argument 212.44.56.21 and SubnetMask argument 255.255.128.0 to 212.44.56.21/17' {
            $network = ConvertToNetwork 212.44.56.21 255.255.128.0
            $network.IPAddress | Should -Be '212.44.56.21'
            $network.SubnetMask | Should -Be '255.255.128.0'
            $network.MaskLength | Should -Be 17
        }

        It 'Translates IPAddres argument 1.0.0.0 with no SubnetMask argument to 1.0.0.0/32 (mask 255.255.255.255)' {
            $network = ConvertToNetwork 1.0.0.0
            $network.IPAddress | Should -Be '1.0.0.0'
            $network.SubnetMask | Should -Be '255.255.255.255'
            $network.MaskLength | Should -Be 32
        }

        It 'Converts CIDR formatted subnets from <MaskLength> to <Mask>' -TestCases $maskTable {
            param (
                $MaskLength,

                $Mask
            )

            $errorRecord = $null
            try {
                $network = ConvertToNetwork "10.0.0.0/$MaskLength"
            } catch {
                $errorRecord = $_
            }

            $errorRecord | Should -BeNullOrEmpty
            $network.SubnetMask | Should -Be $Mask
        }

        It 'Converts dotted-decimal formatted subnets from <Mask> to <MaskLength>' -TestCases $maskTable {
            param (
                $MaskLength,

                $Mask
            )

            $errorRecord = $null
            try {
                $network = ConvertToNetwork 10.0.0.0 $Mask
            } catch {
                $errorRecord = $_
            }

            $errorRecord | Should -BeNullOrEmpty
            $network.MaskLength | Should -Be $MaskLength
        }

        It 'Pads a partial subnet mask' {
            $network = ConvertToNetwork "10.0.0.0" "255.255"

            $network.SubnetMask | Should -Be '255.255.0.0'
        }

        It 'Raises a terminating error when the IP address is invalid' {
            { ConvertToNetwork InvalidIP/24 } | Should -Throw -ErrorId 'InvalidIPAddress'
        }

        It 'Raises a terminating error when the mask length is invalid' {
            { ConvertToNetwork "10.0.0.0/33" } | Should -Throw -ErrorId 'InvalidMaskLength'
            { ConvertToNetwork "10.0.0.0/-1" } | Should -Throw -ErrorId 'InvalidMaskLength'
        }

        It 'Raises a terminating error when the subnet mask is invalid' {
            { ConvertToNetwork "10.0.0.0" "255.255.255.1" } | Should -Throw -ErrorId 'InvalidSubnetMask'
        }
    }
}
$private = @(
    'ConvertToNetwork'
    'GetPermutation'
)

foreach ($file in $private) {
    . ("{0}\private\{1}.ps1" -f $psscriptroot, $file)
}

$public = @(
    'ConvertFrom-HexIP'
    'ConvertTo-BinaryIP'
    'ConvertTo-DecimalIP'
    'ConvertTo-DottedDecimalIP'
    'ConvertTo-HexIP'
    'ConvertTo-Mask'
    'ConvertTo-MaskLength'
    'ConvertTo-Subnet'
    'Get-BroadcastAddress'
    'Get-NetworkAddress'
    'Get-NetworkRange'
    'Get-NetworkSummary'
    'Get-Subnet'
    'Resolve-IPAddress'
    'Test-SubnetMember'
)

foreach ($file in $public) {
    . ("{0}\public\{1}.ps1" -f $psscriptroot, $file)
}

$functionsToExport = @(
    'ConvertFrom-HexIP'
    'ConvertTo-BinaryIP'
    'ConvertTo-DecimalIP'
    'ConvertTo-DottedDecimalIP'
    'ConvertTo-HexIP'
    'ConvertTo-Mask'
    'ConvertTo-MaskLength'
    'ConvertTo-Subnet'
    'Get-BroadcastAddress'
    'Get-NetworkAddress'
    'Get-NetworkRange'
    'Get-NetworkSummary'
    'Get-Subnet'
    'Resolve-IPAddress'
    'Test-SubnetMember'
)
Export-ModuleMember -Function $functionsToExport



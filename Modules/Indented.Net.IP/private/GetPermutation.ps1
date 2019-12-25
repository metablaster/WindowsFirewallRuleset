function GetPermutation {
    <#
    .SYNOPSIS
        Gets permutations of an IP address expansion expression.
    .DESCRIPTION
        Gets permutations of an IP address expansion expression.
    #>

    [CmdletBinding()]
    param (
        [PSTypeName('ExpansionGroupInfo')]
        [Object[]]$Group,

        [String]$BaseAddress,

        [Int32]$Index
    )

    foreach ($value in $Group[$Index].ReplaceWith) {
        $octets = $BaseAddress -split '\.'
        $octets[$Group[$Index].Position] = $value
        $address = $octets -join '.'

        if ($Index -lt $Group.Count - 1) {
            $address = GetPermutation $Group -Index ($Index + 1) -BaseAddress $address
        }
        $address
    }
}
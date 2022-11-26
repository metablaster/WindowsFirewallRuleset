
function GetNewVersionNumber
{
	param (
		[UInt32] $Version,
		[string[]] $PolicyType
	)

	# User version is the high 16 bits, Machine version is the low 16 bits.
	# Reference:  http://blogs.technet.com/b/grouppolicy/archive/2007/12/14/understanding-the-gpo-version-number.aspx

	$pair = UInt32ToUInt16Pair -UInt32 $version

	if ($PolicyType -contains 'User')
	{
		$pair.HighPart++
	}

	if ($PolicyType -contains 'Machine')
	{
		$pair.LowPart++
	}

	return UInt16PairToUInt32 -UInt16Pair $pair
}

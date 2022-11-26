
function UInt16PairToUInt32
{
	param ([object] $UInt16Pair)

	# Deliberately avoiding bitwise shift operators here, for PowerShell v2 compatibility.

	return ([UInt32] $UInt16Pair.HighPart) * 0x10000 + $UInt16Pair.LowPart
}

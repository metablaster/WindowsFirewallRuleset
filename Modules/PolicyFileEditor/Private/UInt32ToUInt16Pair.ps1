
function UInt32ToUInt16Pair
{
	param ([UInt32] $UInt32)

	# Deliberately avoiding bitwise shift operators here, for PowerShell v2 compatibility.

	$lowPart = $UInt32 -band 0xFFFF
	$highPart = ($UInt32 - $lowPart) / 0x10000

	return New-Object psobject -Property @{
		LowPart = [UInt16] $lowPart
		HighPart = [UInt16] $highPart
	}
}

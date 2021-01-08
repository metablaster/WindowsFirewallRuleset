
<#
.SYNOPSIS
Get device path or disk volume path

.DESCRIPTION
Get mappings of disk volume letter and device path
Optionally you can convert from drive letter to device path and vice versa

.PARAMETER DriveLetter
If specified the result is device path for given drive letter

.PARAMETER DevicePath
If specified result is drive letter for given device path

.EXAMPLE
PS> .\Get-DevicePath.ps1

DevicePath              DriveLetter
----------              -----------
\Device\HarddiskVolume1 D:
\Device\HarddiskVolume4 C:

.EXAMPLE
PS> .\Get-DevicePath.ps1 -DevicePath "\Device\HarddiskVolume4"

C:

.EXAMPLE
PS> .\Get-DevicePath.ps1 -DriveLetter C:"

\Device\HarddiskVolume4

.INPUTS
None. You cannot pipe objects to Get-DevicePath.ps1

.OUTPUTS
[string]
[PSCustomObject]

.NOTES
TODO: Make it work with PowerShell Core, see: Add-WinFunction
#>

using namespace System
#Requires -Version 5.1
#requires -PSEdition Desktop

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None")]
[OutputType([string], [System.Management.Automation.PSCustomObject])]
param (
	[Parameter(ParameterSetName = "Drive")]
	[string] $DriveLetter,

	[Parameter(ParameterSetName = "Path")]
	[string] $DevicePath
)

# Build System Assembly in order to call Kernel32:QueryDosDevice.
$DynAssembly = New-Object System.Reflection.AssemblyName("SysUtils")
$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("SysUtils", $false)

# Define [Kernel32]::QueryDosDevice method
$TypeBuilder = $ModuleBuilder.DefineType("Kernel32", "Public, Class")
$PInvokeMethod = $TypeBuilder.DefinePInvokeMethod(
	"QueryDosDevice",
	"kernel32.dll",
	([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
	[Reflection.CallingConventions]::Standard,
	[uint32],
	[type[]] @([string], [Text.StringBuilder], [uint32]),
	[Runtime.InteropServices.CallingConvention]::Winapi,
	[Runtime.InteropServices.CharSet]::Auto
)

$DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([string]))
$SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField("SetLastError")

$SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
	$DllImportConstructor,
	@("kernel32.dll"),
	[Reflection.FieldInfo[]] @($SetLastError),
	@($true)
)

$PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
$Kernel32 = $TypeBuilder.CreateType()

# The maximum number of characters that can be stored into the StringBuilder buffer
$Max = 65536

# A variable to a buffer that will receive the result of the query
$StringBuilder = New-Object System.Text.StringBuilder($Max)

if ($DriveLetter)
{
	# An MS-DOS device name string specifying the target of the query.
	# The device name cannot have a trailing backslash, for example,use "C:", not "C:\"
	# This parameter can be NULL. In that case, the QueryDosDevice function will store a list
	# of all existing MS-DOS device names into the StringBuilder buffer.
	# If the function fails, the return value is zero
	$ReturnLength = $Kernel32::QueryDosDevice($DriveLetter, $StringBuilder, $Max)

	if ($ReturnLength)
	{
		Write-Output $StringBuilder.ToString()
	}
	else
	{
		Write-Warning -Message "Drive letter '$DriveLetter' not found"
	}

	return
}

$ResultTable = Get-CimInstance -ClassName Win32_Volume -Namespace "root\cimv2" |
Where-Object { $_.DriveLetter } | ForEach-Object {
	$ReturnLength = $Kernel32::QueryDosDevice($_.DriveLetter, $StringBuilder, $Max)

	if ($ReturnLength)
	{
		[PSCustomObject]@{
			DriveLetter = $_.DriveLetter
			DevicePath = $StringBuilder.ToString()
		}
	}
}

if ($DevicePath)
{
	[string] $Result = $ResultTable | Where-Object {
		$_.DevicePath -eq $DevicePath
	} | Select-Object -ExpandProperty DriveLetter

	if ([string]::IsNullOrEmpty($Result))
	{
		Write-Warning -Message "Device path '$DevicePath' not found"
	}

	return $Result
}

Write-Output $ResultTable

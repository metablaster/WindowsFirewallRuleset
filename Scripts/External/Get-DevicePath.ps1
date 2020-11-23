
<#
.SYNOPSIS
Get disk volume path

.DESCRIPTION
Get mappings of disk volume letter and device path

.EXAMPLE
PS> .\Get-DevicePath.ps1

DevicePath              DriveLetter
----------              -----------
\Device\HarddiskVolume1 D:
\Device\HarddiskVolume4 C:

.INPUTS
None. You cannot pipe objects to Get-DevicePath.ps1

.OUTPUTS
[PSCustomObject]

.NOTES
Following modifications by metablaster, November 2020:
- Replace Get-WmiObject with Get-CimInstance
- Applied code style and formatting
- Added script boilerplace code
TODO: Make it work with PowerShell Core, see: Add-WinFunction
TODO: Make it convert from one path to another by using parameters

.LINK
https://morgantechspace.com/2014/11/Get-Volume-Path-from-Drive-Name-using-Powershell.html
#>

#region Initialization
using namespace System
#Requires -Version 5.1
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\..\ContextSetup.ps1
#endregion

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
	@($true))

$PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
$Kernel32 = $TypeBuilder.CreateType()

$Max = 65536
$StringBuilder = New-Object System.Text.StringBuilder($Max)

Get-CimInstance -ClassName Win32_Volume -Namespace root/CIMV2 | Where-Object { $_.DriveLetter } |
ForEach-Object {
	$ReturnLength = $Kernel32::QueryDosDevice($_.DriveLetter, $StringBuilder, $Max)

	if ($ReturnLength)
	{
		$DriveMapping = @{
			DriveLetter = $_.DriveLetter
			DevicePath = $StringBuilder.ToString()
		}

		New-Object -TypeName PSCustomObject -Property $DriveMapping
	}
}

Update-Log

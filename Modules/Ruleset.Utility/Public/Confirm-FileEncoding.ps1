
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Verify file is encoded as expected

.DESCRIPTION
Confirm-FileEncoding verifies target file is encoded as expected.
Unexpected encoding may give bad data resulting is unexpected behavior

.PARAMETER Path
Path to the file which is to be checked.
Wildcard characters are permitted.

.PARAMETER LiteralPath
Specifies a path to one or more file locations.
The value of LiteralPath is used exactly as it is typed.
No characters are interpreted as wildcards

.PARAMETER Encoding
Expected encoding, for PS Core the default is "utf8NoBOM" or "ascii",
for PS Desktop the default is "utf8" or "ascii"

The acceptable values for this parameter are as follows:

ascii: Encoding for the ASCII (7-bit) character set.
bigendianunicode: UTF-16 format using the big-endian byte order.
bigendianutf32: UTF-32 format using the big-endian byte order.
oem: The default encoding for MS-DOS and console programs.
unicode: UTF-16 format using the little-endian byte order.
utf7: UTF-7 format.
utf8: UTF-8 format.
utf32: UTF-32 format.

The following values are valid for Core edition only:

utf8BOM: UTF-8 format with Byte Order Mark (BOM)
utf8NoBOM: UTF-8 format without Byte Order Mark (BOM)

The following values are valid For Desktop edition only:

byte: A sequence of bytes.
default: Encoding that corresponds to the system's active code page (usually ANSI).
string: Same as Unicode.
unknown: Same as Unicode.

.PARAMETER Binary
If specified, binary files are left alone.
By default binary files are detected as having wrong encoding.

.EXAMPLE
PS> Confirm-FileEncoding C:\SomeFile.txt -Encoding utf16

.INPUTS
[System.IO.FileInfo[]] One or more paths to file to check

.OUTPUTS
None. Confirm-FileEncoding does not generate any output

.NOTES
None.
#>
function Confirm-FileEncoding
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false, DefaultParameterSetName = "Path",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Confirm-FileEncoding.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = "Path")]
		[Alias("FilePath")]
		[SupportsWildcards()]
		[System.IO.FileInfo[]] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "Literal")]
		[System.IO.FileInfo[]] $LiteralPath,

		[Parameter()]
		[ValidateSet("ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
			"utf8", "utf32", "utf8BOM", "utf8NoBOM", "byte", "default", "string", "unknown")]
		[string[]] $Encoding,

		[Parameter()]
		[switch] $Binary
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		if ([string]::IsNullOrEmpty($Encoding))
		{
			if ($PSVersionTable.PSEdition -eq "Core") { $Encoding = @("utf8NoBOM", "ascii") }
			else { $Encoding = @("utf8", "ascii") }
		}

		# All of these 3 are UTF16-LE
		if ("unicode" -in $Encoding) { $Encoding += @("string", "unknown") }
		elseif ("string" -in $Encoding) { $Encoding += @("unicode", "unknown") }
		elseif ("unknown" -in $Encoding) { $Encoding += @("unicode", "string") }

		# All 3 are UTF8
		if ("utf8" -in $Encoding) { $Encoding += @("utf8BOM", "utf8NoBOM") }
	}
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "LiteralPath")
		{
			$Path = $LiteralPath
		}

		foreach ($TargetFile in $Path)
		{
			if ($PSCmdlet.ParameterSetName -eq "Path")
			{
				$File = Resolve-FileSystemPath $TargetFile -File
			}

			if (!($File -and $File.Exists))
			{
				Write-Error -Category ObjectNotFound -TargetObject $TargetFile `
					-Message "Cannot find file '$TargetFile' because it does not exist"
				return
			}

			$TargetEncoding = Get-FileEncoding $File
			$FileName = Split-Path -Path $File -Leaf

			if (($TargetEncoding -eq "Binary") -and $Binary)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] File '$FileName' encoded as '$TargetEncoding' verification skipped"
				continue
			}

			# [array]::Find($Encoding, [System.Predicate[string]] { $TargetEncoding -eq $args[0] })
			if ($TargetEncoding -in $Encoding)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] File '$FileName' encoded as '$TargetEncoding' verification passed"
			}
			else
			{
				Write-Error -Category ReadError -TargetObject $File -Message "File read operation expects '$Encoding' encoding on file '$File' but file encoded as '$TargetEncoding'"

				if ($PSCmdlet.ShouldProcess($FileName, "Abort due to bad file encoding"))
				{
					exit
				}

				Write-Warning -Message "[$($MyInvocation.InvocationName)] $FileName, '$TargetEncoding' encoded might yield unexpected results"
			}
		}
	}
}

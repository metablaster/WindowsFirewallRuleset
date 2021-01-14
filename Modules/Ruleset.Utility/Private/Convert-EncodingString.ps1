
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Convert between strings identifying encoding in PowerShell and System.Text.Encoding name

.DESCRIPTION
Convert-EncodingString converts PowerShell encoding string to System.Text.Encoding name or
System.Text.Encoding name to PowerShell equivalent encoding string.
BOM is not included in the result but function accept it as parameter for conversion.
If the result could be represented in multiple encoding strings, the one that applies to both
Core and Desktop editions will be returned.

.PARAMETER Encoding
Either System.Text.Encoding name or PowerShell encoding string

.PARAMETER BOM
If specified, the string may include mention of BOM (Byte Order Mark)
This parameter is ignored for PowerShell Desktop edition and valid only for
"utf-8" System.Text.Encoding name

.EXAMPLE
PS> Convert-EncodingString "bigendianutf32"
utf-32BE

.EXAMPLE
PS> Convert-EncodingString utf-8
utf8

.INPUTS
None. You cannot pipe objects to Convert-EncodingString

.OUTPUTS
[string]

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.MODULENAME/Help/en-US/FUNCTIONNAME.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding?view=netcore-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding?view=powershellsdk-1.1.0
#>
function Convert-EncodingString
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.MODULENAME/Help/en-US/FUNCTIONNAME.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
			"utf8", "utf32", "utf8BOM", "utf8NoBOM", "byte", "default", "string", "unknown",
			"us-ascii", "utf-7", "utf-8", "unicodeFFFE", "utf-16BE", "utf-32BE", "utf-16", "utf-32")]
		[string] $Encoding,

		[Parameter(ParameterSetName = "BOM")]
		[switch] $BOM
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (($PSVersionTable.PSEdition -eq "Core") -and ($Encoding -in @("byte", "default", "string", "unknown")))
	{
		Write-Warning "Encoding string '$Encoding' is not valid for Core edition"
	}
	elseif (($PSVersionTable.PSEdition -eq "Desktop") -and ($Encoding -in @("utf8BOM", "utf8NoBOM")))
	{
		Write-Warning "Encoding string '$Encoding' is not valid for Desktop edition"
	}

	$Result = switch ($Encoding)
	{
		# Encoding for the ASCII (7-bit) character set
		"ascii" { "us-ascii"; break }
		# UTF-16 format using the big-endian byte order
		"bigendianunicode"
		{
			"utf-16BE"
			# "unicodeFFFE"
			break
		}
		# UTF-32 format using the big-endian byte order
		"bigendianutf32" { "utf-32BE"; break }
		# UTF-16 format using the little-endian byte order
		"unicode" { "utf-16"; break }
		# UTF-7 format
		"utf7" { "utf-7"; break }
		# UTF-8 format
		"utf8" { "utf-8"; break }
		# UTF-32 format
		"utf32" { "utf-32"; break }
		# The default encoding for MS-DOS and console programs
		"oem" { break }
		# NOTE: Following values are valid for Core edition only:
		# UTF-8 format with Byte Order Mark (BOM)
		"utf8BOM" { "utf-8"; break }
		# UTF-8 format without Byte Order Mark (BOM)
		"utf8NoBOM" { "utf-8"; break }
		# NOTE: Following values are valid For Desktop edition only:
		# A sequence of bytes
		"byte" { break }
		# The system's active code page (usually ANSI)
		"default" { break }
		# Same as Unicode
		"string" { "utf-16"; break }
		# Same as Unicode
		"unknown" { "utf-16"; break }
		# NOTE: Following values are reverse of previous values
		# US-ASCII
		"us-ascii" { "ascii"; break }
		# Unicode (UTF-7)
		"utf-7" { "utf7"; break }
		# Unicode (UTF-8)
		"utf-8"
		{
			if (($PSVersionTable.PSEdition -eq "Core") -and ($PSCmdlet.ParameterSetName -eq "BOM"))
			{
				if ($BOM)
				{
					"utf8BOM"
				}
				else
				{
					"utf8NoBOM"
				}
			}
			else
			{
				"utf8"
			}

			break
		}
		# Unicode (Big endian)
		"unicodeFFFE"
		{
			# NOTE: utf-16BE is not listed in "List of encodings" link
			$OldDebug = $DebugPreference
			$DebugPreference = "Continue"
			Write-Debug -Message "[$($MyInvocation.InvocationName)] 'unicodeFFFE' encoding confirmed, please update code"

			$DebugPreference = $OldDebug
			"bigendianunicode"
			break
		}
		"utf-16BE" { "bigendianunicode"; break }
		# Unicode (UTF-32 Big endian)
		"utf-32BE" { "bigendianutf32"; break }
		# Unicode
		"utf-16"
		{
			"unicode"
			# "string"
			# "unknown"
			break
		}
		# Unicode (UTF-32)
		"utf-32" { "utf32" }
	}

	if ([string]::IsNullOrEmpty($Result))
	{
		Write-Error -Category NotImplemented -TargetObject $Encoding `
			-Message "Converting encoding string '$Encoding' not implemented"
	}
	else
	{
		Write-Output $Result
	}
}

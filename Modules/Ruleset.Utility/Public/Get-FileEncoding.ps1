
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Gets the encoding of a file

.DESCRIPTION
Gets the encoding of a file, if the encoding can't be determined, ex. the file
contains unicode charaters but no BOM, then the default encoding is assumed which
can be specified trough Encoding parameter.

.PARAMETER Path
The path of the file to get the encoding of

.PARAMETER Encoding
Default encoding to assume for non ASCII files without BOM.
This encoding is also used to read file if needed.
This parameter can be either a string identifying an encoding that is used by PowerShell commandlets
such as "utf8" or System.Text.Encoding object.
The default is set by global variable, UTF8 no BOM for Core or UTF8 with BOM for Desktop edition

.EXAMPLE
PS> Get-FileEncoding .\utf8BOM.txt
utf8BOM

.EXAMPLE
PS> Get-FileEncoding .\utf-16LE.txt
unicode

.EXAMPLE
PS> Get-FileEncoding .\ascii.txt
ascii

.EXAMPLE
PS> Get-FileEncoding C:\WINDOWS\regedit.exe
binary

.INPUTS
None. You cannot pipe objects to Get-FileEncoding

.OUTPUTS
[string]

.NOTES
TODO: Encoding parameter should also accept code page or encoding name, Encoding class has
static functions to convert.
TODO: Parameter to specify output as [System.Text.Encoding] instead of default [string]
TODO: utf8 file reported as ascii in Windows PowerShell

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-FileEncoding.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding

.LINK
https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding
#>
function Get-FileEncoding
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-FileEncoding.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("FilePath")]
		[SupportsWildcards()]
		[System.IO.FileInfo] $Path,

		[Parameter()]
		[ValidateScript( {
				($_ -is [System.Text.Encoding]) -or
				($_ -in @("ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
					"utf8", "utf32", "utf8BOM", "utf8NoBOM", "byte", "default", "string", "unknown"))
			})]
		$Encoding = $DefaultEncoding
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[System.IO.FileInfo] $File = Resolve-FileSystemPath $Path -File

	if (!($File -and $File.Exists))
	{
		Write-Error -Category ObjectNotFound -TargetObject $Path `
			-Message "Cannot find path '$Path' because it does not exist"
		return
	}

	# First, check if the file is binary.
	# That is, if the first 5 lines contain any non-printable characters.
	$NonPrintable = [char[]] (0..8 + 10..31 + 127 + 129 + 141 + 143 + 144 + 157)

	# TODO: Is encoding parameter needed?
	# [System.String]
	$Lines = Get-Content -Path $File -TotalCount 5 -ErrorAction Ignore

	$Result = @($Lines | Where-Object {
			# Reports the zero-based index of the first occurrence in this instance of any character
			# in a specified array of Unicode characters, -1 if not found
			$_.IndexOfAny($NonPrintable) -ge 0
		})

	if ($Result.Count -gt 0)
	{
		return "binary"
	}

	# Next, check if it matches a well-known encoding.
	# The hashtable used to store our mapping of encoding bytes to System.TextEncoding object.
	# For example, "255-254 = [System.Text.UnicodeEncoding]"
	$Encodings = @{}

	# Find all of the encodings understood by the .NET Framework.
	# For each, determine the bytes at the start of the file (the preamble) that the .NET
	# Framework uses to identify that encoding.
	foreach ($LocalEncoding in [System.Text.Encoding]::GetEncodings())
	{
		$Preamble = $LocalEncoding.GetEncoding().GetPreamble()

		if ($Preamble)
		{
			$EncodingBytes = $Preamble -join '-'
			$Encodings[$EncodingBytes] = $LocalEncoding.GetEncoding()
		}
	}

	# Find out the lengths of all of the preambles.
	$EncodingLengths = $Encodings.Keys | Where-Object { $_ } |
	ForEach-Object {
		($_ -split "-").Count
	}

	# To read file as bytes, that depends on PowerShell edition
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		$Params = @{
			# Warning issued if Encoding used with this param
			AsByteStream = $true
		}
	}
	else
	{
		$Params = @{
			Encoding = "Byte"
		}
	}

	# Is there BOM in file
	[bool] $BOM = $false

	# Go through each of the possible preamble lengths, read that many
	# bytes from file, and then see if it matches one of the encodings we know about.
	foreach ($EncodingLength in $EncodingLengths | Sort-Object -Descending)
	{
		try
		{
			# If file can't be read there is no point to continue, ex. access to file is denied
			$Bytes = Get-Content @Params -ReadCount $EncodingLength -Path $File -ErrorAction Stop |
			Select-Object -First 1
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return "unknown"
		}

		# [System.Text.Encoding]
		$LocalEncoding = $Encodings[$Bytes -join '-']

		# If we found an encoding that had the same preamble bytes, save that output and break.
		if ($LocalEncoding)
		{
			$Result = $LocalEncoding

			# For UTF encoding this will match only if there is BOM in file
			$BOM = switch ($Result | Select-Object -ExpandProperty BodyName)
			{
				"utf-8" { $true; break }
				"utf-16" { $true; break }
				"utf-32" { $true; break }
				default { $false }
			}

			break
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Length is '$EncodingLength', Encoding is '$LocalEncoding'"
	}

	if (!$Result)
	{
		# If there is no BOM present in file, parse file for non ASCII characters
		# TODO: not sure what encoding should be default for this
		if ($PSVersionTable.PSEdition -eq "Core")
		{
			$FileData = Get-Content -Path $File -Encoding $Encoding
		}
		else
		{
			$FileData = Get-Content -Path $File -Encoding Ascii
		}

		# TODO: there is no need to parse line by line
		foreach ($Line in $FileData)
		{
			# ASCIIEncoding encodes Unicode characters as single 7-bit ASCII characters.
			# This encoding only supports character values between U+0000 and U+007F. Code page 20127.
			if ($Line -cmatch "[^\u0000-\u007F]")
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Non ASCII line in file without BOM: $($Path.FullName)"
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Line reads '$Line'"

				# We only know it's not ASCII and there is no BOM, so use default encoding
				$Result = $Encoding
				break
			}
		}

		if (!$Result)
		{
			# All characters in file are in ASCII range
			$Result = [System.Text.Encoding]::ASCII
		}
	}

	if ($Result -is [System.Text.Encoding])
	{
		# TODO: we can create custom object to tell us more about encoding of target file
		$Result = $Result | Select-Object -ExpandProperty BodyName
		$OutputString = Convert-EncodingString $Result -BOM:$BOM
	}
	else
	{
		$OutputString = $Result
	}

	Write-Output $OutputString
}

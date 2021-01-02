
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Verify file is correctly encoded

.DESCRIPTION
Confirm-FileEncoding verifies target file is encoded as expected.
Wrong encoding may return bad data resulting is unexpected behavior

.PARAMETER Path
Path to the file which to check

.PARAMETER Encoding
Expected encoding

.PARAMETER Binary
If specified, handles binary files as well.

.EXAMPLE
PS> Confirm-FileEncoding C:\SomeFile.txt utf16

.INPUTS
[string] One or more paths to file to check

.OUTPUTS
None. Confirm-FileEncoding does not generate any output

.NOTES
None.
#>
function Confirm-FileEncoding
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Confirm-FileEncoding.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Alias("FilePath")]
		[SupportsWildcards()]
		[System.IO.FileInfo[]] $Path,

		[Parameter()]
		[string[]] $Encoding = @("utf-8", "us-ascii"),

		[Parameter()]
		[switch] $Binary
	)

	begin
	{
		# TODO: Windows PowerShell outputs as utf8 with BOM
		if ($PSVersionTable.PSEdition -eq "Desktop")
		{
			# NOTE: Until this issue is resolved adding "utf-8 with BOM" to whitelist
			$Encoding += "utf-8 with BOM"
		}
	}
	process
	{
		foreach ($TargetFile in $Path)
		{
			$File = Resolve-FileSystemPath $TargetFile -File

			if (!($File -and $File.Exists))
			{
				Write-Error -Category ObjectNotFound -TargetObject $TargetFile `
					-Message "Cannot find path '$TargetFile' because it does not exist"
				return
			}

			$TargetEncoding = Get-FileEncoding $File
			if (($TargetEncoding -eq "Binary") -and !$Binary)
			{
				Write-Debug -Message "File $FileName encoded as $TargetEncoding verification skipped"
				continue
			}

			$FileName = Split-Path -Path $File -Leaf

			if ([array]::Find($Encoding, [System.Predicate[string]] { $TargetEncoding -eq $args[0] }))
			{
				Write-Debug -Message "File $FileName encoded as $TargetEncoding verification passed"
			}
			else
			{
				Write-Error -Category ReadError -TargetObject $File -Message "File read operation expects $Encoding encoding on file $File but file encoded as $TargetEncoding"

				if ($PSCmdlet.ShouldProcess($FileName, "Abort due to bad file encoding"))
				{
					exit
				}

				Write-Warning -Message "$FileName, $TargetEncoding encoded might yield unexpected results"
			}
		}
	}
}

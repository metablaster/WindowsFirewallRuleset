
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
Get a list of windows services involved in rules

.DESCRIPTION
Scan all scripts in this repository and get windows service names involved in rules,
the result is saved to file and used to verify existence of these services on target system.

.PARAMETER Path
Root folder name which to scan recursively

.EXAMPLE
PS> Find-NetworkService "C:\PathToRepo"

.INPUTS
None. You cannot pipe objects to Find-NetworkService

.OUTPUTS
None. Find-NetworkService does not generate any output

.NOTES
None.
#>
function Find-NetworkService
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Find-NetworkService.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Scanning rules for network services"

	[System.IO.DirectoryInfo] $Directory = Resolve-FileSystemPath $Path
	# get-service | Where-Object -property BinaryPathName -NotLike "C:\WINDOWS\System32\svchost.exe *" | Select-Object -ExpandProperty BinaryPathName

	if (!($Directory -and $Directory.Exists))
	{
		Write-Warning -Message "Unable to locate path '$Path'"
		return
	}

	# Recursively get powershell scripts in input folder
	$Files = Get-ChildItem -Path $Directory -Recurse -Filter *.ps1
	if (!$Files)
	{
		Write-Warning -Message "No powershell script files found in '$Directory'"
		return
	}

	$Content = @()
	# Filter out service names from each powershell file in input folder
	$Files | ForEach-Object {
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading file: $($_.FullName)"
		Confirm-FileEncoding $_.FullName
		Get-Content $_.FullName -Encoding $DefaultEncoding | ForEach-Object {
			if ($_ -match "(?<=-Service )(.*)(?= -Program)")
			{
				$Content += $Matches[0]
			}
		}
	}

	if (!$Content)
	{
		Write-Warning -Message "No matches found in any of the rules"
		return
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rid of duplicate matches and known bad values"
	$Content = $Content | Select-Object -Unique
	$Content = $Content | Where-Object { $_ -ne '$Service' -and $_ -ne "Any" -and $_ -ne '"*"' } | Sort-Object

	if (!$Content)
	{
		Write-Warning -Message "No valid service matches found"
		return
	}

	# File name where to save all matches
	$File = "$ProjectRoot\Rules\NetworkServices.txt"

	# If output file exists clear it, otherwise create a new file
	if (Test-Path -Path $File)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Clearing file: $File"
		Clear-Content -Path $File
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating file: $File"
		New-Item -ItemType File -Path $File | Out-Null
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing filtered services to: $File"
	Add-Content -Encoding $DefaultEncoding -Path $File -Value $Content

	Write-Information -Tags "Project" -MessageData "INFO: $($Content.Count) services involved in firewall rules"
}

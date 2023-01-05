
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
Build a list of windows services involved in script rules

.DESCRIPTION
Scan all scripts in this repository and get windows service names involved in firewall rules.
The result is saved to file and used to verify existence and digital signature of these services
on target system.

.PARAMETER Path
Root folder name which to scan recursively

.PARAMETER Log
If specified, the list of services is also logged.

.EXAMPLE
PS> Write-ServiceList "C:\PathToRepo"

.EXAMPLE
PS> Write-ServiceList "C:\PathToRepo" -Log

.INPUTS
None. You cannot pipe objects to Write-ServiceList

.OUTPUTS
[string]

.NOTES
TODO: -Log parameter should be accompanied with -LogName parameter
#>
function Write-ServiceList
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ServiceList.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[switch] $Log
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Scanning rules for network services"

	[System.IO.DirectoryInfo] $Directory = Resolve-FileSystemPath $Path

	if (!($Directory -and $Directory.Exists))
	{
		Write-Error -Category ObjectNotFound -TargetObject $Path -Message "Unable to locate path '$Path'"
		return
	}

	# Recursively get powershell scripts in input folder
	$Files = Get-ChildItem -Path $Directory -Recurse -Filter *.ps1
	if (!$Files)
	{
		Write-Error -Category ObjectNotFound -Message "No powershell script files found in '$Directory'"
		return
	}

	$Services = @()
	# Filter out service names from each powershell file in input folder
	$Files | ForEach-Object {
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading file: $($_.FullName)"
		Confirm-FileEncoding $_.FullName
		Get-Content $_.FullName -Encoding $DefaultEncoding | ForEach-Object {
			if ($_ -match "(?<=-Service )(.*)(?= -Program)")
			{
				$Services += $Matches[0]
			}
		}
	}

	if (!$Services)
	{
		Write-Error -Category ParserError -TargetObject $Files -Message "No matches found in any of the files"
		return
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rid of duplicate matches and known bad values"
	$Services = $Services | Select-Object -Unique | Where-Object {
		($_ -ne '$Service') -and ($_ -ne "Any") -and ($_ -ne '"*"')
	} | Sort-Object

	if (!$Services)
	{
		Write-Error -Category InvalidResult -Message "No service matches found in any of the rules"
		return
	}

	if ($Log)
	{
		$HeaderStack.Push("Services involved in all firewall rules")
		Write-LogFile -Message $Services -LogName "ServiceList" -Path $LogsFolder -Raw -Overwrite
		$HeaderStack.Pop() | Out-Null
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: $($Services.Count) services involved in firewall rules"
	Write-Output $Services
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Generates a log file name for Update-Log function

.DESCRIPTION
Generates a log file name composed of current date and time and appends to input
log level label and input path.
The function checks if a path to file exists, if not it creates one.

.PARAMETER Folder
Path to folder where to save logs

.PARAMETER FileLabel
File label which precedes date an time, ie Warning or Error.

.EXAMPLE
PS> Get-LogFile "C:\Logs" "Warning"

Warning_25.02.20 19h.log

.INPUTS
None. You cannot pipe objects to Get-LogFile

.OUTPUTS
None. Get-LogFile does not generate any output

.NOTES
TODO: Maybe a separate folder for each day?
TODO: need to check if drive exists
#>
function Get-LogFile
{
	[OutputType([void])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Folder,

		[Parameter(Mandatory = $true)]
		[string] $FileLabel
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Generate file name
	$FileName = $FileLabel + "_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = Join-Path -Path $Folder -ChildPath $FileName

	# Create Logs directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log directory $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Logs folder is: $Folder"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Generate log file name: $FileName"

	return $LogFile
}

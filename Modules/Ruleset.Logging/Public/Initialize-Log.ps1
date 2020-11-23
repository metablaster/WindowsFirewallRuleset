
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Generates a log file name composed of current date and appends to requested label and path.
The function checks if the path to log file exists, if not it creates directory but not log file.

.PARAMETER Folder
Path to directory where to save logs

.PARAMETER Label
File label which precedes file date, ex. Warning or Error

.PARAMETER Header
If specified, this header message will be at the top of a log file.
This parameter is ignored for existing log files

.EXAMPLE
PS> Initialize-Log "C:\Logs" -Label "Warning"

Warning_25.02.20.log

.INPUTS
None. You cannot pipe objects to Initialize-Log

.OUTPUTS
[string] Full path to log file name

.NOTES
None.
#>
function Initialize-Log
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateScript( { (Test-Path -Path (Split-Path -Path $_ -Qualifier)) })]
		[string] $Folder,

		[Parameter(Mandatory = $true)]
		[string] $Label,

		[Parameter()]
		[string] $Header
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Generate file name
	$FileName = $Label + "_$(Get-Date -Format "dd.MM.yy").log"
	$LogFile = Join-Path -Path $Folder -ChildPath $FileName

	# Create Logs directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log directory: $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	if (!(Test-Path -PathType Leaf -Path $LogFile))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log file: $FileName"
		New-Item -ItemType File -Path $LogFile -ErrorAction Stop | Out-Null
		Set-Content -Path $LogFile -Value "`n#`n# Windows Firewall Ruleset $ProjectVersion"

		if ($Header)
		{
			Add-Content -Path $LogFile -Value "# $Header"
		}

		Add-Content -Path $LogFile -Value "#"
	}
	elseif ($Header)
	{
		Write-Warning -Message "Header parameter is valid for new log files only, ignored..."
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Logs folder is: $Folder"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Generate log file name: $FileName"

	return $LogFile
}

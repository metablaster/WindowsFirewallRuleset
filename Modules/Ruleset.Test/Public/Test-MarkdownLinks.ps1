
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
Test markdown links

.DESCRIPTION
Test each link in markdown file and report if any link is dead

.PARAMETER Path
The path to directory containing target markdown files

.PARAMETER Recurse
If specified, recurse in to the path specified by Path parameter

.PARAMETER TimeoutSec
Specifies how long the request can be pending before it times out

.PARAMETER MaximumRetryCount
Specifies how many times PowerShell retries a connection when a failure code between 400 and
599, inclusive or 304 is received

.PARAMETER RetryIntervalSec
Specifies the interval between retries for the connection when a failure code between 400 and
599, inclusive or 304 is received

.PARAMETER MaximumRedirection
Specifies how many times PowerShell redirects a connection to an alternate Uniform Resource
Identifier (URI) before the connection fails.
A value of 0 (zero) prevents all redirection.

.PARAMETER SslProtocol
Sets the SSL/TLS protocols that are permissible for the web request.
This feature was added in PowerShell 6.0.0 and support for Tls13 was added in PowerShell 7.1.

.PARAMETER NoProxy
Indicates the test shouldn't use a proxy to reach the destination.
This feature was added in PowerShell 6.0.0.

.EXAMPLE
Test-MarkdownLinks -Path C:\GitHub\MyProject -Recurse

.EXAMPLE
Test-MarkdownLinks -Path C:\GitHub\MyProject -Recurse

.NOTES
WebSslProtocol enum does not list Tls13
TODO: Update time elapsed and remaining when testing links in single file
TODO: Implement parameters for Get-ChildItem
#>
function Test-MarkdownLinks
{
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter()]
		[string] $Path,

		[Parameter()]
		[switch] $Recurse,

		[Parameter()]
		[int32] $TimeoutSec = 0,

		[Parameter()]
		[int32] $MaximumRetryCount = 1,

		[Parameter()]
		[int32] $RetryIntervalSec = 2,

		[Parameter()]
		[int32] $MaximumRedirection = 5,

		[Parameter()]
		[ValidateSet("Default", "Tls", "Tls11", "Tls12")]
		$SslProtocol = "Default",

		[Parameter()]
		[switch] $NoProxy
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Progress bar initial setup
	$StartTime = Get-Date
	[System.TimeSpan] $SecondsElapsed = 0
	[nullable[double]] $SecondsRemaining = $null

	# Unreachable links
	[PSCustomObject[]] $StatusReport = @()

	# Get markdown files recursively
	[System.IO.FileInfo[]] $MarkdownFiles = Get-ChildItem -Path $Path -Recurse:$Recurse -Include "*.md"

	# Set up web request parameters
	$WebParams = [hashtable]@{
		TimeoutSec = $TimeoutSec
		MaximumRetryCount = $MaximumRetryCount
		RetryIntervalSec = $RetryIntervalSec
		MaximumRedirection = $MaximumRedirection
	}

	if ($PSVersionTable.PSVersion -ge "6.0.0")
	{
		$WebParams.Add("NoProxy", $NoProxy)

		# [Microsoft.PowerShell.Commands.WebSslProtocol]
		$WebParams.Add("SslProtocol", $SslProtocol)
	}
	elseif ($NoProxy -or ($SslProtocol -ne "Default"))
	{
		Write-Warning -Message "NoProxy and SslProtocol parameters are valid only for PowerShell Core 6+"
	}

	$FileCounter = 0
	foreach ($Markdown in $MarkdownFiles)
	{
		$File = $Markdown.Name
		$FullName = $Markdown.FullName
		$PercentComplete = $FileCounter / $MarkdownFiles.Count * 100

		# Convert elapsed time to short time string: [double] -> [string] -> [System.DateTime] -> [string]
		$DmftTime = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($SecondsElapsed.ToString())
		$DateTimeTotal = [System.Management.ManagementDateTimeConverter]::ToDateTime($DmftTime)
		$TotalTime = [string]::Format($DateTimeTotal.ToLongTimeString(), "dd\:hh\:mm")

		$ProgressParams = @{
			Activity = "File [$($FileCounter + 1)/$($MarkdownFiles.Count)] $TotalTime elapsed"
			Status = "Analyzing file: $File"
			CurrentOperation = "File path: $FullName"
			PercentComplete = $PercentComplete
			Id = 1
		}

		if ($SecondsRemaining)
		{
			$ProgressParams["SecondsRemaining"] = $SecondsRemaining
		}

		$FileCounter += 1
		Write-Progress @ProgressParams
		Write-Information -MessageData "INFO: Analyzing file $FullName"

		[uri[]] $FileLinks = Select-String -Path $Markdown -Pattern "\[.+\]\((http.*?)\)" | ForEach-Object {
			# [Microsoft.PowerShell.Commands.MatchInfo]
			# [System.Text.RegularExpressions.GroupCollection]
			$_.Matches.Groups[1].ToString()
		} | Select-Object

		if (!$FileLinks)
		{
			Write-Verbose -Message "File '$File' contains no links"
			continue
		}

		# NOTE: The counter will not reset on subsequent foreach loop
		# New-Variable -Name LinkCounter -Scope Script -Value 0

		$LinkCounter = 0
		foreach ($Link in $FileLinks)
		{
			$URL = $Link.AbsoluteUri
			$PercentComplete = $LinkCounter / $FileLinks.Count * 100

			$ProgressParams = [hashtable]@{
				Activity = "Link [$($LinkCounter + 1)/$($FileLinks.Count)]"
				Status = "Testing link"
				CurrentOperation = "Link URL: $URL"
				PercentComplete = $PercentComplete
				Id = 2
				ParentId = 1
			}

			$LinkCounter += 1
			Write-Progress @ProgressParams

			try
			{
				# Suppress progress bar from Invoke-WebRequest
				$DefaultProgress = $ProgressPreference
				$ProgressPreference = "SilentlyContinue"

				# [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]
				Invoke-WebRequest -Uri $URL -DisableKeepAlive @WebParams | Out-Null

				$ProgressPreference = $DefaultProgress
			}
			catch
			{
				Write-Warning -Message "Found dead link in '$File' -> $URL"
				$StatusReport += [PSCustomObject]@{
					FullName = $FullName
					URL = $URL
				}
			}
		}

		# Remove-Variable -Name LinkCounter -Scope Script

		# Estimate the time remaining
		$SecondsElapsed = (Get-Date) - $StartTime
		$SecondsRemaining = ($SecondsElapsed.TotalSeconds / $FileCounter) * ($MarkdownFiles.Count - $FileCounter)
	}

	# Optional, if the progress bar don't go away by itself, un-comment this line
	# Write-Progress -Activity "Test markdown links" -Completed

	if ($StatusReport.Count)
	{
		Write-Information -MessageData "*** Test summary ***"

		foreach ($Status in $StatusReport)
		{
			Write-Error -Category ResourceUnavailable -TargetObject $Status.URL -Message "Dead link -> $($Status.URL)"
			Write-Information -MessageData "INFO: Found in file -> $($Status.FullName)"
		}
	}
}

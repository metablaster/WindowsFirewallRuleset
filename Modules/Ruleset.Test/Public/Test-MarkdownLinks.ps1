
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
Test links in markdown files

.DESCRIPTION
Test each link in markdown file and report if any link is dead

.PARAMETER Path
The path to directory containing target markdown files

.PARAMETER Recurse
If specified, recurse in to the path specified by Path parameter

.PARAMETER TimeoutSec
Specifies (per link) how long the request can be pending before it times out

.PARAMETER MaximumRetryCount
Specifies (per link) how many times PowerShell retries a connection when a failure code between 400
and 599, inclusive or 304 is received.
This parameter is valid for PowerShell Core edition only.

.PARAMETER RetryIntervalSec
Specifies the interval between retries for the connection when a failure code between 400 and
599, inclusive or 304 is received
This parameter is valid for PowerShell Core edition only.

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
PS> Test-MarkdownLinks -Path C:\GitHub\MyProject -Recurse

.EXAMPLE
PS> Test-MarkdownLinks -Path C:\GitHub\MyProject -SslProtocol Tls -NoProxy

.INPUTS
None. You cannot pipe objects to Test-MarkdownLinks

.OUTPUTS
None. Test-MarkdownLinks does not generate any output

.NOTES
WebSslProtocol enum does not list Tls13
TODO: Implement parameters for Get-ChildItem
#>
function Test-MarkdownLinks
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-MarkdownLinks.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
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
		[string] $SslProtocol = "Default",

		[Parameter()]
		[switch] $NoProxy
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Get markdown files recursively
	[System.IO.FileInfo[]] $MarkdownFiles = Get-ChildItem -Path $Path -Recurse:$Recurse -Include "*.md"

	if ($MarkdownFiles.Count -eq 0)
	{
		Write-Warning -Message "No markdown files were found specified by Path parameter"
		return
	}

	# Save progress preference
	$DefaultProgress = $ProgressPreference

	[scriptblock] $GetElapsedTime = {
		param ($SecondsElapsed)

		# Convert elapsed time to short time string: [double] -> [string] -> [System.DateTime] -> [string]
		$DmftTime = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($SecondsElapsed.ToString())
		$DateTimeTotal = [System.Management.ManagementDateTimeConverter]::ToDateTime($DmftTime)
		[string]::Format($DateTimeTotal.ToLongTimeString(), "dd\:hh\:mm")
	}

	# Unreachable links
	[PSCustomObject[]] $StatusReport = @()

	# Set up web request parameters
	$WebParams = [hashtable]@{
		TimeoutSec = $TimeoutSec
		MaximumRedirection = $MaximumRedirection
		DisableKeepAlive = $true
	}

	if ($PSVersionTable.PSEdition -eq "Desktop")
	{
		# Beginning with PowerShell 6.0.0 Invoke-WebRequest supports basic parsing only
		# Otherwise throws: WebCmdletIEDomNotSupportedException
		$WebParams.Add("UseBasicParsing", $true)
	}
	else
	{
		$WebParams.Add("MaximumRetryCount", $MaximumRetryCount)
		$WebParams.Add("RetryIntervalSec", $RetryIntervalSec)

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
	}

	# Outer progress bar setup
	$StartTime = Get-Date
	[timespan] $Elapsed = 0
	[double] $Remaining = -1
	$MultiFile = $MarkdownFiles.Count -gt 1

	$FileCounter = 0
	foreach ($Markdown in $MarkdownFiles)
	{
		$File = $Markdown.Name
		$FullName = $Markdown.FullName

		if ($MultiFile)
		{
			$ProgressParams = [hashtable]@{
				Activity = "File [$($FileCounter + 1)/$($MarkdownFiles.Count)] $(& $GetElapsedTime $Elapsed) elapsed"
				Status = "Analyzing file"
				CurrentOperation = "File: $FullName"
				PercentComplete = $FileCounter / $MarkdownFiles.Count * 100
				SecondsRemaining = $Remaining
				Id = 1
			}

			Write-Progress @ProgressParams
		}

		++$FileCounter
		Write-Information -Tags "Project" -MessageData "INFO: Analyzing file $FullName"

		[uri[]] $FileLinks = Select-String -Path $Markdown -Pattern "\[.+\]\((http.*?)\)" | ForEach-Object {
			# [Microsoft.PowerShell.Commands.MatchInfo]
			# [System.Text.RegularExpressions.GroupCollection]
			$_.Matches.Groups[1].ToString()
		} | Select-Object

		if (!$FileLinks)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] File '$File' contains no links"
			continue
		}

		# Inner progress bar setup
		$StartTime2 = Get-Date
		[timespan] $Elapsed2 = 0
		[double] $Remaining2 = -1

		$LinkCounter = 0
		foreach ($Link in $FileLinks)
		{
			$URL = $Link.AbsoluteUri
			$Percent2 = $LinkCounter / $FileLinks.Count * 100

			if ($MultiFile)
			{
				$ProgressParams2 = [hashtable]@{
					Activity = "Link [$($LinkCounter + 1)/$($FileLinks.Count)] $(& $GetElapsedTime $Elapsed2) elapsed"
					Status = "Testing link"
					CurrentOperation = "URL: $URL"
					PercentComplete = $Percent2
					SecondsRemaining = $Remaining2
					Id = 2
					ParentId = 1
				}
			}
			else
			{
				$ProgressParams2 = [hashtable]@{
					Activity = "Link [$($LinkCounter + 1)/$($FileLinks.Count)] $(& $GetElapsedTime $Elapsed2) elapsed"
					Status = "Analyzing file: $FullName"
					CurrentOperation = "Testing link: $URL"
					PercentComplete = $Percent2
					SecondsRemaining = $Remaining2
				}
			}

			++$LinkCounter
			Write-Progress @ProgressParams2
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Testing link $URL"

			try
			{
				# Suppress progress bar from Invoke-WebRequest
				$ProgressPreference = "SilentlyContinue"

				# [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]
				Invoke-WebRequest -Uri $URL @WebParams | Out-Null
			}
			catch
			{
				Write-Warning -Message "Found dead link in '$File' -> $URL"
				$StatusReport += [PSCustomObject]@{
					FullName = $FullName
					URL = $URL
				}
			}
			finally
			{
				$ProgressPreference = $DefaultProgress
			}

			if ($MultiFile)
			{
				# Estimate the time remaining
				$Elapsed = (Get-Date) - $StartTime
				$Remaining = ($Elapsed.TotalSeconds / $FileCounter) * ($MarkdownFiles.Count - $FileCounter)
			}

			$Elapsed2 = (Get-Date) - $StartTime2
			$Remaining2 = ($Elapsed2.TotalSeconds / $LinkCounter) * ($FileLinks.Count - $LinkCounter)
		}

		Write-Progress $ProgressParams2 -Completed

		$Elapsed = (Get-Date) - $StartTime
		$Remaining = ($Elapsed.TotalSeconds / $FileCounter) * ($MarkdownFiles.Count - $FileCounter)
	}

	if ($MultiFile)
	{
		Write-Progress $ProgressParams -Completed
	}

	if ($StatusReport.Count)
	{
		Write-Information -Tags "Project" -MessageData "*** LINK STATUS REPORT ***"

		foreach ($Status in $StatusReport)
		{
			Write-Error -Category ResourceUnavailable -TargetObject $Status.URL -Message "Dead link -> $($Status.URL)"
			Write-Information -Tags "Project" -MessageData "INFO: Found in file -> $($Status.FullName)"
		}
	}
}

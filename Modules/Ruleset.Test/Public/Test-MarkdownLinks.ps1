
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
Test each link in one or multiple markdown files and report if any link is dead.
You can "brute force" test links or test only unique ones.
Links to be tested can be excluded or included by using wildcard pattern.
Test can be customized for various TLS protocols, query timeouts and retry attempts.
The links to be tested can be reference links, inline links or both.

.PARAMETER Path
Specifies a path to one or more locations containing target markdown files.
Wildcard characters are supported.

.PARAMETER LiteralPath
Specifies a path to one or more locations containing target markdown files.
The value of LiteralPath is used exactly as it's typed.
No characters are interpreted as wildcards.

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

.PARAMETER Include
Specifies an URL wildcard pattern that this function includes in the operation.

.PARAMETER Exclude
Specifies an URL wildcard pattern that this function excludes from operation.

.PARAMETER LinkType
Specifies the type of links to check, acceptable values are:

-Inline ex. [label](URL)
-Reference ex. [label]: URL
-Any process both inline and reference links

.PARAMETER Unique
If specified, only unique links are tested reducing the amount of time needed for bulk link test operation

.PARAMETER Depth
The Depth parameter determines the number of subdirectory levels that are included in the recursion.
For example, Depth 2 includes the Path parameter's directory, first level of subdirectories, and
second level of subdirectories.

.EXAMPLE
PS> Test-MarkdownLinks -Path C:\GitHub\MyProject -Recurse

.EXAMPLE
PS> Test-MarkdownLinks -Path C:\GitHub\MyProject -SslProtocol Tls -NoProxy

.EXAMPLE
PS> Test-MarkdownLinks .\MyProject\MarkdownFile.md -LinkType "Reference" -Include *microsoft.com*

.INPUTS
None. You cannot pipe objects to Test-MarkdownLinks

.OUTPUTS
None. Test-MarkdownLinks does not generate any output

.NOTES
WebSslProtocol enum does not list Tls13
TODO: Implement pipeline support
#>
function Test-MarkdownLinks
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Path",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-MarkdownLinks.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
		[SupportsWildcards()]
		[string[]] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "Literal")]
		[string[]] $LiteralPath,

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
		[switch] $NoProxy,

		[Parameter()]
		[SupportsWildcards()]
		[string] $Include = "*",

		[Parameter()]
		[SupportsWildcards()]
		[string] $Exclude,

		[Parameter()]
		[ValidateSet("Reference", "Inline", "Any")]
		[string] $LinkType = "Any",

		[Parameter()]
		[switch] $Unique,

		[Parameter()]
		[uint32] $Depth
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$ChildItemParams = @{
		Recurse = $Recurse
	}

	if ($PSCmdlet.ParameterSetName -eq "Path")
	{
		$ChildItemParams.Add("Path", $Path)
	}
	else
	{
		$ChildItemParams.Add("LiteralPath", $LiteralPath)
	}

	if ($Depth -gt 0)
	{
		$ChildItemParams.Add("Depth", $Depth)
	}

	# Get markdown files
	[System.IO.FileInfo[]] $MarkdownFiles = Get-ChildItem @ChildItemParams -Include "*.md"

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

	# All unique links already tested
	[uri[]] $UniqueLinks = @()

	# Total duplicate links skipped (if Unique was specified)
	$TotalDiscarded = 0
	# Links tested in total
	$TotalLinksTested = 0

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

	# Include/Exclude link
	[scriptblock] $SkipLink = {
		param (
			[Parameter(Mandatory = $true)]
			[uri] $Link,

			[Parameter(Mandatory = $true)]
			[ref] $TotalDiscarded
		)

		if ($Link.AbsoluteUri -notlike $Include)
		{
			++$TotalDiscarded.Value
			return $true
		}
		elseif (![string]::IsNullOrEmpty($Exclude) -and ($Link.AbsoluteUri -like $Exclude))
		{
			++$TotalDiscarded.Value
			return $true
		}

		return $false
	}

	# Outer progress bar setup
	$StartTime = Get-Date
	[timespan] $Elapsed = 0
	[double] $Remaining = -1
	$MultiFile = $MarkdownFiles.Count -gt 1

	$FileCounter = 0
	foreach ($Markdown in $MarkdownFiles)
	{
		if (!$Markdown.Exists)
		{
			Write-Error -Category ObjectNotFound -TargetObject $Markdown `
				-Message "Markdown file could not be found because it doesn't exist: $FullName"
			continue
		}

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

		[uri[]] $FileLinks = @()

		if (($LinkType -eq "Any") -or ($LinkType -eq "Inline"))
		{
			# Capture inline links
			$FileLinks += Select-String -Path $Markdown -Pattern "(?<=\[.+\]\()(http.*)(?=\))" -Encoding $DefaultEncoding | ForEach-Object {
				# [Microsoft.PowerShell.Commands.MatchInfo]
				$_.Matches.Groups[1].ToString()
			} | Where-Object { !(& $SkipLink $_ ([ref] $TotalDiscarded)) }
		}

		if (($LinkType -eq "Any") -or ($LinkType -eq "Reference"))
		{
			# Capture reference links
			$FileLinks += Select-String -Path $Markdown -Encoding $DefaultEncoding `
				-Pattern "(?<=\[.+\]:\s)([(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)(\(.+\))?)" |
			ForEach-Object {
				$_.Matches.Groups[1].ToString()
			} | Where-Object { !(& $SkipLink $_ ([ref] $TotalDiscarded)) }
		}

		if ($Unique)
		{
			$LinkCount = $FileLinks.Count
			# Get rid of duplicate and already tested links
			$FileLinks = $FileLinks | Where-Object {
				$_ -notin $UniqueLinks
			}
		}

		if (!$FileLinks)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] File '$File' matches no links"
			continue
		}
		elseif ($Unique)
		{
			$UniqueLinks += $FileLinks
			$Discarded = $LinkCount - $FileLinks.Count
			$TotalLinksTested = $UniqueLinks.Count

			if ($Discarded -gt 0)
			{
				$TotalDiscarded += $Discarded
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Discarded duplicate links were skipped from file '$File'"
			}
		}
		else
		{
			$TotalLinksTested += $FileLinks.Count
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
		Write-Information -Tags "Project" -MessageData "*** LINK TEST STATUS REPORT ***"

		foreach ($Status in $StatusReport)
		{
			Write-Error -Category ResourceUnavailable -TargetObject $Status.URL -Message "Dead link -> $($Status.URL)"
			Write-Information -Tags "Project" -MessageData "INFO: Found in file -> $($Status.FullName)"
		}

		if ($StatusReport.Count -eq 1)
		{
			Write-Warning -Message "Only 1 dead link found"
		}
		else
		{
			Write-Warning -Message "In total there are $($StatusReport.Count) dead links"
		}
	}

	Write-Information -Tags "Project" -MessageData "$TotalLinksTested links were tested in total"
	Write-Information -Tags "Project" -MessageData "$TotalDiscarded links were discarded"
}

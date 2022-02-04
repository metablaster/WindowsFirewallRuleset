
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.12.0

.GUID 6734776b-e551-4313-b598-cdff26b80c13

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Scan executables for digital signature and check virus total status

.DESCRIPTION
Use Find-UnsignedFile.ps1 to scan executable files in specified directory for digital signature.
If file being scanned lacks digital signature it is optionally sent to virus total for analysis.
The result of scan and virus analysis can be optionally saved to JSON file for later inspection.

.PARAMETER Path
Directory which is to be scanned for executable files.
Wildcard characters are permitted.

.PARAMETER LiteralPath
Directory which is to be scanned for executable files.
The value of LiteralPath is used exactly as it's typed.
No characters are interpreted as wildcards.

.PARAMETER Driver
If specified, system drivers are checked for digital signature and
uploaded to virus total if necessary.

.PARAMETER Filter
Specify executable program type (file extension) which is to be searched in path specified by -LiteralPath.
The default is *.exe

.PARAMETER SigcheckLocation
Specify path to sigcheck executable program.
Do not specify sigcheck file, only path to where sigcheck is located.
By default working directory and PATH is searched for sigcheck64.exe.
On 32 bit operating system sigcheck.exe is searched instead.

.PARAMETER Log
If specified, the result of scan is saved to JSON file.

.PARAMETER LogName
Filename into which to save the result of scan, JSON format.
By default, scan results are saved into ScanResult.json inside working directory.

.PARAMETER All
If specified, all unsigned files are reported.
By default if VirusTotal check is enabled, only files that are unknown by VirusTotal or
have non-zero detection are reported.

.PARAMETER Recurse
If specified, the path specified by -LiteralPath is recursed.

.PARAMETER VirusTotal
If specified, file hash of the files lacking digital signature are sent to virus total for malware check,
files which were never scanned by virus total are uploaded for analysis.
Note that individual scan results may not be available for five or more minutes.

.PARAMETER SkipUpload
If specified, files reported as not previously scanned will not be uploaded to VirusTotal.
By default files never scanned by virus total are uploaded and web page is opened in
default web browser for each un-scanned file for review.

.PARAMETER Append
If specified, appends scan result to json file.
By default existing file (if any) is replaced.

.PARAMETER FileSize
Maximum file size to be sent to virus total expressed in MB.
Files which exceed this value won't be sent to virus total for malware analysis.
The default value is 2 MB.
Virus total maximum file size is 650 MB.

.PARAMETER Timeout
Specify maximum wait time expressed in seconds for virus total to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

.EXAMPLE
PS> Find-UnsignedFile C:\Windows\system32 -Log -VirusTotal

.EXAMPLE
PS> Find-UnsignedFile C:\Windows\system32 -Type com

.EXAMPLE
PS> Find-UnsignedFile C:\Windows\ -VirusTotal -Log -Recurse -SkipUpload

.INPUTS
None. You cannot pipe objects to Find-UnsignedFile.ps1

.OUTPUTS
None. Find-UnsignedFile.ps1 does not generate any output

.NOTES
TODO: More functionality can be implemented by handling more sigcheck switches

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false, DefaultParameterSetName = "Path")]
[OutputType([void])]
param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
	[SupportsWildcards()]
	[string] $Path,

	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "LiteralPath")]
	[string] $LiteralPath,

	[Parameter(ParameterSetName = "Driver")]
	[switch] $Driver,

	[Parameter(ParameterSetName = "Path")]
	[Parameter(ParameterSetName = "LiteralPath")]
	[string] $Filter = "*.exe",

	[Parameter()]
	[System.IO.DirectoryInfo] $SigcheckLocation = $PSScriptRoot,

	[Parameter()]
	[switch] $Log,

	[Parameter()]
	[string] $LogName = "$PSScriptRoot\..\..\Exports\ScanStatus.json",

	[Parameter()]
	[switch] $All,

	[Parameter(ParameterSetName = "Path")]
	[Parameter(ParameterSetName = "LiteralPath")]
	[switch] $Recurse,

	[Parameter()]
	[switch] $VirusTotal,

	[Parameter()]
	[switch] $SkipUpload,

	[Parameter()]
	[switch] $Append,

	[Parameter()]
	[ValidateRange(1, 650)]
	[int32] $FileSize = 2,

	[Parameter()]
	[ValidateRange(1, 650)]
	[int32] $TimeOut = 300
)

Write-Debug -Message "ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
$InformationPreference = "Continue"

if ([string]::IsNullOrEmpty($Path))
{
	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
}
elseif ($Driver)
{
	$ExpandedPath = "Driver store"
}
else
{
	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
	$ExpandedPath = Resolve-Path -Path $ExpandedPath
}

if ($PSCmdlet.ShouldProcess($ExpandedPath, "Bulk digital signature check for '$Filter' files"))
{
	$StopWatch = [System.Diagnostics.Stopwatch]::new()
	$StopWatch.Start()

	if ($Driver)
	{
		$Filter = "*.sys"
		$Files = Get-CimInstance -Class Win32_SystemDriver | Select-Object -ExpandProperty PathName
	}
	else
	{
		Write-Information -MessageData "INFO: Scanning $ExpandedPath for executable files with '$Filter' extension"

		if (!$Filter.StartsWith("*.")) { $Filter = "*.$Filter" }
		$Files = Get-ChildItem -Path $ExpandedPath -Filter $Filter -Recurse:$Recurse
	}

	$TotalFiles = ($Files | Measure-Object).Count

	if ($TotalFiles -gt 0)
	{
		Write-Information -MessageData "INFO: Checking $TotalFiles '$Filter' files in $ExpandedPath"
	}
	else
	{
		Write-Warning -Message "No executable files with '$Filter' extension have been found in $ExpandedPath"
		return
	}

	# Save log file to working directory if only file name is specified
	if ($Log -and !$LogName.Contains("\"))
	{
		$LogName = ".\$LogName"
	}

	if ($VirusTotal)
	{
		$SigcheckDir = [System.Environment]::ExpandEnvironmentVariables($SigcheckLocation.FullName)
		$SigcheckDir = Resolve-Path -Path $SigcheckDir

		if ((Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture) -eq "64-bit")
		{
			$SigcheckExecutable = "sigcheck64.exe"
		}
		else
		{
			$SigcheckExecutable = "sigcheck.exe"
		}

		# Check if path to sigcheck executable is valid
		if (Test-Path -Path "$SigcheckDir\$SigcheckExecutable")
		{
			$SigCheckFile = "$SigcheckDir\$SigcheckExecutable"
		}
		else
		{
			# Check if sigcheck is in path
			$Command = Get-Command -Name $SigcheckExecutable -CommandType Application -ErrorAction Ignore

			# Can be, not found or there are multiple matches
			if (($Command | Measure-Object).Count -eq 1)
			{
				$SigCheckFile = $Command.Name
			}
			else
			{
				Write-Error -Category ObjectNotFound -Message "$SigcheckExecutable was not found in specified path '$SigcheckDir'"
				return
			}
		}

		Write-Verbose -Message "Using sigcheck file: $SigCheckFile"

		# Create sigcheck process object
		$Process = New-Object System.Diagnostics.Process

		# The application or document to start
		$Process.StartInfo.FileName = $SigCheckFile

		# Whether to start the process in a new window
		$Process.StartInfo.CreateNoWindow = $true

		# Whether to use the operating system shell to start the process
		# If the UserName property is not null or an empty string, the UseShellExecute property must be false
		# UseShellExecute must also be false to redirect output
		$Process.StartInfo.UseShellExecute = $false

		# Whether the textual output of an application is written to the StandardOutput stream
		$Process.StartInfo.RedirectStandardOutput = $true

		# Whether the error output of an application is written to the StandardError stream
		$Process.StartInfo.RedirectStandardError = $true
	}

	if ($Log)
	{
		# JSON root file data
		[hashtable] $JsonData = @{}

		# Script block used to write scan results into JSON file
		[scriptblock] $WriteFile = {
			[CmdletBinding(PositionalBinding = $false)]
			param (
				# Full path to JSON file
				[Parameter(Mandatory = $true, Position = 0)]
				[SupportsWildcards()]
				[string] $FilePath,

				# JSON data which to write to file
				[Parameter(Mandatory = $true)]
				[hashtable] $FileData,

				# If specified, JSON data is appended to file
				[Parameter()]
				[switch] $Append
			)

			Write-Debug -Message "[WriteFile] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

			$ParentPath = Split-Path -Path $FilePath -Parent
			$ParrentPath = (Resolve-Path -Path $ParentPath).Path

			$FileName = Split-Path -Path $FilePath -Leaf
			$FileName = "$ParrentPath\$FileName"

			if (!$ParentPath)
			{
				New-Item -Path $ParentPath -ItemType Directory | Out-Null
			}

			# NOTE: Split-Path -Extension is not available in Windows PowerShell
			$FileExtension = [System.IO.Path]::GetExtension($FileName)

			# Verify extension is *.json, if not add it
			if (!$FileExtension -or ($FileExtension -ne ".json"))
			{
				Write-Debug -Message "[WriteFile] Adding extension to file"
				$FileName += ".json"
			}

			if ($Append)
			{
				if (Test-Path -PathType Leaf -Path $FileName)
				{
					Write-Debug -Message "[WriteFile] Appending JSON data to file"
					$JsonFile = ConvertFrom-Json -InputObject (Get-Content -Path $FileName -Raw)
					@($JsonFile; $FileData) | ConvertTo-Json | Set-Content -Path $FileName -Encoding utf8
				}
				else
				{
					Write-Debug -Message "[WriteFile] Not appending to JSON file because no existing file"
					$FileData | ConvertTo-Json | Set-Content -Path $FileName -Encoding utf8
				}
			}
			else
			{
				Write-Debug -Message "[WriteFile] Replacing contents in JSON file"
				$FileData | ConvertTo-Json | Set-Content -Path $FileName -Encoding utf8
			}
		}

		# Unsigned files not processed by virus total
		[array] $SkippedFiles = @()

		# Unsigned files processed by virus total
		[array] $ScannedFiles = @()
	}

	# Counter for progress
	[int32] $FileCount = 0

	foreach ($File in $Files)
	{
		if ($Driver)
		{
			$FilePath = $File
			$FileName = Split-Path -Path $File -Leaf
		}
		else
		{
			$FilePath = $File.FullName
			$FileName = $File.Name
		}

		if ($TotalFiles -gt 50)
		{
			Write-Progress -Activity "Processing files" -CurrentOperation $FilePath `
				-PercentComplete (++$FileCount / $TotalFiles * 100) `
				-SecondsRemaining (($TotalFiles - $FileCount + 1) / 10 * 60)
		}
		else
		{
			Write-Verbose -Message "Processing file $FilePath"
		}

		$Signature = Get-AuthenticodeSignature -LiteralPath $FilePath

		if ($Signature.Status -ne "Valid")
		{
			Write-Warning -Message "Unsigned file detected $FileName"

			if ($VirusTotal -and $PSCmdlet.ShouldProcess($FilePath, "Upload file to virus total for malware analysis"))
			{
				# Ensure scanned file does not exceed user specified maximum file size for virus total processing
				$FileBytes = (Get-Item -Path $FilePath | Select-Object -ExpandProperty Length)
				$FileMegaBytes = [System.Math]::Round($FileBytes / (1024 * 1024), 2)

				if ($FileMegaBytes -gt $FileSize)
				{
					Write-Warning -Message "File size of $FileMegaBytes MB exceeded specified virus total maximum file size of $FileSize MB"

					if ($Log)
					{
						$SkippedFiles += $FilePath
					}

					continue
				}
				else
				{
					Write-Verbose -Message "$FileName is $FileMegaBytes MB which is less than specified maximum of $FileSize MB"
				}

				# A collection of command-line arguments to use when starting the application
				# -vt accept virus total license
				$Process.StartInfo.Arguments = "-vt -accepteula -nobanner"

				if ($SkipUpload)
				{
					# Open report in web browser
					$Process.StartInfo.Arguments += " -vr"
				}
				else
				{
					# Open report in web browser and upload files never scanned by virus total
					$Process.StartInfo.Arguments += " -vrs"
				}

				if (!$All)
				{
					# If VirusTotal check is enabled, show files that are unknown by VirusTotal or
					# have non-zero detection, otherwise show only unsigned files.
					$Process.StartInfo.Arguments += " -u"
				}

				# File which is to be scanned
				$Process.StartInfo.Arguments += " `"$FilePath`""
				Write-Debug -Message "Sigcheck arguments are $($Process.StartInfo.Arguments)"

				if (!$Process.Start())
				{
					Write-Error -Category InvalidResult -TargetObject $Process -Message "Starting process '$SigCheckFile' failed"

					if ($Log)
					{
						$SkippedFiles += $FilePath
					}

					continue
				}

				Write-Verbose -Message "Parsing sigcheck output, synchronous read operation"
				[hashtable] $ScanResult = @{}

				while (!$Process.StandardOutput.EndOfStream)
				{
					# Reads a line of characters from the current stream and returns the data as [string]
					# Methods such as Read, ReadLine, and ReadToEnd perform synchronous read operations
					# on the output stream of the process
					$StreamLine = $Process.StandardOutput.ReadLine()

					if (![string]::IsNullOrEmpty($StreamLine))
					{
						Write-Debug -Message "Processing $SigCheckFile output: $StreamLine"

						$VTDetection = [regex]::Match($StreamLine, "(?<VTdetection>VT detection:\s+)(?<status>.*)")
						$VTLink = [regex]::Match($StreamLine, "(?<VTlink>VT link:\s+)(?<link>.*)")
						$RawPublisher = [regex]::Match($StreamLine, "(?<VTdetection>Description:\s+)(?<publisher>.*)")
						$RawDescription = [regex]::Match($StreamLine, "(?<VTlink>Publisher:\s+)(?<description>.*)")

						$Detection = $VTDetection.Groups["status"]
						$Link = $VTLink.Groups["link"]
						$Publisher = $RawPublisher.Groups["publisher"]
						$Description = $RawDescription.Groups["description"]

						if ($Detection.Success)
						{
							Write-Information -MessageData "INFO: $FileName Virus total status is '$($Detection.Value)'"

							if ($Log)
							{
								$ScanResult.Add("VT status is", $Detection.Value)
							}
						}

						if ($Link.Success)
						{
							Write-Verbose -Message "$FileName VT Link is $($Link.Value)"

							if ($Log)
							{
								$ScanResult.Add("VT link", $Link.Value)
							}
						}

						if ($Publisher.Success)
						{
							Write-Verbose -Message "$FileName Publisher is $($Publisher.Value)"

							if ($Log)
							{
								$ScanResult.Add("Publisher", $Publisher.Value)
							}
						}

						if ($Description.Success)
						{
							Write-Verbose -Message "$FileName Description is $($Description.Value)"

							if ($Log)
							{
								$ScanResult.Add("Description", $Description.Value)
							}
						}

						$ScanResult.Add("FilePath", $FilePath)
					}
				}

				if ($Log)
				{
					$ScannedFiles += $ScanResult
					Write-Debug -Message "Scan result is $($ScanResult | Out-String)"
					Write-Debug -Message "ScannedFiles variable is $($ScannedFiles | Out-String)"
				}

				# If sigcheck produces any errors it should write them here
				$StandardError = $Process.StandardError.ReadToEnd()
				if (![string]::IsNullOrEmpty($StandardError))
				{
					Write-Output $StandardError
				}

				# True if the associated process has exited, otherwise false
				# The amount of time, in milliseconds, to wait for the associated process to exit.
				# Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
				$StatusWait = $Process.WaitForExit($TimeOut * 1000)

				if (!$StatusWait)
				{
					Write-Warning -Message "Process '$SigCheckFile' failed to exit, killing process"

					# Immediately stops the associated process, and optionally its child/descendent processes (true)
					$Process.Kill()
					continue
				}

				# The Close method causes the process to stop waiting for exit if it was waiting,
				# closes the process handle, and clears process-specific properties.
				# NOTE: Close does not close the standard output, input, and error readers and writers in
				# case they are being referenced externally
				Write-Debug -Message "Closing $SigcheckFile process"
				$Process.Close()
			}
			elseif ($Log)
			{
				$SkippedFiles += $FilePath
				Write-Debug -Message "SkippedFiles variable contains $($SkippedFiles | Out-String)"
			}
		} # if signature not valid
	} # foreach file

	if ($Log -and $PSCmdlet.ShouldProcess($LogName, "Write scan results to file"))
	{
		if ($SkippedFiles.Count -gt 0)
		{
			Write-Debug -Message "Adding skipped files to JSON root: $($SkippedFiles | Out-String)"
			$JsonData.Add("Files skipped from virus total analysis", $SkippedFiles)
		}

		if ($ScannedFiles.Count -gt 0)
		{
			Write-Debug -Message "Adding skipped files to JSON root: $($ScannedFiles | Out-String)"
			$JsonData.Add("Files analyzed by virus total", $ScannedFiles)
		}

		if (($JsonData | Measure-Object).Count -gt 0)
		{
			& $WriteFile $LogName -FileData $JsonData -Append:$Append
		}
		else
		{
			Write-Debug -Message "There is nothing to write to file $($JsonData | Out-String)"
		}
	}

	$StopWatch.Stop()
	$TotalHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
	$TotalMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
	$TotalSeconds = $StopWatch.Elapsed | Select-Object -ExpandProperty Seconds

	Write-Information -MessageData "INFO: Time elapsed: $TotalHours hours, $TotalMinutes minutes and $TotalSeconds seconds"
	Write-Information -MessageData "INFO: All operations completed successfully!"
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Check if executable file exists and is trusted.

.DESCRIPTION
Test-ExecutableFile verifies the path to executable file is valid and that executable itself exists.
File extension is then verified to confirm it is whitelisted, ex. such as an *.exe
The executable is then verified to ensure it's digitaly signed and that signature is valid.
If digital signature is missing or not valid, the file is optionally scanned on virus total to
confirm it's not malware.
If the file can't be found or verified, an error is genrated possibly with informational message,
to explain if there is any problem with the path or file name syntax, otherwise information is
present to the user to explain how to resolve the problem including a stack trace to script that
is producing this issue.

.PARAMETER LiteralPath
Fully qualified path to executable file

.PARAMETER SigcheckLocation
Specify path to sigcheck executable program.
Do not specify sigcheck file, only path to where sigcheck is located.
By default working directory and PATH is searched for sigcheck64.exe.
On 32 bit operating system sigcheck.exe is searched instead.
If location to sigcheck executable is not found then no virus total scan and report is done.

.PARAMETER Timeout
Specify maximum wait time expressed in seconds for virus total to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

.PARAMETER Quiet
If specified, no information, warning or error message is shown, only true or false is returned

.PARAMETER Force
If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in bypassed signature test.

.EXAMPLE
PS> Test-ExecutableFile "C:\Windows\UnsignedFile.exe"

ERROR: Digital signature verification failed for: C:\Windows\UnsignedFile.exe

.EXAMPLE
PS> Test-ExecutableFile "C:\Users\USERNAME\AppData\Application\chrome.exe"

WARNING: Executable 'chrome.exe' was not found, firewall rule not loaded
INFO: Searched path was: C:\Users\USERNAME\AppData\Application\chrome.exe
INFO: To fix this problem find 'chrome.exe' and update installation directory in Test-ExecutableFile.ps1 script

.EXAMPLE
PS> Test-ExecutableFile "\\COMPUTERNAME\Directory\file.exe"

ERROR: Specified file path is missing a file system qualifier: \\COMPUTERNAME\Directory\file.exe

.EXAMPLE
PS> Test-ExecutableFile ".\..\file.exe"

ERROR: Specified file path is relative: .\..\file.exe

.EXAMPLE
PS> Test-ExecutableFile "C:\Bad\<Path>\Loca'tion"

ERROR: Specified file path contains invalid characters: C:\Bad\<Path>\Loca'tion

.INPUTS
None. You cannot pipe objects to Test-ExecutableFile

.OUTPUTS
[bool]

.NOTES
TODO: We should attempt to fix the path if invalid here, ex. Get-Command (-Repair parameter)
TODO: We should return true or false and conditionally load rule
TODO: Verify file is executable file (and path formatted?)
#>
function Test-ExecutableFile
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $LiteralPath,

		[Parameter()]
		[System.IO.DirectoryInfo] $SigcheckLocation = $SigcheckPath,

		[Parameter()]
		[ValidateRange(1, 650)]
		[int32] $TimeOut = 300,

		[Parameter()]
		[switch] $Quiet,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($Quiet)
	{
		$ErrorActionPreference = "SilentlyContinue"
		$WarningPreference = "SilentlyContinue"
		$InformationPreference = "SilentlyContinue"
	}

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking file path: $ExpandedPath"

	$Executable = Split-Path -Path $ExpandedPath -Leaf

	# NOTE: Index 0 is this function
	$Caller = (Get-PSCallStack)[1].Command

	if (Test-FileSystemPath $ExpandedPath -PathType File -Firewall -Quiet:$Quiet)
	{
		if ($ExpandedPath -match "(\\\.\.\\)+")
		{
			# TODO: While valid for fiewall, we want to resolve/format in Format-Path and Resolve-FileSystemPath
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified file path contains parent directory notation: $ExpandedPath"
		}

		# NOTE: Split-Path -Extension is not available in Windows PowerShell
		[string] $Extension = [System.IO.Path]::GetExtension($Executable)

		if ([string]::IsNullOrEmpty($Extension))
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "File extension is missing for specified file: $ExpandedPath"

			return $false
		}

		# Remove starting dot
		$Extension = $Extension.Remove(0, 1).ToUpper()

		if ([string]::IsNullOrEmpty($script:WhiteListExecutable[$Extension]))
		{
			$ExtensionInfo = $script:BlackListExecutable[$Extension]

			if ([string]::IsNullOrEmpty($ExtensionInfo))
			{
				# TODO: Learn extension description
				Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
					-Message "Specified file is not recognized as an executable file: $ExpandedPath"
			}
			else
			{
				Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
					-Message "File extension '$Extension' is blacklisted executable file: $ExpandedPath"

				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Blocked file '$Executable' is $ExtensionInfo"
			}

			return $false
		}

		[scriptblock] $TestVirusTotal = {
			param (
				[Parameter(Mandatory = $true)]
				[string] $LiteralPath,

				[Parameter(Mandatory = $true)]
				[System.IO.DirectoryInfo] $SigcheckLocation,

				[Parameter(Mandatory = $true)]
				[string] $Executable
			)

			$SigcheckDir = [System.Environment]::ExpandEnvironmentVariables($SigcheckLocation.FullName)
			$SigcheckDir = Resolve-Path -Path $SigcheckDir -ErrorAction SilentlyContinue

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
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if sigcheck is in path"
				$Command = Get-Command -Name $SigcheckExecutable -CommandType Application -ErrorAction Ignore

				# Can be, not found or there are multiple matches
				if (($Command | Measure-Object).Count -eq 1)
				{
					$SigCheckFile = $Command.Name
					Write-Debug -Message "[$($MyInvocation.InvocationName)] $SigcheckExecutable found in path"
				}
				else
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] $SigcheckExecutable was not found in specified path '$SigcheckDir', virus total scan will not be performed"
				}
			}

			if ($SigCheckFile)
			{
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

				# A collection of command-line arguments to use when starting the application
				# -vt accept virus total license
				$Process.StartInfo.Arguments = "-vt -accepteula -nobanner"

				# Open report in web browser and upload files never scanned by virus total
				$Process.StartInfo.Arguments += " -vrs"

				# File which is to be scanned
				$Process.StartInfo.Arguments += " `"$LiteralPath`""
				Write-Debug -Message "Sigcheck arguments are $($Process.StartInfo.Arguments)"

				$FileIsMalware = $false
				if ($Process.Start())
				{
					$HeaderStack.Push("Virus total status")

					while (!$Process.StandardOutput.EndOfStream)
					{
						# Reads a line of characters from the current stream and returns the data as [string]
						# Methods such as Read, ReadLine, and ReadToEnd perform synchronous read operations
						# on the output stream of the process
						$StreamLine = $Process.StandardOutput.ReadLine()

						if (![string]::IsNullOrEmpty($StreamLine))
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $SigCheckFile output: $StreamLine"

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
								Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Virus total report for '$Executable' is '$($Detection.Value)'"
								Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT status is", $Detection.Value

								$TotalDetections = [regex]::Match($Detection.Value, "\d+")
								if ($TotalDetections.Success)
								{
									if ([int32] $TotalDetections.Value -gt 0)
									{
										Write-Warning -Message "[$($MyInvocation.InvocationName)] '$Executable' is infected with malware"
										$FileIsMalware = $true
									}
								}
								else
								{
									Write-Error -Category ParserError -TargetObject $Detection `
										-Message "Failed to match total count of infections for '$Executable'"
								}
							}

							if ($Link.Success)
							{
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Executable VT Link is $($Link.Value)"
								Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT link", $Link.Value
							}

							if ($Publisher.Success)
							{
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Executable Publisher is $($Publisher.Value)"
								Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "Publisher", $Publisher.Value
							}

							if ($Description.Success)
							{
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Executable Description is $($Description.Value)"
								Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "Description", $Description.Value
							}
						}
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
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Process '$SigCheckFile' failed to exit, killing process"

						# Immediately stops the associated process, and optionally its child/descendent processes (true)
						$Process.Kill()
					}

					# The Close method causes the process to stop waiting for exit if it was waiting,
					# closes the process handle, and clears process-specific properties.
					# NOTE: Close does not close the standard output, input, and error readers and writers in
					# case they are being referenced externally
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Closing $SigcheckFile process"
					$Process.Close()

					$HeaderStack.Pop() | Out-Null
				}
				else
				{
					Write-Error -Category InvalidResult -TargetObject $Process -Message "Starting process '$SigCheckFile' failed"
				}

				return $FileIsMalware
			} # if sigcheckfile
		}

		# [System.Management.Automation.Signature]
		$Signature = Get-AuthenticodeSignature -LiteralPath $ExpandedPath

		if ($Signature.Status -ne "Valid")
		{
			if ($Force)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Digital signature verification failed for: $ExpandedPath"
				# NOTE: StatusMessage seems to be unrelated to problem
				# Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: $($Signature.StatusMessage)"

				if (!(& $TestVirusTotal -LiteralPath $ExpandedPath -SigcheckLocation $SigcheckLocation -Executable $Executable))
				{
					return $false
				}
			}
			else
			{
				Write-Error -Category SecurityError -TargetObject $LiteralPath `
					-Message "Digital signature verification failed for: $ExpandedPath"

				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: To load rules for unsigned executables run '$Caller' with -Trusted switch"

				& $TestVirusTotal -LiteralPath $ExpandedPath -SigcheckLocation $SigcheckLocation -Executable $Executable | Out-Null
				return $false
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Executable file '$Executable' $($Signature.StatusMessage)"
		return $true
	}

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: To fix this problem locate '$Executable' file and update installation directory in $Caller"

	return $false
}

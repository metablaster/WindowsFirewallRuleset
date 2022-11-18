
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

<#
.SYNOPSIS
Analyze file trough virus total API

.DESCRIPTION
Test-VirusTotal performs malware analysis on file by using sysinternals sigcheck
program which in turn uses virus total API to perform analysis.

.PARAMETER LiteralPath
Fully qualified path to executable file which is to be tested

.PARAMETER Domain
Computer name on which executable file to be tested is located

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

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

.EXAMPLE
PS> Test-VirusTotal -LiteralPath "C:\Windows\notepad.exe" -SigcheckLocation "C:\tools"

.INPUTS
None. You cannot pipe objects to Test-VirusTotal

.OUTPUTS
[bool]

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md
#>
function Test-VirusTotal
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain", SupportsShouldProcess = $true, ConfirmImpact = "Medium",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $LiteralPath,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter(Mandatory = $true)]
		[string] $SigcheckLocation,

		[Parameter()]
		[ValidateRange(1, 650)]
		[int32] $TimeOut = 300
	)

	if ($PSCmdlet.ShouldProcess($LiteralPath, "Run virus total check"))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[hashtable] $SessionParams = @{}
		if ($PsCmdlet.ParameterSetName -eq "Session")
		{
			$SessionParams.Session = $Session
		}
		else
		{
			$SessionParams.ComputerName = $Domain
			if ($Credential)
			{
				$SessionParams.Credential = $Credential
			}
		}

		$InvocationName = $MyInvocation.InvocationName
		Invoke-Command @SessionParams -ArgumentList $InvocationName -ScriptBlock {
			param ([string] $InvocationName)

			$Executable = Split-Path -Path $using:LiteralPath -Leaf
			$SigcheckDir = [System.Environment]::ExpandEnvironmentVariables($using:SigcheckLocation)
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
			$SigCheckFile = $null
			if (Test-Path -Path "$SigcheckDir\$SigcheckExecutable")
			{
				$SigCheckFile = "$SigcheckDir\$SigcheckExecutable"
			}
			else
			{
				# Check if sigcheck is in path
				Write-Debug -Message "[$InvocationName] Checking if sigcheck is in path"
				$Command = Get-Command -Name $SigcheckExecutable -CommandType Application -ErrorAction Ignore

				# Can be, not found or there are multiple matches
				if (($Command | Measure-Object).Count -eq 1)
				{
					$SigCheckFile = $Command.Name
					Write-Debug -Message "[$InvocationName] $SigcheckExecutable found in path"
				}
				else
				{
					# Using because ExpandEnvironmentVariables will return NULL if location doesn't exist
					Write-Warning -Message "[$InvocationName] $SigcheckExecutable was not found in the specified path '$using:SigcheckLocation', virus total scan will not be performed"
				}
			}

			if (![string]::IsNullOrEmpty($SigCheckFile))
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
				$Process.StartInfo.Arguments += " `"$using:LiteralPath`""
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
							Write-Debug -Message "[$InvocationName] Processing $SigCheckFile output: $StreamLine"

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
								# TODO: Write-LogFile, output is printed to console
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT status is", $Detection.Value

								$TotalDetections = [regex]::Match($Detection.Value, "\d+")
								if ($TotalDetections.Success)
								{
									if ([int32] $TotalDetections.Value -gt 0)
									{
										Write-Warning -Message "[$InvocationName] '$Executable' is infected with malware"
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
								Write-Verbose -Message "[$InvocationName] $Executable VT Link is $($Link.Value)"
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT link", $Link.Value
							}

							if ($Publisher.Success)
							{
								Write-Verbose -Message "[$InvocationName] $Executable Publisher is $($Publisher.Value)"
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "Publisher", $Publisher.Value
							}

							if ($Description.Success)
							{
								Write-Verbose -Message "[$InvocationName] $Executable Description is $($Description.Value)"
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "Description", $Description.Value
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
					$StatusWait = $Process.WaitForExit($using:TimeOut * 1000)

					if (!$StatusWait)
					{
						Write-Warning -Message "[$InvocationName] Process '$SigCheckFile' failed to exit, killing process"

						# Immediately stops the associated process, and optionally its child/descendent processes (true)
						$Process.Kill()
					}

					# The Close method causes the process to stop waiting for exit if it was waiting,
					# closes the process handle, and clears process-specific properties.
					# NOTE: Close does not close the standard output, input, and error readers and writers in
					# case they are being referenced externally
					Write-Debug -Message "[$InvocationName] Closing $SigcheckFile process"
					$Process.Close()

					$HeaderStack.Pop() | Out-Null
				}
				else
				{
					Write-Error -Category InvalidResult -TargetObject $Process -Message "Starting process '$SigCheckFile' failed"
				}

				return $FileIsMalware
			} # if sigcheckfile
		} # Invoke-Command
	}
}

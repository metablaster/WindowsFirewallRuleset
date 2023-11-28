
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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
Analyze file trough VirusTotal API

.DESCRIPTION
Test-VirusTotal performs malware analysis on file by using sysinternals sigcheck
program which in turn uses VirusTotal API to perform analysis.

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
If location to sigcheck executable is not found then no VirusTotal scan and report is done.

.PARAMETER SkipPositivies
Specify count of detections up to which VirusTotal detections will be considered false positives.
If the number of detection is greater than this value, the file being scanned is considered malware.
The default value is 0, meaning it must be clean of any detections.

.PARAMETER Timeout
Specify maximum wait time expressed in seconds for VirusTotal to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

.PARAMETER Force
If specified, sigcheck is downloaded if it's not found and is used without user prompt

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

.LINK
https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck

.LINK
https://support.virustotal.com/hc/en-us/articles/115002145529-Terms-of-Service

.LINK
https://support.virustotal.com/hc/en-us/articles/115002168385-Privacy-Policy
#>
function Test-VirusTotal
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain", SupportsShouldProcess = $true, ConfirmImpact = "Medium",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md")]
	[OutputType([bool], [void])]
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

		[Parameter()]
		[string] $SigcheckLocation,

		[Parameter()]
		[int32] $SkipPositivies = $DefaultSkipPositivies,

		[Parameter()]
		[ValidateRange(1, 650)]
		[int32] $TimeOut = 300,

		[Parameter()]
		[switch] $Force
	)

	if ($PSCmdlet.ShouldProcess($LiteralPath, "Run VirusTotal check"))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[hashtable] $SessionParams = @{}
		if ($PsCmdlet.ParameterSetName -eq "Session")
		{
			$Domain = $Session.ComputerName
			$SessionParams.Session = $Session
		}
		else
		{
			$Domain = Format-ComputerName $Domain

			# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
			if ($Domain -ne [System.Environment]::MachineName)
			{
				$SessionParams.ComputerName = $Domain
				if ($Credential)
				{
					$SessionParams.Credential = $Credential
				}
			}
		}

		# TODO: Use $PSBoundParameters?
		Invoke-Command @SessionParams -ArgumentList $MyInvocation.InvocationName, $SigcheckLocation, $TimeOut, $LiteralPath, $SkipPositivies, $Domain, $Force -ScriptBlock {
			[CmdletBinding()]
			param (
				[string] $InvocationName,
				[string] $SigcheckLocation,
				[int32] $TimeOut,
				[string] $LiteralPath,
				[int32] $SkipPositivies,
				[string] $Domain,
				# TODO: [switch] doesn't work "A positional parameter cannot be found that accepts argument 'False'"
				[bool] $Force
			)

			if ([System.Environment]::Is64BitOperatingSystem)
			{
				# Consider both, sigcheck.exe and sigcheck64.exe
				$SigcheckExecutable = "sigcheck*.exe"
			}
			else
			{
				$SigcheckExecutable = "sigcheck.exe"
			}

			# if SigcheckLocation is null ExpandEnvironmentVariables won't be null but ""
			$SigcheckDir = [System.Environment]::ExpandEnvironmentVariables($SigcheckLocation)

			# Otherwise Resolve-Path will error
			if (![string]::IsNullOrEmpty($SigcheckDir))
			{
				$SigcheckDir = Resolve-Path -Path $SigcheckDir -ErrorAction SilentlyContinue
			}

			# TODO: Prefer x64 bit executable on x64 system
			$SigCheckFile = $null

			# Check if path to sigcheck executable is valid
			# NOTE: sigcheck64a.exe is not a valid application for this OS platform
			if (![string]::IsNullOrEmpty($SigcheckDir) -and (Test-Path -Path "$SigcheckDir\$SigcheckExecutable" -Exclude "*a.exe" -PathType Leaf))
			{
				# Get full path to single executable
				$Command = Resolve-Path -Path "$SigcheckDir\$SigcheckExecutable" |
				Get-Command -CommandType Application | Where-Object {
					$_.Name -notmatch "a.exe$"
				}

				$SigCheckFile = $Command.Source | Select-Object -Last 1
				Write-Debug -Message "[$InvocationName] $SigCheckFile found in '$SigcheckDir'"
			}
			else
			{
				# If variable was set to null in ProjectSettings.ps1 by user restore it to default
				if ([string]::IsNullOrEmpty($SigcheckPath))
				{
					Set-Variable -Name SigcheckPath -Scope Global -Value "C:\tools"
				}

				# Check if sigcheck is in PATH
				Write-Debug -Message "[$InvocationName] Checking if sigcheck is in PATH"
				$Command = Get-Command -Name $SigcheckExecutable -CommandType Application -ErrorAction Ignore |
				Where-Object {
					$_.Name -notmatch "a.exe$"
				}

				if ([System.Environment]::Is64BitOperatingSystem)
				{
					$SigcheckExecutable = $SigcheckExecutable -replace "\*", "64"
				}

				# Can be, not found or there are multiple matches
				if (($Command | Measure-Object).Count -ne 0)
				{
					$SigCheckFile = $Command.Name | Select-Object -Last 1
					Write-Debug -Message "[$InvocationName] $SigCheckFile found in PATH"
				}
				# Offer to user to download it
				elseif ($Force -or $PSCmdlet.ShouldContinue("Download $SigcheckExecutable from sysinternals.com to '$SigcheckPath' directory", "$SigcheckExecutable executable was not found on '$Domain' computer"))
				{
					if (Test-Path -Path User:\)
					{
						# Drive created by session configuration
						$TempFolder = "User:\"
					}
					else
					{
						$TempFolder = [System.Environment]::ExpandEnvironmentVariables("%LocalAppData%\temp")
					}

					if ([System.Environment]::Is64BitOperatingSystem)
					{
						$SigCheckFile = "$SigcheckPath\Sigcheck64.exe"
					}
					else
					{
						$SigCheckFile = "$SigcheckPath\Sigcheck.exe"
					}

					try
					{
						$PreviousProgressPreference = $ProgressPreference
						if ($PSVersionTable.PSEdition -eq "Core")
						{
							# Required by Invoke-WebRequest within Invoke-Command,
							# .NET 7, therefore not working nor needed in Desktop edition
							Add-Type -AssemblyName "System.Net.Quic"
						}

						# This rule is disabled by default, however it's needed here to make
						# Invoke-WebRequest work within Invoke-Command scriptblock
						$wsmprovhostRule = Get-NetFirewallRule -DisplayName "PowerShell WinRM" -PolicyStore $Domain -ErrorAction Ignore |
						Where-Object {
							$_.Direction -eq "Outbound"
						} | Enable-NetFirewallRule -PassThru

						if ($wsmprovhostRule)
						{
							Write-Debug "[$InvocationName] Sleeping 2 seconds on '$Domain' computer"

							# Rule may not be instantly effective
							Start-Sleep -Seconds 2
						}
						else
						{
							Write-Debug "[$InvocationName] wsmprovhostRule not found on '$Domain' computer"
						}

						Write-Information -Tags $InvocationName -MessageData "INFO: Downloading Sigcheck.zip to '$TempFolder'"

						# Get rid of flushy download progress
						$ProgressPreference = "SilentlyContinue"
						# This will override Sigcheck.zip if it exists
						Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sigcheck.zip" -OutFile "$TempFolder\Sigcheck.zip" -ErrorAction Stop

						Write-Information -Tags $InvocationName -MessageData "INFO: Expanding Sigcheck.zip to '$SigcheckPath'"
						# -Force to override existing files such as Eula.txt, -DestinationPath is created
						Expand-Archive -Path "$TempFolder\Sigcheck.zip" -DestinationPath $SigcheckPath -Force -ErrorAction Stop
						# Ignore removing zip, if it's used by AV to scan it then this may fail
						Remove-Item -Path "$TempFolder\Sigcheck.zip" -ErrorAction Ignore

						if (!(Test-Path -Path $SigCheckFile -PathType Leaf))
						{
							throw "Downloading and expanding Sigcheck.zip succeeded but $SigcheckExecutable not found"
						}
					}
					catch
					{
						$SigCheckFile = $null
						Write-Warning -Message "[$InvocationName] Failed to download sigcheck because '$($_.Exception.Message)'"
					}
					finally
					{
						$ProgressPreference = $PreviousProgressPreference
						if ($wsmprovhostRule)
						{
							# This rule should not be enabled since it allows internet access
							Disable-NetFirewallRule -InputObject $wsmprovhostRule
						}
					}
				}
				else
				{
					$SigCheckFile = $null
					# This is to stop prompting to download sigcheck
					Set-Variable -Name SkipVirusTotalCheck -Scope Global -Value $true
					Write-Warning -Message "[$InvocationName] $SigcheckExecutable was not found in '$SigcheckPath' or in PATH, VirusTotal scan will not be performed"
				}
			}

			if (![string]::IsNullOrEmpty($SigCheckFile))
			{
				Write-Verbose -Message "[$InvocationName] Using sigcheck file '$SigCheckFile'"

				# The path to executable needs to be expanded for sigcheck.exe,
				# otherwise it results with "No matching files were found"
				$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
				$Executable = Split-Path -Path $ExpandedPath -Leaf

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
				# -vt accept VirusTotal license
				$Process.StartInfo.Arguments = "-vt -accepteula -nobanner"

				# Open report in web browser and upload files never scanned by VirusTotal
				$Process.StartInfo.Arguments += " -vrs"

				# File which is to be scanned
				$Process.StartInfo.Arguments += " `"$ExpandedPath`""
				Write-Debug -Message "[$InvocationName] Sigcheck arguments are $($Process.StartInfo.Arguments)"

				$FileIsMalware = $false
				if ($Process.Start())
				{
					$HeaderStack.Push("VirusTotal status")

					while (!$Process.StandardOutput.EndOfStream)
					{
						# Reads a line of characters from the current stream and returns the data as [string]
						# Methods such as Read, ReadLine, and ReadToEnd perform synchronous read operations
						# on the output stream of the process
						$StreamLine = $Process.StandardOutput.ReadLine()

						if (![string]::IsNullOrEmpty($StreamLine))
						{
							Write-Debug -Message "[$InvocationName] Processing $SigCheckFile output '$StreamLine'"

							# NOTE: Only one of these can be success per line, therefore do not error for failure
							# TODO: This is likely why we see "InvalidOperation: You cannot call a method on a null-valued expression" soon after if($...)
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
								Write-Information -Tags $InvocationName -MessageData "INFO: VirusTotal report for '$Executable' is '$($Detection.Value)'"
								# TODO: Write-LogFile, output is printed to console
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT status is", $Detection.Value

								$TotalDetections = [regex]::Match($Detection.Value, "\d+")
								if ($TotalDetections.Success)
								{
									if ([int32] $TotalDetections.Value -gt $SkipPositivies)
									{
										$FileIsMalware = $true
										# TODO: Write-ColorMessage does not work here, should be red text
										Write-Warning -Message "[$InvocationName] '$Executable' was reported as malware"
									}
								}
								# May happen if ie there is no firewall rule for sigcheck.exe, we ignore
								# this as an error because testing windows services would spam the console with errors
								elseif ($Detection.Value -notlike "*connection with the server could not be established*")
								{
									Write-Error -Category ParserError -TargetObject $Detection `
										-Message "Failed to match total count of infections for '$Executable'"
								}
							}
							elseif ($Link.Success)
							{
								Write-Verbose -Message "[$InvocationName] $Executable VT Link is $($Link.Value)"
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "VT link", $Link.Value
							}
							elseif ($Publisher.Success)
							{
								Write-Verbose -Message "[$InvocationName] $Executable Publisher is $($Publisher.Value)"
								# Write-LogFile -LogName "VirusTotal" -Tags "VirusTotal" -Message "Publisher", $Publisher.Value
							}
							elseif ($Description.Success)
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
					$StatusWait = $Process.WaitForExit($TimeOut * 1000)

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

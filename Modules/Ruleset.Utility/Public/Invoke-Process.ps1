
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Run process, format and redirect captured process output

.DESCRIPTION
Run process with or without arguments, set process timeout, capture and format output.
If target process produces an error, the error message is formatted and shown in addition
to standard output if any.

.PARAMETER Path
Executable name or path to application which to start.
Wildcard characters and relative paths are supported.

.PARAMETER ArgumentList
A collection of command-line arguments to use when starting the application

.PARAMETER NoNewWindow
Whether to use the operating system shell to start the process

.PARAMETER Timeout
The amount of time, in milliseconds, to wait for the associated process to exit.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 10000 (10 seconds).

.PARAMETER Async
If specified, reading process output is asynchronous.
This functionality is experimental because current thread will block until timeout.

.PARAMETER Raw
If specified, process output is returned as string.
By default process output is formatted and redirected to information and error stream.

.PARAMETER Credential
Optionally specify Windows user name and password to use when starting the process

.PARAMETER LoadUserProfile
Specify whether the Windows user profile is to be loaded from the registry
Because loading the profile can be time-consuming, it is best to use this value only if you must
access the information in the HKEY_CURRENT_USER registry key.

.PARAMETER WorkingDirectory
Set the working directory for the process to be started.
The WorkingDirectory property must be set if Credential (UserName and Password) is provided.

.EXAMPLE
PS> Invoke-Process git.exe -ArgumentList "status" -NoNewWindow -Wait 3000

.EXAMPLE
PS> Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Async -Timeout 3000

.INPUTS
None. You cannot pipe objects to Invoke-Process

.OUTPUTS
[string]
[System.Threading.CancellationTokenSource]
[void]

.NOTES
TODO: Because of uncertain output this function needs a lot of improvements and a lot more test cases
to handle variable varieties of process outputs.
TODO: Domain parameter needed to invoke process remotely
TODO: Process may need to read input
TODO: NoNewWindow should be default
TODO: To implement LiteralPath parameter, it must be done with parameter sets.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo
#>
function Invoke-Process
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md")]
	[OutputType([string], [System.Threading.CancellationTokenSource], [void])]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[Alias("FilePath")]
		[string] $Path,

		[Parameter(Position = 1)]
		[string] $ArgumentList,

		[Parameter()]
		[switch] $NoNewWindow,

		[Parameter()]
		[ValidateRange(-1, [int32]::MaxValue)]
		[int32] $Timeout = 10000,

		[Parameter()]
		[switch] $Async,

		[Parameter()]
		[switch] $Raw,

		[Parameter(Mandatory = $true, ParameterSetName = "Credential")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Credential")]
		[switch] $LoadUserProfile,

		[Parameter()]
		[Parameter(Mandatory = $true, ParameterSetName = "Credential")]
		[string] $WorkingDirectory
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$CommandName = Split-Path -Path $Path -Leaf
	# [System.Management.Automation.ApplicationInfo]
	$Command = Get-Command -Name $Path -CommandType Application -ErrorAction Ignore

	# Can be, not found or there are multiple matches
	if (($Command | Measure-Object).Count -ne 1)
	{
		[System.IO.FileInfo] $FilePath = Resolve-FileSystemPath $Path -File

		if ($FilePath -and $FilePath.Exists)
		{
			$Command = Get-Command -Name $FilePath.FullName -CommandType Application -ErrorAction Ignore

			if (!$Command)
			{
				Write-Error -Category ObjectNotFound -TargetObject $FilePath.FullName -Message "Application was not found: $($FilePath.FullName)"
				return
			}
		}
		else
		{
			Write-Error -Category ObjectNotFound -TargetObject $CommandName -Message "Application '$CommandName' was not found"
			return
		}
	}

	$CommandName = $Command.Name
	$Process = New-Object System.Diagnostics.Process

	# The application or document to start
	$Process.StartInfo.FileName = $Command.Path

	# Whether the textual output of an application is written to the StandardOutput stream
	$Process.StartInfo.RedirectStandardOutput = $true

	# Whether the error output of an application is written to the StandardError stream
	$Process.StartInfo.RedirectStandardError = $true

	# Whether to start the process in a new window
	$Process.StartInfo.CreateNoWindow = $NoNewWindow

	# Whether to use the operating system shell to start the process
	# If the UserName property is not null or an empty string, the UseShellExecute property must be false
	$Process.StartInfo.UseShellExecute = $false

	if (![string]::IsNullOrEmpty($WorkingDirectory))
	{
		# When UseShellExecute property is false, sets the working directory for the process to be started.
		# When UseShellExecute is true, sets the directory that contains the process to be started.
		$Process.StartInfo.WorkingDirectory = $WorkingDirectory
	}

	if ($PSCmdlet.ParameterSetName -eq "Credential")
	{
		# The user name to use when starting the process
		$Process.StartInfo.UserName = $Credential.UserName

		# The user password to use when starting the process
		$Process.StartInfo.Password = $Credential.Password

		if ($LoadUserProfile)
		{
			$Process.StartInfo.LoadUserProfile = $LoadUserProfile
		}
	}

	if ($ArgumentList)
	{
		# A collection of command-line arguments to use when starting the application
		$Process.StartInfo.Arguments = $ArgumentList
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] $CommandName argument list is '$ArgumentList'"
	}

	$InvocationName = $MyInvocation.InvocationName

	if ($Async)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Hooking up event handlers for asynchronous operations"

		if ($Raw)
		{
			[scriptblock] $OutputDataReceived = {
				if (![string]::IsNullOrEmpty($EventArgs.Data))
				{
					Write-Debug -Message "[$InvocationName & OutputDataReceived] OutputDataReceived: $($EventArgs.Data)"
					$Event.MessageData.AppendLine($EventArgs.Data)
				}
			}

			[scriptblock] $ErrorDataReceived = {
				if (![string]::IsNullOrEmpty($EventArgs.Data))
				{
					Write-Debug -Message "[$InvocationName & ErrorDataReceived] ErrorDataReceived: $($EventArgs.Data)"
					$Event.MessageData.AppendLine($EventArgs.Data)
				}
			}
		}
		else
		{
			# Adding event handler for StandardOutput
			[scriptblock] $OutputDataReceived = {
				# TODO: Unable to surpress with SuppressMessageAttribute, parameter is required otherwise event will not work
				[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
					"PSReviewUnusedParameter", "SendingProcess", Justification = "Needed for the event to work")]
				param (
					[Parameter(Mandatory = $true)]
					[object] $SendingProcess,

					[Parameter(Mandatory = $true)]
					[System.Diagnostics.DataReceivedEventArgs] $OutLine
				)

				if (![string]::IsNullOrEmpty($OutLine.Data))
				{
					# NOTE: Explicit -Debug or INFA is needed inside event
					Write-Debug -Message "[$InvocationName & OutputDataReceived] OutputDataReceived: $($OutLine.Data)"
					Write-Information -Tags $InvocationName -MessageData "INFO: $($OutLine.Data)" -INFA "Continue"
				}
			}

			# Adding event handler for StandardError
			[scriptblock] $ErrorDataReceived = {
				# TODO: Unable to surpress with SuppressMessageAttribute, parameter is required otherwise event will not work
				[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
					"PSReviewUnusedParameter", "SendingProcess", Justification = "Needed for the event to work")]
				param (
					[Parameter(Mandatory = $true)]
					[object] $SendingProcess,

					[Parameter(Mandatory = $true)]
					[System.Diagnostics.DataReceivedEventArgs] $OutLine
				)

				if (![string]::IsNullOrEmpty($OutLine.Data))
				{
					# NOTE: Explicit -Debug is needed inside event
					Write-Debug -Message "[$InvocationName & ErrorDataReceived] ErrorDataReceived: $($OutLine.Data)"
					Write-Error -Category FromStdErr -TargetObject $Process -MessageData $OutLine.Data
				}
			}
		}

		$OutputEventParams = @{
			InputObject = $Process
			Action = $OutputDataReceived
			EventName = "OutputDataReceived"
		}

		$ErrorEventParams = @{
			InputObject = $Process
			Action = $ErrorDataReceived
			EventName = "ErrorDataReceived"
		}

		if ($Raw)
		{
			# Create string builders to store output
			$OutputBuilder = New-Object -TypeName System.Text.StringBuilder
			$ErrorBuilder = New-Object -TypeName System.Text.StringBuilder

			$OutputEventParams.Add("MessageData", $OutputBuilder)
			$ErrorEventParams.Add("MessageData", $ErrorBuilder)
		}

		# OutputDataReceived: Occurs each time an application writes a line to its redirected StandardOutput stream
		$OutputEvent = Register-ObjectEvent @OutputEventParams

		# ErrorDataReceived: Occurs when an application writes to its redirected StandardError stream
		$ErrorEvent = Register-ObjectEvent @ErrorEventParams

		[scriptblock] $UnregisterEvents = {
			Write-Debug -Message "[$InvocationName & UnregisterEvents] Unregistering asynchronous operations"

			try
			{
				# End the asynchronous read operation.
				# Cancels the asynchronous read operation on the redirected StandardOutput stream of an application
				# https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process.canceloutputread?view=net-5.0
				$Process.CancelOutputRead()
				$Process.CancelErrorRead()
			}
			catch [System.InvalidOperationException]
			{
				# The StandardOutput stream is not enabled for asynchronous read operations
				Write-Error -Category InvalidOperation -TargetObject $Process -Message $_.Exception.Message
			}

			# Un-registering events to retrieve process output.
			Unregister-Event -SourceIdentifier $OutputEvent.Name
			Unregister-Event -SourceIdentifier $ErrorEvent.Name
		}
	}

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting process '$CommandName'"

		# true if a process resource is started; false if no new process resource is started
		if (!$Process.Start())
		{
			Write-Error -Category InvalidResult -TargetObject $Process -Message "Starting process '$CommandName' failed"
			if ($Async) { & $UnregisterEvents }
			return
		}
	}
	catch [System.ComponentModel.Win32Exception]
	{
		Write-Error -Category InvalidOperation -TargetObject $Process `
			-Message "There was an error in starting process '$CommandName'"
		if ($Async) { & $UnregisterEvents }
		return
	}
	catch [System.InvalidOperationException]
	{
		Write-Error -Category InvalidOperation -TargetObject $Process -Message $_.Exception.Message
		if ($Async) { & $UnregisterEvents }
		return
	}
	catch
	{
		Write-Error -Category NotSpecified -TargetObject $Process -Message $_.Exception.Message
		if ($Async) { & $UnregisterEvents }
		return
	}

	if ($Async)
	{
		if (!$Raw)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting asynchronous read"
		}

		try
		{
			# BeginOutputReadLine starts asynchronous read operations on the StandardOutput stream.
			# This method enables a designated event handler for the stream output and immediately returns to the caller
			# https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process.standardoutput?view=net-5.0
			$Process.BeginOutputReadLine()
			$Process.BeginErrorReadLine()
		}
		catch # [System.InvalidOperationException]
		{
			Write-Error -Category InvalidOperation -TargetObject $Process -Message $_.Exception.Message

			$Async = $false
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Fallback to synchronous mode"
		}

		# Define the cancellation token
		# https://docs.microsoft.com/en-us/dotnet/api/system.threading.cancellationtoken?view=net-5.0
		$CancelSource = [System.Threading.CancellationTokenSource]::new($Timeout)
		$CancelToken = $CancelSource.Token #[System.Threading.CancellationToken]::new($true)

		# WaitForExitAsync (System.Threading.CancellationToken cancellationToken = default)
		# https://docs.microsoft.com/en-us/dotnet/api/system.threading.tasks.task?view=net-5.0
		[System.Threading.Tasks.Task] $Task = $Process.WaitForExitAsync($CancelToken)

		Write-Output $CancelSource
	}

	try
	{
		if ($Timeout -ge 0)
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Waiting up to $($Timeout / 1000) seconds for process '$CommandName' to finish..."

			if ($Async)
			{
				# true if the Task completed execution within the allotted time, otherwise false
				$StatusWait = $Task.Wait($Timeout, $CancelToken)
			}
			else
			{
				# true if the associated process has exited, otherwise false
				$StatusWait = $Process.WaitForExit($Timeout)
			}

			if (!$StatusWait)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Process '$CommandName' is taking too long, aborting..."
			}
		}
		else
		{
			$StatusWait = $true
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Waiting infinitely for process '$CommandName' to finish..."

			if ($Async)
			{
				$Task.Wait($CancelToken)
			}
			else
			{
				$Process.WaitForExit()
			}
		}
	}
	catch
	{
		$StatusWait = $false

		if ($Async -and $CancelSource.IsCancellationRequested)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] The task has been canceled"
		}
		else
		{
			Write-Error -ErrorRecord $_
		}
	}

	if (!$StatusWait)
	{
		if ($Async) { & $UnregisterEvents }

		try
		{
			# Immediately stops the associated process, and optionally its child/descendent processes (true)
			$Process.Kill($true)
		}
		catch [System.NotSupportedException]
		{
			Write-Error -Category NotEnabled -TargetObject $Process `
				-Message "Killing a process is available only for processes running on the local computer"
		}
		catch [System.ComponentModel.Win32Exception]
		{
			Write-Error -Category InvalidOperation -TargetObject $Process `
				-Message "The process '$CommandName' could not be terminated"
		}
		catch # [System.InvalidOperationException]
		{
			# TODO: Will be triggered in Windows PowerShell but not in Core (run unit test to repro)
			Write-Error -Category NotSpecified -TargetObject $Process `
				-Message "There is no process associated with this Process object"
		}

		return
	}

	if ($Async)
	{
		& $UnregisterEvents

		if ($Raw)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting raw asynchronous read"

			$StandardOutput = $OutputBuilder.ToString()
			if (![string]::IsNullOrEmpty($StandardOutput))
			{
				Write-Output $StandardOutput
			}

			$StandardError = $ErrorBuilder.ToString()
			if (![string]::IsNullOrEmpty($StandardError))
			{
				Write-Output $StandardError
			}
		}
	}
	else
	{
		if ($Raw)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting raw synchronous read"

			# Reads all characters from the current position to the end of the stream (returns [string])
			$StandardOutput = $Process.StandardOutput.ReadToEnd()
			if (![string]::IsNullOrEmpty($StandardOutput))
			{
				Write-Output $StandardOutput
			}

			$StandardError = $Process.StandardError.ReadToEnd()
			if (![string]::IsNullOrEmpty($StandardError))
			{
				Write-Output $StandardError
			}
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting synchronous read"

			# true if the current stream position is at the end of the stream
			while (!$Process.StandardOutput.EndOfStream)
			{
				# Reads a line of characters from the current stream and returns the data as [string]
				# Methods such as Read, ReadLine, and ReadToEnd perform synchronous read operations
				# on the output stream of the process
				$StreamLine = $Process.StandardOutput.ReadLine()

				if (![string]::IsNullOrEmpty($StreamLine))
				{
					Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: $StreamLine"
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Sleeping..."
				Start-Sleep -Milliseconds 300
			}

			while (!$Process.StandardError.EndOfStream)
			{
				$StreamLine = $Process.StandardError.ReadLine()

				if (![string]::IsNullOrEmpty($StreamLine))
				{
					Write-Error -Category FromStdErr -TargetObject $Process -Message $StreamLine
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Sleeping..."
				Start-Sleep -Milliseconds 300
			}
		}
	}

	# The Close method causes the process to stop waiting for exit if it was waiting,
	# closes the process handle, and clears process-specific properties.
	# NOTE: Close does not close the standard output, input, and error readers and writers in
	# case they are being referenced externally
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Closing process '$CommandName'"
	$Process.Close()
}

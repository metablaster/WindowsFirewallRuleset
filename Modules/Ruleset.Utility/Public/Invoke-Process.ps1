
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
Run process and capture output

.DESCRIPTION
Run process with or without arguments, set wait time and capture output.
If the target process results in an error, error message is formatted and shown in addition
to standard output if any.

.PARAMETER Path
Executable name or path to application to which to start.
Wildcard characters and relative paths are supported.

.PARAMETER ArgumentList
A collection of command-line arguments to use when starting the application

.PARAMETER NoNewWindow
Whether to use the operating system shell to start the process

.PARAMETER Wait
The amount of time, in milliseconds, to wait for the associated process to exit.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 10 seconds.

.PARAMETER Format
If specified, each line of application output is redirected to new information stream

.EXAMPLE
PS> Invoke-Process git.exe -ArgumentList "status" -NoNewWindow -Wait 3000

.INPUTS
None. You cannot pipe objects to Invoke-Process

.OUTPUTS
[string] If the "Format" parameter is not specified

.NOTES
TODO: Because of uncertain output this function needs a lot of improvements and a lot more test cases
to handle variable varieties of process outputs.
#>
function Invoke-Process
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md")]
	[OutputType([string])]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[Alias("Application", "FilePath")]
		[string] $Path,

		[Parameter()]
		[string] $ArgumentList,

		[Parameter()]
		[switch] $NoNewWindow,

		[Parameter()]
		[int32] $Wait = 10000,

		[Parameter()]
		[switch] $Format
	)

	$CommandName = Split-Path -Path $Path -Leaf

	# TODO: May return unexpected application if multiple matches exist
	# [System.Management.Automation.ApplicationInfo]
	$Command = Get-Command -Name $CommandName -CommandType Application -ErrorAction Ignore

	if (!$Command)
	{
		[System.IO.FileInfo] $FilePath = Resolve-FileSystem $Path -File

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
	$Process.StartInfo.UseShellExecute = $false

	if ($ArgumentList)
	{
		# A collection of command-line arguments to use when starting the application
		$Process.StartInfo.Arguments = $ArgumentList
	}

	# TODO: Not working as expected
	# Creating string builders to store stdout.
	# $StdOutBuilder = New-Object -TypeName System.Text.StringBuilder

	# # Adding event handler for stdout.
	# $ScripBlock = {
	# 	if (![string]::IsNullOrEmpty($EventArgs.Data))
	# 	{
	# 		$Event.MessageData.AppendLine($EventArgs.Data)
	# 	}
	# }

	# $StdOutEvent = Register-ObjectEvent -InputObject $Process `
	# 	-Action $ScripBlock -EventName "OutputDataReceived" `
	# 	-MessageData $StdOutBuilder

	try
	{
		Write-Verbose -Message "Starting process '$CommandName'"

		# true if a process resource is started; false if no new process resource is started
		if (!$Process.Start())
		{
			Write-Error -Category InvalidResult -TargetObject $Process -Message "Starting process '$CommandName' failed"
			return
		}
	}
	catch
	{
		Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
	}

	# NOTE: Part of commented code above
	# $Process.BeginOutputReadLine()

	if ($Wait -ge 0)
	{
		Write-Information -Tags "User" -MessageData "Waiting up to $($Wait / 1000) seconds for Process '$CommandName' to finish ..."

		# true if the associated process has exited; otherwise, false
		if (!$Process.WaitForExit($Wait))
		{
			Write-Warning -Message "Process '$CommandName' is taking too long, aborting ..."
			$Process.Kill()
			return
		}
	}
	else
	{
		Write-Information -Tags "User" -MessageData "Waiting infinitely for Process '$CommandName' to finish ..."

		$Process.WaitForExit()

		# NOTE: Part of commented code above
		# Un-registering events to retrieve process output.
		# Unregister-Event -SourceIdentifier $StdOutEvent.Name

		# $StdOutBuilder.ToString()
	}

	if ($Format)
	{
		Write-Verbose -Message "Formatting process output"

		# true if the current stream position is at the end of the stream
		while (!$Process.StandardOutput.EndOfStream)
		{
			# Reads a line of characters from the current stream and returns the data as [string]
			$StreamLine = $Process.StandardOutput.ReadLine()

			if (![string]::IsNullOrEmpty($StreamLine))
			{
				Write-Information -Tags "User" -MessageData "INFO: $StreamLine"
			}
		}
	}
	else
	{
		Write-Verbose -Message "Getting process output"
		$Process.StandardOutput.ReadToEnd()
	}

	# Reads all characters from the current position to the end of the stream (returns [string])
	$StandardError = $Process.StandardError.ReadToEnd()

	if (![string]::IsNullOrEmpty($StandardError))
	{
		Write-Error -Category FromStdErr -TargetObject $Process -Message $StandardError
	}
}

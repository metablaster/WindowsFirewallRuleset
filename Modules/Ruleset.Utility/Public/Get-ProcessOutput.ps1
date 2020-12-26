
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

.PARAMETER Application
Executable name.
Should be in PATH environment variable to resolve.

.PARAMETER Path
The path to application or document to start.
Wildcard characters and relative paths are supported.

.PARAMETER ArgumentList
A collection of command-line arguments to use when starting the application

.PARAMETER NoNewWindow
Whether to use the operating system shell to start the process

.PARAMETER Wait
Number of milliseconds to wait for the associated process to exit
Default is 0, which means wait indefinitely

.PARAMETER Format
If specified, formats standard output into INFO messages

.EXAMPLE
PS> Get-ProcessOutput -Path "git.exe" -ArgumentList "status" -NoNewWindow -Wait 3000

.INPUTS
None. You cannot pipe objects to Get-ProcessOutput

.OUTPUTS
[string] If the "Format" parameter is not specified

.NOTES
TODO: Function needs improvements and more test cases
TODO: consider renaming to Format-ProcessOutput
#>
function Get-ProcessOutput
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Program",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-ProcessOutput.md")]
	[OutputType([string])]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Program")]
		[string] $Application,

		[Parameter(Mandatory = $true, ParameterSetName = "Path")]
		[SupportsWildcards()]
		[System.IO.FileInfo] $Path,

		[Parameter()]
		[string] $ArgumentList,

		[Parameter()]
		[switch] $NoNewWindow,

		[Parameter()]
		[uint32] $Wait = 0,

		[Parameter()]
		[switch] $Format
	)

	if ($Path)
	{
		[System.IO.FileInfo] $FilePath = Resolve-FileSystem $Path -File
		if (!($FilePath -and $FilePath.Exists))
		{
			return
		}
	}
	else
	{
		[System.Management.Automation.ApplicationInfo] $Command = Get-Command -Name $Application -CommandType Application -ErrorAction SilentlyContinue

		if (!$Command)
		{
			Write-Error -Category ObjectNotFound -TargetObject $Application -Message "The application '$Application' was not found"
			return
		}

		[System.IO.FileInfo] $FilePath = $Command.Source
	}

	$Process = New-Object System.Diagnostics.Process
	# The application or document to start
	$Process.StartInfo.FileName = $FilePath
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

	if (!$Process.Start())
	{
		Write-Warning -Message "Start process '$($Process.ProcessName)' failed"
		return
	}

	# NOTE: Part of commented code above
	# $Process.BeginOutputReadLine()

	if ($Wait -gt 0)
	{
		# true if the associated process has exited; otherwise, false
		$Status = $Process.WaitForExit([int32] $Wait)

		if (!$Status)
		{
			Write-Warning -Message "Process '$($Process.ProcessName)' is taking too long, aborting..."
			$Process.Kill()
			return
		}
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Waiting for Process '$($Process.ProcessName)' to finish..."

		$Process.WaitForExit()

		# NOTE: Part of commented code above
		# Un-registering events to retrieve process output.
		# Unregister-Event -SourceIdentifier $StdOutEvent.Name

		# $StdOutBuilder.ToString()
	}

	if ($Format)
	{
		# Reads a line of characters from the current stream and returns the data as a string.
		while ($null -ne ($StreamLine = $Process.StandardOutput.ReadLine()))
		{
			if ($StreamLine)
			{
				Write-Information -Tags "User" -MessageData "INFO: $StreamLine"
			}
		}
	}
	else
	{
		$Process.StandardOutput.ReadToEnd()
	}

	# Reads all characters from the current position to the end of the stream (returns [string])
	$StandardError = $Process.StandardError.ReadToEnd()

	if ($StandardError)
	{
		Write-Error -Category FromStdErr -Message $StandardError -TargetObject $Process
	}
}

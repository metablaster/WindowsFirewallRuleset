
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

using namespace System.Management.Automation

<#
.SYNOPSIS
Write a message or hash table to log file

.DESCRIPTION
Unlike Update-Log function which automatically picks up and logs Write-* streams,
the purpose of this function is to write logs manually.

Each script that uses Write-LogFile should first push a new header to "HeaderStack" variable,
this header will then appear in newly created logs that describes this log.

Before the script exits you should pop header from HeaderStack.

To write new log to different log or location within same script, the HeaderStack should be pushed
a new header, and popped before writing to previous log.

.PARAMETER Message
One or more messages from which to construct "InformationRecord" and append to log file

.PARAMETER Hash
Hash table or dictionary which to write to log file

.PARAMETER Path
Destination directory

.PARAMETER Tags
One or more optional message tags

.PARAMETER LogName
File label that is added to current date for resulting file name

.PARAMETER Raw
If specified, the message is written directly to log file without any formatting,
by default InformationRecord object is created from the message and written to log file.

.PARAMETER Overwrite
If specified, the log file is overwritten if it exists.

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message1", "Sample message 2"
PS> $HeaderStack.Pop() | Out-Null

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> [hashtable] $HashResult = Get-SomeHashTable
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Hash $HashResult
PS> $HeaderStack.Pop() | Out-Null

Will write entire $HashResult to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message"
PS> $HeaderStack.Push("Another Header")
PS> Write-LogFile -Path "C:\logs\next" -LogName "Admin" -Tags "NewTag" -Message "Another message"
PS> $HeaderStack.Pop() | Out-Null
PS> $HeaderStack.Pop() | Out-Null

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"
Will write "Another message" InformationRecord to log C:\logs\next\Admin_15.12.20.log with a header set to "Another Header"

.EXAMPLE
PS> $HeaderStack.Push("Raw message overwrite")
PS> Write-LogFile -Message "Raw message overwrite" -LogName "MyRawLog" -Path "C:\logs" -Raw -Overwrite

Will write raw message and overwrite existing log file if it exists.

.INPUTS
None. You cannot pipe objects to Write-LogFile

.OUTPUTS
None. Write-LogFile does not generate any output

.NOTES
Maybe there should be stack of labels and/or tags, but too early to see if this makes sense
#>
function Write-LogFile
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Logging/Help/en-US/Write-LogFile.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = "Message")]
		[string[]] $Message,

		[Parameter(Mandatory = $true, ParameterSetName = "Hash")]
		$Hash,

		[Parameter()]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path = $LogsFolder,

		[Parameter(ParameterSetName = "Message")]
		[string[]] $Tags = "Administrator",

		[Parameter()]
		[string] $LogName = "Admin",

		[Parameter(ParameterSetName = "Message")]
		[switch] $Raw,

		[Parameter()]
		[switch] $Overwrite
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# If Peek() fails you have called Pop() more times than Push()
	$LogFile = Initialize-Log $Path -LogName $LogName -Header $HeaderStack.Peek() -Overwrite:$Overwrite

	if ($LogFile)
	{
		if ($Message)
		{
			if ($Raw)
			{
				$Message | Out-File -Append -FilePath $LogFile -Encoding $DefaultEncoding
			}
			else
			{
				$Caller = (Get-PSCallStack)[1].ScriptName
				[InformationRecord[]] $AllRecords = @()

				foreach ($msg in $Message)
				{
					Write-Information -MessageData $msg -IV LocalBuffer -INFA "SilentlyContinue"

					$Record = [InformationRecord]::new($LocalBuffer, $Caller)

					$Record.Tags.AddRange($Tags)
					$AllRecords += $Record
				}

				$AllRecords | Select-Object * | Out-File -Append -FilePath $LogFile -Encoding $DefaultEncoding
			}
		}
		else
		{
			$Hash | Out-File -Append -FilePath $LogFile -Encoding $DefaultEncoding
		}
	}
}

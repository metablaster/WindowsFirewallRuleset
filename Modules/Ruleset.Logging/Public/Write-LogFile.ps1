
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

using namespace System.Management.Automation

<#
.SYNOPSIS
Write to log file

.DESCRIPTION
Unlike Update-Log function which automatically picks up and logs Write-* streams,
the purpose of this function is to write logs manually.

Each script that uses Write-LogFile should first push a new header to "HeaderStack" variable,
this header will then appear in newly created logs that describes this log.

Before the script exits you should pop header from HeaderStack.

To write new log to different log or location within same script, the HeaderStack should be pushed
a new header, and popped before writing to previous log.

.PARAMETER Message
Message from which to construct "InformationRecord" and append to log file

.PARAMETER Hash
Hash table or dictionary which to write to log file

.PARAMETER Tags
One or more optional message tags

.PARAMETER Path
Destination directory

.PARAMETER LogFile
File label that is added to current date for resulting file name

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message"
PS> $HeaderStack.Pop() | Out-Null

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> [hashtable] $HashResult = Get-SomeHashTable
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Hash $HashResult
PS> $HeaderStack.Pop() | Out-Null

Will write entry $HashResult to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

.EXAMPLE
PS> $HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message"
PS> $HeaderStack.Push("Another Header")
PS> Write-LogFile -Path "C:\logs\next" -LogName "Admin" -Tags "NewTag" -Message "Another message"
PS> $HeaderStack.Pop() | Out-Null
PS> $HeaderStack.Pop() | Out-Null

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"
Will write "Another message" InformationRecord to log C:\logs\next\Admin_15.12.20.log with a header set to "Another Header"

.INPUTS
None. You cannot pipe objects to Write-LogFile

.OUTPUTS
None. Write-LogFile does not generate any output

.NOTES
Maybe there should be stack of labels and/or tags, but too early to see if this makes sense
#>
function Write-LogFile
{
	[OutputType([void])]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Logging/Help/en-US/Write-LogFile.md")]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = "Message")]
		[string] $Message,

		[Parameter(Mandatory = $true, ParameterSetName = "Hash")]
		$Hash,

		[Parameter()]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path = $LogsFolder,

		[Parameter(ParameterSetName = "Message")]
		[string[]] $Tags = "Administrator",

		[Parameter()]
		[string] $LogName = "Admin"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# If Peek() fails you have called Pop() more times than Push()
	$LogFile = Initialize-Log $Path -LogName $LogName -Header $HeaderStack.Peek()

	if ($LogFile)
	{
		if ($Message)
		{
			Write-Information -MessageData $Message -IV LocalBuffer -INFA "SilentlyContinue"

			$Caller = (Get-PSCallStack)[1].ScriptName
			[InformationRecord] $Record = [InformationRecord]::new($LocalBuffer, $Caller)

			$Record.Tags.AddRange($Tags)
			$Record | Select-Object * | Out-File -Append -FilePath $LogFile -Encoding $DefaultEncoding
		}
		else
		{
			$Hash | Out-File -Append -FilePath $LogFile -Encoding $DefaultEncoding
		}
	}
}

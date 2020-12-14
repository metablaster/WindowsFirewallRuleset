
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

using namespace System.Management.Automation

<#
.SYNOPSIS
Write to log file

.DESCRIPTION
Outputs of the built in Write-* commandlets are automatically picked up and logs are
written, however purpose of this function is to write logs manually

.PARAMETER Message
Message from which to construct "InformationRecord" and append to log file

.PARAMETER Hash
Has table which to write to log file

.PARAMETER Tags
One or more optional message tags

.PARAMETER Path
Destination directory

.PARAMETER Label
File label that is added to current date for resulting file name

.EXAMPLE
PS> $File = Initialize-Log -Folder "C:\logs" -Label "Settings" -Header "System changes"
PS> Write-LogFile $File

.INPUTS
None. You cannot pipe objects to Write-LogFile

.OUTPUTS
None. Write-LogFile does not generate any output

.NOTES
None.
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
		[hashtable] $Hash,

		[Parameter()]
		[string] $Path = $LogsFolder,

		[Parameter()]
		[string[]] $Tags = "Administrator",

		[Parameter()]
		[string] $Label = "Admin"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	$LogFile = Initialize-Log $Path -Label $Label -Header $LogHeader

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


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
If the file can't be found or verified, an error is genrated possibly with informational message,
to explain if there is any problem with the path or file name syntax, otherwise information is
present to the user to explain how to resolve the problem including a stack trace to script that
is producing this issue.

.PARAMETER LiteralPath
Fully qualified path to executable file

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
TODO: We should attempt to fix the path if invalid here, ex. Get-Command
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
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking file path: $ExpandedPath"

	$Executable = Split-Path -Path $ExpandedPath -Leaf

	# NOTE: Index 0 is this function
	$Caller = (Get-PSCallStack)[1].Command

	if (Test-FileSystemPath $ExpandedPath -PathType File -Firewall)
	{
		if ($ExpandedPath -match "(\\\.\.\\)+")
		{
			# TODO: While valid for fiewall, we want to resolve/format in Format-Path and Resolve-FileSystemPath
			Write-Warning -Message "Specified file path contains parent directory notation: $ExpandedPath"
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

		if ([string]::IsNullOrEmpty($script:WhiteListExecutable["$Extension"]))
		{
			$ExtensionInfo = $script:BlackListExecutable["$Extension"]

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

				Write-Information -Tags "User" -MessageData "INFO: Blocked file '$Executable' is $ExtensionInfo"
			}

			return $false
		}

		# [System.Management.Automation.Signature]
		$Signature = Get-AuthenticodeSignature -LiteralPath $ExpandedPath

		if ($Signature.Status -ne "Valid")
		{
			if ($Force)
			{
				Write-Warning -Message "Digital signature verification failed for: $ExpandedPath"
				# NOTE: StatusMessage seems to be unrelated to problem
				# Write-Information -Tags "User" -MessageData "INFO: $($Signature.StatusMessage)"
			}
			else
			{
				Write-Error -Category SecurityError -TargetObject $LiteralPath `
					-Message "Digital signature verification failed for: $ExpandedPath"

				Write-Information -Tags "User" -MessageData "INFO: To load rules for unsigned executables run '$Caller' with -Trusted switch"
				return $false
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Executable file '$Executable' $($Signature.StatusMessage)"
		return $true
	}

	Write-Information -Tags "User" -MessageData "INFO: To fix this problem locate '$Executable' file and update installation directory in $Caller"

	return $false
}

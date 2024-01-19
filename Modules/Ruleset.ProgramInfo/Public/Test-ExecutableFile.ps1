
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
If digital signature is missing or not valid, the file is optionally scanned on VirusTotal to
confirm it's not malware.
If the file can't be found or verified, an error is genrated possibly with informational message,
to explain if there is any problem with the path or file name syntax, otherwise information is
present to the user to explain how to resolve the problem including a stack trace to script that
is producing this issue.

.PARAMETER LiteralPath
Fully qualified path to executable file

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

.PARAMETER Timeout
Specify maximum wait time expressed in seconds for VirusTotal to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

.PARAMETER Quiet
If specified, no information, warning or error message is shown, only true or false is returned

.PARAMETER Force
If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in bypassed signature test.
This parameter has no effect on VirusTotal check, if the file is reported as malware the return
value is $false unless SkipVirusTotalCheck global variable is set.

.EXAMPLE
PS> Test-ExecutableFile "C:\Windows\UnsignedFile.exe"

ERROR: Digital signature verification failed for 'C:\Windows\UnsignedFile.exe'
INFO: If you trust this executable run 'CallerScript.ps1' with -Trusted switch

.EXAMPLE
PS> Test-ExecutableFile "C:\Users\USERNAME\AppData\Application\file.paf"

ERROR: File extension 'PAF' is blacklisted executable file 'C:\Users\USERNAME\AppData\Application\file.paf'
INFO: Blocked file 'file.paf' is Portable Application Installer File

.EXAMPLE
PS> Test-ExecutableFile ".\directory\..\file.exe"

WARNING: Specified file path contains parent directory notation '$ExpandedPath'

.INPUTS
None. You cannot pipe objects to Test-ExecutableFile

.OUTPUTS
[bool]

.NOTES
TODO: We should attempt to fix the path if invalid here, ex. Get-Command (-Repair parameter)
TODO: We should return true or false and conditionally load rule
TODO: Verify file is executable file (and path formatted?)

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.signature
#>
function Test-ExecutableFile
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $LiteralPath,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

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

	if ($Quiet)
	{
		$ErrorActionPreference = "SilentlyContinue"
		$WarningPreference = "SilentlyContinue"
		$InformationPreference = "SilentlyContinue"
	}

	$ExpandedPath = Invoke-Command @SessionParams -ArgumentList $LiteralPath -ScriptBlock {
		param ($LiteralPath)
		[System.Environment]::ExpandEnvironmentVariables($LiteralPath)
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking file path '$ExpandedPath'"
	$Executable = Split-Path -Path $ExpandedPath -Leaf

	# Index 0 is this function
	$Caller = (Get-PSCallStack)[1].Command

	if (Test-FileSystemPath $ExpandedPath -PathType File -Firewall -Quiet:$Quiet @SessionParams)
	{
		if ($ExpandedPath -match "(\\\.\.\\)+")
		{
			# TODO: While valid for fiewall, we want to resolve/format in Format-Path and Resolve-FileSystemPath
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified file path contains parent directory notation '$ExpandedPath'"
		}

		# NOTE: Split-Path -Extension is not available in Windows PowerShell
		[string] $Extension = [System.IO.Path]::GetExtension($Executable)

		if ([string]::IsNullOrEmpty($Extension))
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "File extension is missing for specified file '$ExpandedPath'"

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
					-Message "The specified file is not recognized as an executable file '$ExpandedPath'"
			}
			else
			{
				Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
					-Message "File extension '$Extension' is blacklisted executable file '$ExpandedPath'"

				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Blocked file '$Executable' is $ExtensionInfo"
			}

			return $false
		}

		$Signature = Invoke-Command @SessionParams -ArgumentList $ExpandedPath -ScriptBlock {
			param ($ExpandedPath)
			# [System.Management.Automation.Signature]
			Get-AuthenticodeSignature -LiteralPath $ExpandedPath
		}

		if ($Signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid)
		{
			# HACK: We ignore -Quiet switch for signature mismatch because of Deploy-Firewall -Quiet
			# making signature mismatch silent is not desired for bulk deployment however a better
			# design is needed for global -Quiet because this function should be quiet if run on it's own
			# TODO: Errors and warnings are not logged, probably due to script level preferences
			if ($Force)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Digital signature verification failed for '$ExpandedPath'" -WarningAction "Continue"
				# NOTE: StatusMessage seems to be unrelated to problem
				# Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: $($Signature.StatusMessage)"

				if (!$SkipVirusTotalCheck)
				{
					if (Test-VirusTotal -LiteralPath $LiteralPath -SigcheckLocation $SigcheckLocation -TimeOut $TimeOut @SessionParams)
					{
						Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Loading rule for '$(Split-Path $ExpandedPath -Leaf)' skipped due to positive VirusTotal report"
						return $false
					}
				}
			}
			else
			{
				Write-Error -Category SecurityError -TargetObject $LiteralPath `
					-Message "Digital signature verification failed for '$ExpandedPath'" -ErrorAction "Continue"

				if (!$SkipVirusTotalCheck)
				{
					Test-VirusTotal -LiteralPath $LiteralPath -SigcheckLocation $SigcheckLocation -TimeOut $TimeOut @SessionParams | Out-Null
				}

				Write-Information -Tags $MyInvocation.InvocationName -InformationAction "Continue" `
					-MessageData "INFO: If you trust this executable run '$Caller' with -Trusted switch"
				return $false
			}
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Executable file '$Executable' $($Signature.StatusMessage)"
		return $true
	} # if Test-FileSystemPath

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: To fix this problem locate '$Executable' file and update searched directory in '$Caller' script"

	return $false
}

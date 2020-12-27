
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Check if file such as an *.exe exists

.DESCRIPTION
In addition to Test-Path of file, message and stack trace is shown and
warning message if file not found

.PARAMETER LiteralPath
Full path to executable file

.EXAMPLE
PS> Test-File "C:\Users\USERNAME\AppData\Local\Google\Chrome\Application\chrome.exe"

.INPUTS
None. You cannot pipe objects to Test-File

.OUTPUTS
None. Test-File does not generate any output

.NOTES
TODO: We should attempt to fix the path if invalid here!
TODO: We should return true or false and conditionally load rule
TODO: This should probably be renamed to Test-Executable to make it less likely part of utility module
TODO: Verify file is executable file (and path formatted?)
#>
function Test-File
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-File.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $LiteralPath,

		[Parameter()]
		[switch] $Force
	)

	# $VerbosePreference = "Continue"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking file path: $ExpandedPath"

	# NOTE: We are testing fully qualified and valid file system path local to target machine, for
	# This reason it's much simplier to use System.IO classes
	$Executable = Split-Path -Path $ExpandedPath -Leaf
	$HasParentNotation = $ExpandedPath -match "(\\\.\.\\)+"
	$IsRooted = [System.IO.Path]::IsPathRooted($ExpandedPath)
	$Qualifier = Split-Path -Path $ExpandedPath -Qualifier -EA Ignore

	if (!($Qualifier -and $IsRooted))
	{
		# !$IsRooted here means we exclude UNC path notation
		if (!$IsRooted -and (!$Qualifier -or $HasParentNotation))
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "Specified file path is relative: $ExpandedPath"
		}
		else
		{
			# This test eliminates any path that is not file system path with a valid drive letter syntax
			# NOTE: IsPathRooted will give True for UNC path, and Split-Path will give True for non filesystem provider
			# Both of which will give False for opposite tests respectively
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "Specified file path is missing a file system qualifier: $ExpandedPath"
		}
	}
	elseif ([System.IO.File]::Exists($ExpandedPath))
	{
		if ($HasParentNotation)
		{
			# TODO: While valid for fiewall, we want to resolve it in Format-Path
			Write-Warning -Message "Specified file path contains parent directory notation: $ExpandedPath"
		}

		[string] $Extension = Split-Path -Path $ExpandedPath -Extension

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
				Write-Information -Tags "User" -MessageData "INFO: $($Signature.StatusMessage)"
			}
			else
			{
				Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
					-Message "Digital signature verification failed for: $ExpandedPath"

				Write-Information -Tags "User" -MessageData "INFO: To load rules for unsigned executables run '$($MyInvocation.MyCommand)' with -Force switch"
			}

			return $false
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Executable file '$Executable' $($Signature.StatusMessage)"
		return $true
	}
	elseif ([System.IO.Directory]::Exists($ExpandedPath))
	{
		Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
			-Message "Specified file path is directory: $ExpandedPath"
	}
	elseif (Test-Path -Path $ExpandedPath -IsValid)
	{
		if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($ExpandedPath))
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "Specified path contains unresolved wildcard pattern: $ExpandedPath"
		}
		elseif ((Split-Path -Path $ExpandedPath -NoQualifier) -match '[\<\>\:\"\|]')
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "Specified file path contains invalid characters: $ExpandedPath"
		}
		elseif ($Executable -match "\\")
		{
			# TODO: This is also bad character for any of the individual directories
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
				-Message "Specified file contains invalid characters: $ExpandedPath"
		}
		else
		{
			# NOTE: Index 0 is this function
			$Caller = (Get-PSCallStack)[1].Command

			Write-Warning -Message "Executable '$Executable' was not found, firewall rule not loaded"
			Write-Information -Tags "User" -MessageData "INFO: Searched path was: $(Split-Path -Path $ExpandedPath -Parent)"
			Write-Information -Tags "User" -MessageData "INFO: To fix this problem find '$Executable' and update installation directory in $Caller script"
		}
	}
	else
	{
		Write-Error -Category InvalidArgument -TargetObject $LiteralPath `
			-Message "Specified path is not a valid path: $ExpandedPath"
	}

	return $false
}

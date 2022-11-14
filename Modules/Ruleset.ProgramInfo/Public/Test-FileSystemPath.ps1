
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Test existence of a file system path and validate path syntax

.DESCRIPTION
Test-FileSystemPath checks file system path syntax by verifying environment variables and reporting
unresolved wildcard pattern or bad characters.
The path is then tested to confirm it points to an existing and valid location.

Optionally you can check if the path is compatible for firewall rules or if the path leads to user profile.
All of which can be limited to either container or leaf path type.

.PARAMETER LiteralPath
Path to directory or file which to test.
Allows null or empty since it may come from commandlets which may return empty string or null

.PARAMETER Domain
Computer name on which to test path

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER PathType
The type of path to test, can be one of the following:
1. File - The path is path to file
2. Directory - The path is path to directory
3. Any - The path is either path to file or directory, this is default

.PARAMETER Firewall
Ensures path is valid for firewall rule.
When specified, for path to be reported as valid it must be compatible for firewall

.PARAMETER UserProfile
Checks if the path leads to user profile.
When specified, for path to be reported as valid it must lead to user profile.

.PARAMETER Quiet
If specified, no information, warning or error message is shown, only true or false is returned

.EXAMPLE
PS> Test-FileSystemPath "%Windir%"

True, The path is valid, and it exists

.EXAMPLE
PS> Test-FileSystemPath "'%Windir%\System32'"

False, Invalid path syntax

.EXAMPLE
PS> Test-FileSystemPath "%HOME%\AppData\Local\MicrosoftEdge" -Firewall -UserProfile

False, the path contains environment variable that leads to userprofile and will not work for firewall

.EXAMPLE
PS> Test-FileSystemPath "%SystemDrive%\Users\USERNAME\AppData\Local\MicrosoftEdge" -Firewall -UserProfile

True, the path leads to userprofile, is good for firewall rule and it exists

.EXAMPLE
Test-FileSystemPath "%LOCALAPPDATA%\MicrosoftEdge" -UserProfile

True, the path lead to user profile, and it exists

.INPUTS
None. You cannot pipe objects to Test-FileSystemPath

.OUTPUTS
[bool] true if path exists, false otherwise

.NOTES
The result of this function should be used only to verify paths for external usage, not as input to
commandles which don't recognize system environment variables.
This function is needed in cases where the path may be a modified version of an already formatted or
verified path such as in rule scripts or to verify manually edited installation table.
TODO: This should proably be part of Utility or ComputerInfo module, it's here since only this module uses this function.
#>
function Test-FileSystemPath
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-FileSystemPath.md")]
	[OutputType([bool])]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string] $LiteralPath,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter()]
		[Alias("Type")]
		[ValidateSet("File", "Directory", "Any")]
		[string] $PathType = "Any",

		[Parameter()]
		[switch] $Firewall,

		[Parameter()]
		[switch] $UserProfile,

		[Parameter()]
		[switch] $Quiet
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $ConnectParams = @{}
	if ($PsCmdlet.ParameterSetName -eq "Session")
	{
		$ConnectParams.Session = $Session
	}
	else
	{
		$ConnectParams.ComputerName = $Domain
		if ($Credential)
		{
			$ConnectParams.Credential = $Credential
		}
	}

	$InvocationName = $MyInvocation.InvocationName
	[scriptblock] $WriteConditional = {
		param (
			[Parameter(Mandatory = $true)]
			[string] $Message,

			# Following parameters are needed only in remote execution context
			[switch] $Quiet = $Quiet,
			[string] $LiteralPath = $LiteralPath,
			[string] $InvocationName = $InvocationName
		)

		if ($Quiet)
		{
			# Make sure -Quiet switch does not make troubleshooting hard
			Write-Debug -Message "[$InvocationName - WriteConditional] $Message"
		}
		else
		{
			Write-Warning -Message "[$InvocationName - WriteConditional] $Message"
			Write-Information -Tags "$InvocationName - WriteConditional" -MessageData "INFO: Path '$LiteralPath'"
		}
	}

	if ([string]::IsNullOrEmpty($LiteralPath))
	{
		& $WriteConditional "The path name is null or empty"
		return $false
	}

	$ExpandedPath = Invoke-Command @ConnectParams -ScriptBlock {
		[System.Environment]::ExpandEnvironmentVariables($using:LiteralPath)
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking path: $ExpandedPath"

	[string] $Status = ""

	# Qualifier ex. "C:\" "D:", "\" or "\\"
	# Unqualified: Anything except qualifier
	$PathGroups = [regex]::Match($ExpandedPath, "(?<Qualifier>^[A-Za-z]+:\\?|^\\{1,2})?(?<Unqualified>.*)")
	$Qualifier = $PathGroups.Groups["Qualifier"]
	$Unqualified = $PathGroups.Groups["Unqualified"]

	# See if expansion resulted in multiple pats
	# Note that % is valid character to name a file or directory
	if ($ExpandedPath -match "([A-Za-z]:\\?.*){2,}")
	{
		$Status = "Result of environment variable expansion resulted in multiple paths"
	}
	# File system qualifier must be single letter
	elseif ($Qualifier.Success -and ($Qualifier.Value -match "^([A-Za-z]{2,}:\\?)"))
	{
		$Status = "Path qualifier '$Qualifier' is not a file system qualifier"
	}
	# Invalid characters to name a file or directory: / \ : < > ? * | "
	elseif ([WildcardPattern]::ContainsWildcardCharacters($ExpandedPath))
	{
		# Handles: ? * [ ]
		$Status = "Specified path contains unresolved wildcard pattern"
	}
	elseif ($Unqualified.Success -and ($Unqualified.Value -match '[<>:"|]'))
	{
		# NOTE: backslash and forward slash is illegal too, however it will be interpreted as path separator
		# If the path is surrounded by quotes it won't be split
		$Status = "Specified path contains invalid characters"
	}
	else
	{
		$BlackList = Select-EnvironmentVariable -From BlackList -Property Name @ConnectParams
		if ([array]::Find($BlackList, [System.Predicate[string]] { $LiteralPath -like "*$($args[0])*" }))
		{
			$Status = "Specified environment variable was blacklisted"
		}
	}

	if ([string]::IsNullOrEmpty($Status))
	{
		if ($UserProfile -or $Firewall)
		{
			$UserVariables = Select-EnvironmentVariable -From UserProfile -Property Name @ConnectParams
			$IsUserProfile = [array]::Find($UserVariables, [System.Predicate[string]] { $LiteralPath -like "$($args[0])*" })

			if ($Firewall)
			{
				if ($IsUserProfile)
				{
					& $WriteConditional "A Path with environment variable which leads to user profile is not valid for firewall"
					return $false
				}

				# Verify path environment variables are whitelisted
				# NOTE: This check must be before qualifier check to get precise error description
				$RegexVariable = [regex]::Match($LiteralPath, "(?<=%)[^%\\]+(?=%)")
				$WhiteList = Select-EnvironmentVariable -From WhiteList -Property Name -Exact @ConnectParams

				while ($RegexVariable.Success)
				{
					if ($RegexVariable.Value -notin $WhiteList)
					{
						& $WriteConditional "Specified environment variable was not whitelisted for firewall"
						return $false
					}

					$RegexVariable = $RegexVariable.NextMatch()
				}

				if ($Qualifier.Success)
				{
					if ($Qualifier -notmatch "^[A-Za-z]:\\")
					{
						& $WriteConditional "The path qualifier '$Qualifier' is not valid for firewall rules"
						return $false
					}
				}
				else
				{
					& $WriteConditional "File system qualifier is required for firewall rules"
					return $false
				}
			}

			# HACK: Need a separate function
			[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem -CimSession $CimServer |
			Select-Object -ExpandProperty SystemDrive

			# NOTE: Public folder and it's subdirectories are not user profile
			if (!$IsUserProfile -and $UserProfile -and ($ExpandedPath -notmatch "^(($SystemDrive\\?)|\\)Users(?!\\+(Public$|Public\\+))\\"))
			{
				& $WriteConditional "The path does not lead to user profile"
				return $false
			}
		}

		Invoke-Command @ConnectParams -ArgumentList $WriteConditional -ScriptBlock {
			# NOTE: Must not be declared as [scriptblock], otherwise [ScriptBlock]::Create() (later) fails
			param ($WriteConditional)

			if ($using:PathType -eq "Any")
			{
				if ([System.IO.Directory]::Exists($using:ExpandedPath) -or [System.IO.File]::Exists($using:ExpandedPath))
				{
					return $true
				}

				$Status = "Specified file or directory does not exist"
			}
			elseif ($using:PathType -eq "Directory")
			{
				if ([System.IO.Directory]::Exists($using:ExpandedPath))
				{
					return $true
				}

				$Status = "Specified directory does not exist"
			}
			elseif ($using:PathType -eq "File")
			{
				if ([System.IO.File]::Exists($using:ExpandedPath))
				{
					return $true
				}

				$Status = "Specified file does not exist"
			}

			[ScriptBlock]::Create($WriteConditional).Invoke($Status, $using:Quiet, $using:LiteralPath, $using:InvocationName)
			return $false
		} # Invoke-Command
	} # if ([string]::IsNullOrEmpty($Status))
}

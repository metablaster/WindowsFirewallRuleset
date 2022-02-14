
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
Get SDDL string for a path

.DESCRIPTION
Get SDDL string for file system or registry locations on a single target computer

.PARAMETER Path
Single file system or registry location for which to obtain SDDL.
Wildcard characters are supported.

.PARAMETER Domain
Computer name on which specified path is located

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER Merge
If specified, combines resultant SDDL strings into one

.EXAMPLE
PS> Get-PathSDDL -Path "C:\Users\Public\Desktop\" -Domain Server01 -Credential (Get-Credential)

.EXAMPLE
PS> Get-PathSDDL -Path "C:\Users" -Session (New-PSSession)

.EXAMPLE
Get-PathSDDL -Path "HKLM:\SOFTWARE\Microsoft\Clipboard"

.INPUTS
None. You cannot pipe objects to Get-PathSDDL

.OUTPUTS
[string]

.NOTES
None.
#>
function Get-PathSDDL
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-PathSDDL.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[string] $Path,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter()]
		[switch] $Merge
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($PSCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session
	}
	else
	{
		$SessionParams.ComputerName = $Domain
		if ($Credential)
		{
			$SessionParams.Credential = $Credential
		}
	}

	$MachineName = Format-ComputerName $Domain

	# Glossary:
	# SDDL: Security Descriptor Definition Language
	# ACE: Access Control Entry (Describes what access rights a security principal has to the secured object)
	# SID: Security IDentifier (Identifies a user or group)
	# DACL: Discretionary Access Control List (ACEs in DACL identify the users and groups that are assigned or denied access permissions on an object)
	# SACL: System Access Control List (ACEs in a SACL determine what types of access is logged in the Security Event Log)
	# ACL: Access Control List (Base name for DACL and SACL, DACL and SACL are ACL's)

	# https://docs.microsoft.com/en-us/windows/win32/secauthz/ace-strings
	# SDDL uses ACE strings in the DACL and SACL, each ACE is enclosed in parentheses.
	# The fields of each ACE are separated by semicolons.
	# ace_type;ace_flags;rights;object_guid;inherit_object_guid;account_sid;(resource_attribute)

	# https://docs.microsoft.com/en-us/windows/win32/secauthz/security-descriptor-definition-language
	# The four main components of SDDL are:
	# owner SID 			(O:sid)			A SID string that identifies the object's owner
	# primary group SID 	(G:sid)			A SID string that identifies the object's primary group.
	# DACL flags 			(D:flags) (ACE 1)..(ACE n)
	# SACL flags 			(S:flags) (ACE 1)..(ACE n)

	<# 	The DACL flags can be a concatenation of zero or more of the following strings:
	"P"					SE_DACL_PROTECTED flag is set.
	"AR"				SE_DACL_AUTO_INHERIT_REQ flag is set.
	"AI"				SE_DACL_AUTO_INHERITED flag is set.
	"NO_ACCESS_CONTROL"	ACL is null.

	The SACL flags string uses the same control bit strings as the dacl_flags string.
	DACL and SACL flags control bits that relate to automatic inheritance of ACE
	ACE: A string that describes an ACE in the security descriptor's DACL or SACL
	#>

	[string] $DACL = $null

	if (($PSCmdlet.ParameterSetName -eq "Domain") -and ($MachineName -eq [System.Environment]::MachineName))
	{
		# TODO: Multiple paths should be supported either here or trough path parameter
		$TargetPath = Resolve-Path -Path $Path -ErrorAction Ignore
	}
	elseif (Test-Computer $Domain)
	{
		$TargetPath = Invoke-Command @SessionParams -ScriptBlock {
			Resolve-Path -Path $using:Path -ErrorAction Ignore
		}
	}
	else { return }

	$ItemCount = ($TargetPath | Measure-Object).Count

	if ($ItemCount -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $Path -Message "The path could not be resolved: $Path"
		return
	}
	elseif ($ItemCount -gt 1)
	{
		Write-Error -Category ObjectNotFound -TargetObject $Path -Message "The path resolves to multiple $($ItemCount) paths: $Path"
		return
	}

	if (($PSCmdlet.ParameterSetName -eq "Domain") -and ($MachineName -eq [System.Environment]::MachineName))
	{
		$ACL = Get-Acl -Path $TargetPath
	}
	else
	{
		$ACL = Invoke-Command @SessionParams -ScriptBlock {
			Get-Acl -Path $using:TargetPath
		}
	}

	if (!$ACL)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] The path is missing SDDL entry: $TargetPath"
		return
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL of a path: $TargetPath"

	if ($Merge)
	{
		# Get entry DACL value, already merged
		$RegMatch = [regex]::Matches($ACL.Sddl, "D\:\w+\(.+\)")

		if ($RegMatch.Count -eq 1)
		{
			$DACL = $RegMatch.Captures.Value
		}
	}
	else
	{
		# Get DACL flags
		$RegMatch = [regex]::Matches($ACL.Sddl, "D\:\w+")

		if ($RegMatch.Count -eq 1)
		{
			# Break down ACE's
			$SDDLSplit = $ACL.Sddl.Split("(").TrimEnd(")")

			# Iterate DACL entry for each ACE
			# Index 0 - 6 (where index 6 is optional) are as follows:
			# ace_type;ace_flags;rights;object_guid;inherit_object_guid;account_sid;(resource_attribute)
			for ($Index = 1; $Index -lt $SDDLSplit.Length; ++$Index)
			{
				# For each ACE, combine DACL flags with ACE
				$DACL = $RegMatch.Captures.Value + "($($SDDLSplit[$Index]))"

				Write-Debug -Message "[$($MyInvocation.InvocationName)] $($ACL.Sddl) resolved to: $DACL"
				Write-Output $DACL
			}

			return
		}
	}

	if ($RegMatch.Count -gt 1)
	{
		# TODO: This must be always false, confirm maximum one SID can be in there
		Write-Error -Category NotImplemented -TargetObject $RegMatch -Message "Expected 1 regex match, got multiple"
		exit
	}

	if ([string]::IsNullOrEmpty($DACL))
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] The path is missing DACL entry: $TargetPath"
		return
	}

	if ($Merge)
	{
		if ($DACL.Length -lt 3)
		{
			Write-Error -Category InvalidResult -TargetObject $DACL -Message "Failed to assemble SDDL"
		}
		else
		{
			Write-Output $DACL
		}
	}
}

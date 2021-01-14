
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
Convert SDDL string to Principal

.DESCRIPTION
Convert one or multiple SDDL strings to Principal, a custom object containing
relevant information about the principal.

.PARAMETER SDDL
One or more strings of SDDL syntax

.EXAMPLE
PS> ConvertFrom-SDDL -SDDL "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

.EXAMPLE
PS> ConvertFrom-SDDL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

.EXAMPLE
PS> $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)" | ConvertFrom-SDDL

.INPUTS
[string[]]

.OUTPUTS
[PSCustomObject]

.NOTES
None.
#>
function ConvertFrom-SDDL
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SDDL.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $SDDL
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
		$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
	}
	process
	{
		foreach ($SddlEntry in $SDDL)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing SDDL: $SddlEntry"

			# Case sensitive regex pattern to math exactly one DACL entry within SDDL string
			$RegMatch = [regex]::Matches($SddlEntry, "(D:\w*(\((\w*;\w*){4};((S(-\d+){2,12})|[A-Z]*)\))+){1}")

			if ($RegMatch.Count -ne 1)
			{
				Write-Error -Category InvalidArgument -TargetObject $SddlEntry `
					-Message "SDDL string to be valid must contain exactly one DACL entry: $SddlEntry"
				continue
			}

			$SddlSplit = $SddlEntry.Split("(").TrimEnd(")")
			$RegMatch = [regex]::Matches($SddlSplit[0], "D:(\w+)?")

			if ($RegMatch.Count -eq 1)
			{
				<# The DACL flags can be a concatenation of zero or more of the following strings:
				"P"					SE_DACL_PROTECTED flag is set.
				"AR"				SE_DACL_AUTO_INHERIT_REQ flag is set.
				"AI"				SE_DACL_AUTO_INHERITED flag is set.
				"NO_ACCESS_CONTROL"	ACL is null.
				#>
				$DaclFlags = $RegMatch.Captures.Value
			}
			else
			{
				Write-Error -Category ParserError -TargetObject $RegMatch `
					-Message "Unable to parse out DACL flags"
				continue
			}

			# Iterate DACL entry for each ACE
			# Index 0 - 6 (where index 6 is optional) are as follows:
			# ace_type;ace_flags;rights;object_guid;inherit_object_guid;account_sid;(resource_attribute)
			for ($Index = 1; $Index -lt $SddlSplit.Length; ++$Index)
			{
				$ACE = $SddlSplit[$Index]
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing ACE: $ACE"

				$AceSplit = $ACE.Split(";")

				if (!$AceSplit[1].Contains("ID")) # if (!"Inherited")
				{
					# TODO: Parse out the SID (store apps have 12 groups of digits in total, other SID's have 8?)
					# If the match is successful, the collection is populated with one [System.Text.RegularExpressions.Match]
					# object for each match found in the input string.
					[System.Text.RegularExpressions.MatchCollection] $RegMatch = [regex]::Matches($AceSplit[5], "(S(-\d+){2,12})")
					if ($RegMatch.Count -eq 1)
					{
						$DACL = "$DaclFlags($ACE)"
						$SID = $RegMatch.Captures.Value

						try
						{
							# Set the security descriptor from the specified SDDL
							$ACLObject.SetSecurityDescriptorSddlForm($DACL)
						}
						catch
						{
							Write-Error -Category InvalidArgument -TargetObject $DACL -Message "Invalid SDDL: '$($DACL)' $($_.Exception.Message)"
							continue
						}

						# [System.Security.Principal.NTAccount]
						$Principal = $ACLObject.Access | Select-Object -ExpandProperty IdentityReference |
						Select-Object -ExpandProperty Value

						[PSCustomObject]@{
							Domain = Split-Principal $Principal -DomainName
							User = Split-Principal $Principal
							# TODO: Group = ?, we have no clue about group, calling a function would be overhead
							# the reason why to include group is consitency for "Ruleset.UserInfo" custom object
							Principal = $Principal
							SID = $SID
							SDDL = $DACL
							PSTypeName = "Ruleset.UserInfo"
						}
					}
					elseif ($RegMatch.Count -gt 1)
					{
						# TODO: This must be always false, confirm maximum one SID can be in there
						Write-Error -Category NotImplemented -TargetObject $RegMatch -Message "Expected 1 regex match, got multiple"
					}
					else
					{
						# "Not inherited"
						continue
					}
				} # if (!"Inherited")
			} # for
		} # foreach ($SddlEntry in $SDDL)
	} # process
}

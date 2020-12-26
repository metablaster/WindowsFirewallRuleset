
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
Convert SDDL string to Principal

.DESCRIPTION
Convert one or multiple SDDL strings to Principals

.PARAMETER SDDL
String array of one or more strings of SDDL syntax

.EXAMPLE
PS> ConvertFrom-SDDL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

.EXAMPLE
PS> $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)" | ConvertFrom-SDDL

.INPUTS
[string]

.OUTPUTS
[PSCustomObject]

.NOTES
None.
#>
function ConvertFrom-SDDL
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-SDDL.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $SDDL
	)

	begin
	{
		$ACLObject = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Entry in $SDDL)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing $Entry"

			$SDDLSplit = $Entry.Split("(")

			# Write-Output ""
			# Write-Output "SDDL Split:"
			# Write-Output "****************"

			# $SDDLSplit

			# Write-Output ""
			# Write-Output "SDDL SID Parsing:"
			# Write-Output "****************"
			$Inherited = "?"

			# Skip index 0 where owner and/or primary group are stored
			for ($i = 1; $i -lt $SDDLSplit.Length; ++$i)
			{
				$ACLSplit = $SDDLSplit[$i].Split(";")
				$ACLObject.SetSecurityDescriptorSddlForm($ACLSplit[1])

				$Principal = $ACLObject.Access | Select-Object -ExpandProperty IdentityReference |
				Select-Object -ExpandProperty Value

				if ($ACLSplit[1].Contains("ID"))
				{
					$Inherited = "Inherited"
				}
				else
				{
					$ACLEntrySID = $null

					# Remove the trailing ")"
					$ACLEntry = $ACLSplit[5].TrimEnd(")")

					# Parse out the SID using a handy RegEx
					$ACLEntrySIDMatches = [regex]::Matches($ACLEntry, "(S(-\d+){2,8})")

					# NOTE: original changed from $ACLEntrySID = $_.value to $ACLEntrySID += $_.value
					$ACLEntrySIDMatches | ForEach-Object {
						$ACLEntrySID += $_.Value
					}

					if ($ACLEntrySID)
					{
						$SID = $ACLEntrySID
					}
					else
					{
						$Inherited = "Not inherited"
					}
				}
			}

			[PSCustomObject]@{
				Principal = $Principal
				SID = $SID
				# SDDL = $Entry
				Inherited = $Inherited
			}
		} # foreach ($Entry in $SDDL)
	}
}

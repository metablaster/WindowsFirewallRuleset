
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
Show-SDDL returns SDDL based on "object" such as path, or registry entry

.DESCRIPTION
TODO: add description

.PARAMETER SDDL
TODO: describe parameter

.EXAMPLE
see Test\Show-SDDL.ps1 for example

.INPUTS
[string]

.OUTPUTS
[string]

.NOTES
This function is used only for debugging and discovery of object SDDL
Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1
TODO: additional work on function to make it more universal, see if we can make use of it somehow, better help comment.
#>
function Show-SDDL
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Show-SDDL.md"	)]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipelineByPropertyName = $true)]
		[string] $SDDL
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		$SDDLSplit = $SDDL.Split("(")

		Write-Output ""
		Write-Output "SDDL Split:"
		Write-Output "****************"

		$SDDLSplit

		Write-Output ""
		Write-Output "SDDL SID Parsing:"
		Write-Output "****************"

		# Skip index 0 where owner and/or primary group are stored
		for ($i = 1; $i -lt $SDDLSplit.Length; ++$i)
		{
			$ACLSplit = $SDDLSplit[$i].Split(";")

			if ($ACLSplit[1].Contains("ID"))
			{
				Write-Output "Inherited"
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
					Write-Output $ACLEntrySID
				}
				else
				{
					Write-Output "Not inherited - No SID"
				}
			}
		}
	}
}

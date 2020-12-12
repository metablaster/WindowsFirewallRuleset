
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

<#
.SYNOPSIS
Verify TypeName and OutputType are referring to same type

.DESCRIPTION
This test case is to ensure object output typename is referring to
same type as at least one of the types described by the OutputType attribute.
Comparison is case sensitive for the matching typename part.
TypeName and OutputType including equality test is printed to console

.PARAMETER InputType
The actual .NET typename which some function returns

.PARAMETER Command
Commandlet or function name for which to retrieve OutputType attribute values,
and then compare InputType against those values.

.EXAMPLE
PS> $Result = Some-Function
PS> Test-Output $Result -Command Some-Function

.INPUTS
None. You cannot pipe objects to Test-Output

.OUTPUTS
None. Test-Output does not generate any output

.NOTES
TODO: For functions which may return null we should not compare
#>
function Test-Output
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-Output.md")]
	[OutputType([void])]
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[AllowNull()]
		[System.Object[]] $InputType,

		[Parameter(Mandatory = $true)]
		[string] $Command
	)

	begin
	{
		Start-Test "Compare TypeName and OutputType"
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# NOTE: OutputType variable may contain multiple valid entries
		$OutputType = Get-TypeName -Command $Command
		$TypeName = Get-TypeName $InputType

		Write-Information -Tags "Test" -MessageData "INFO: TypeName:`t`t$TypeName"
		$OutputType | ForEach-Object {
			Write-Information -Tags "Test" -MessageData "INFO: OutputType:`t$_"
		}

		if ([string]::IsNullOrEmpty($TypeName))
		{
			Write-Error -Category InvalidResult -TargetObject $InputType -Message "Unable to perform type comparison, missing object TypeName"
		}
		elseif ([string]::IsNullOrEmpty($OutputType))
		{
			Write-Error -Category InvalidResult -TargetObject $Command -Message "Unable to perform type comparison, missing OutputType attribute"
		}
		elseif ($OutputType -ceq $TypeName)
		{
			# Output was defined by OutputType
			Write-Information -Tags "Test" -MessageData "INFO: Typename and OutputType are identical"
		}
		elseif ($OutputType -like "$TypeName*" -or ($OutputType | Where-Object { $TypeName -like "$_*" }))
		{
			# Either typename is longer and contains one of OutputType's in it's name or
			# typename is shorter and contained withing one of OutputTypes or
			# both are the same but different casing used.
			Write-Warning -Message "Typename is similar to OutputType but not named exactly the same"
		}
		else
		{
			Write-Error -Category InvalidResult -TargetObject $TypeName `
				-Message "Typename and OutputType are not identical"
		}
	}
	end
	{
		Stop-Test
	}
}

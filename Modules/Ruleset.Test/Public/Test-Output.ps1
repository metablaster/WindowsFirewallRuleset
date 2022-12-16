
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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

.PARAMETER InputObject
.NET object which some function returned

.PARAMETER Command
Commandlet or function name for which to retrieve OutputType attribute
values for comparison with InputObject

.PARAMETER Force
If specified, the function doesn't check if either InputObject or OutputType attribute of
tested command is a .NET type.
This is useful only for PSCustomObject types defined with PSTypeName.

.EXAMPLE
PS> $Result = Some-Function
PS> Test-Output $Result -Command Some-Function

.EXAMPLE
PS> Some-Function | Test-Output -Command Some-Function

.INPUTS
[object[]]

.OUTPUTS
None. Test-Output does not generate any output

.NOTES
TODO: InputObject should be returned if pipeline is used
#>
function Test-Output
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-Output.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[AllowNull()]
		[object[]] $InputObject,

		[Parameter(Mandatory = $true)]
		[string] $Command,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		if (Get-Variable -Name TestCommand -Scope Script -ErrorAction Ignore)
		{
			$TestCommand = $script:TestCommand
			Remove-Variable -Name TestCommand -Scope Script -Force

			Start-Test "Compare TypeName and OutputType of '$Command'"
			Set-Variable -Name TestCommand -Scope Script -Force -Value $TestCommand
		}
		else
		{
			Start-Test "Compare TypeName and OutputType of '$Command'"
		}

		$AllTypeName = @()
		$AllOutputType = @()
	}
	process
	{
		# TODO: Using foreach here for cases where -InputObject is an array but not from pipeline
		# will not not work in cases when function being tested returns null, see unit test.
		# NOTE: OutputType variable may contain multiple valid entries
		# Ignoring errors to reduce spamming console with errors
		$AllTypeName += Get-TypeName $InputObject -ErrorAction SilentlyContinue -Force:$Force
		$AllOutputType += Get-TypeName -Command $Command -ErrorAction SilentlyContinue -Force:$Force
	}
	end
	{
		# Multiple TypeName's might be returned as well as multiple OutputType attributes might exist
		$TypeName = @($AllTypeName | Select-Object -Unique)
		$OutputType = @($AllOutputType | Select-Object -Unique)

		# For each print output
		$TypeName | ForEach-Object {
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: TypeName:`t`t$_"
		}
		$OutputType | ForEach-Object {
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: OutputType:`t$_"
		}

		# If there is none write blank entry, this is for completeness, otherwise info message won't be shown
		if ($TypeName.Count -eq 0)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: TypeName:"
		}
		if ($OutputType.Count -eq 0)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: OutputType:"
		}

		# Compare typenames and outputtypes
		$CaseSensitive = Compare-Object -ReferenceObject $TypeName -DifferenceObject $OutputType -IncludeEqual -ExcludeDifferent -CaseSensitive |
		Where-Object {
			$_.SideIndicator -eq "=="
		}

		if ($null -ne $CaseSensitive)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Typename and OutputType are identical"
		}
		else
		{
			$Equal = Compare-Object -ReferenceObject $TypeName -DifferenceObject $OutputType -IncludeEqual -ExcludeDifferent |
			Where-Object {
				$_.SideIndicator -eq "=="
			}

			if ($null -ne $Equal)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Typename is declared in OutputType but it's not case sensitive"
			}
			else
			{
				$Reference = Compare-Object -ReferenceObject $TypeName -DifferenceObject $OutputType | Where-Object {
					$_.SideIndicator -eq "<="
				} | ForEach-Object {
					# Output type is accelerator
					foreach ($Entry in $OutputType)
					{
						if ($_.InputObject -like "*$Entry")
						{
							$_.InputObject
							break
						}
					}
				}

				$Difference = Compare-Object -ReferenceObject $TypeName -DifferenceObject $OutputType | Where-Object {
					$_.SideIndicator -eq "=>"
				} | ForEach-Object {
					# TypeName is accelerator
					foreach ($Entry in $TypeName)
					{
						if ($_.InputObject -like "*.$Entry")
						{
							$_.InputObject
							break
						}
					}
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Reference is '$Reference'"
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Difference is '$Difference'"

				if ($Reference)
				{
					$Message = "OutputType is similar to TypeName but not not exact"

					if ($Force)
					{
						Write-Error -Category InvalidResult -TargetObject $TypeName -Message $Message
					}
					else
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] $Message"
					}
				}
				elseif ($Difference)
				{
					$Message = "Typename is similar to OutputType but not not exact"

					if ($Force)
					{
						Write-Error -Category InvalidResult -TargetObject $OutputType -Message $Message
					}
					else
					{
						# TypeName is full name and OutputType is accelerator or vice versa
						Write-Warning -Message "[$($MyInvocation.InvocationName)] $Message"
					}
				}
				else
				{
					Write-Error -Category InvalidResult -TargetObject $TypeName `
						-Message "Typename and OutputType are not identical"
				}
			}
		}
	}
}

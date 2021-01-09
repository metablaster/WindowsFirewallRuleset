
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes
Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Convert value to boolean

.DESCRIPTION
Several firewall rule attributes are boolean such as:
True/False or 1/0
Convert-ValueToBoolean converts these values to $true/$false

.PARAMETER Value
Value which to convert to boolean

.PARAMETER DefaultValue
If the Value is null or empty this value will be used as a result

.EXAMPLE
PS> Convert-ValueToBoolean True
True

.EXAMPLE
PS> Convert-ValueToBoolean 0
False

.INPUTS
None. You cannot pipe objects to Convert-ValueToBoolean

.OUTPUTS
[bool]

.NOTES
Following modifications by metablaster:
August 2020:
- Make Convert-ValueToBoolean Advanced function
- Change code style to be same as the rest of a project code
September 2020:
- Change logic to validate input and show warning or error for unexpected input
- Added Write-* stream
#>
function Convert-ValueToBoolean
{
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter()]
		[string] $Value,

		[Parameter()]
		[bool] $DefaultValue = $false
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ([string]::IsNullOrEmpty($Value))
	{
		Write-Warning -Message "Input is missing, using default value of: $DefaultValue"
		return $DefaultValue
	}

	$Result = switch ($Value)
	{
		"1"
		{
			$true
			break
		}
		"True"
		{
			$true
			break
		}
		"0"
		{
			$false
			break
		}
		"False"
		{
			$false
			break
		}
		default
		{
			Write-Error -Category InvalidArgument -TargetObject $Value -Message "Value '$Value' can't be converted to boolean"
			$null
		}
	}

	return $Result
}


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
Convert from OS build number to OS version

.DESCRIPTION
Convert from OS build number to OS version associated with build.
Note that "OS version" is not the same as "OS release version"

.PARAMETER Build
Operating system build number

.EXAMPLE
PS> ConvertFrom-OSBuild 18363.1049

1909

.INPUTS
None. You cannot pipe objects to ConvertFrom-OSBuild

.OUTPUTS
[string]

.NOTES
None.
#>
function ConvertFrom-OSBuild
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/ConvertFrom-OSBuild.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern("^\d{5}(\.\d{3}\d{0,2})?$")]
		[string] $Build
	)

	# Drop decimal part, not used
	$WholePart = [decimal]::ToUInt32($Build)

	foreach ($Info in $Script:OSBuildInfo)
	{
		if ($Info.Build -eq $WholePart)
		{
			return $Info.Version
		}
	}

	if ($Build -gt $OSBuildInfo[0].Build)
	{
		# TODO: OS Version is still present and may be older than latest RTM version
		return "Insider"
	}

	Write-Error -Category ObjectNotFound -TargetObject $Build `
		-Message "OS build number $Build unsupported or not recognized"
}

<#
https://docs.microsoft.com/en-us/windows/release-information/
Version	Servicing option				Availability OS build	Latest revision date	End of service
20H2	Semi-Annual Channel				2020-10-20	19042.572	2020-10-13	2022-05-10	2023-05-09
2004	Semi-Annual Channel				2020-05-27	19041.450	2020-08-11	2021-12-14	2021-12-14	Microsoft recommends
1909	Semi-Annual Channel				2019-11-12	18363.1049	2020-08-20	2021-05-11	2022-05-10
1903	Semi-Annual Channel				2019-05-21	18362.1049	2020-08-20	2020-12-08	2020-12-08
1809	Semi-Annual Channel				2019-03-28	17763.1432	2020-08-20	2020-11-10	2021-05-11
1809	Semi-Annual Channel (Targeted)	2018-11-13	17763.1432	2020-08-20	2020-11-10	2021-05-11
1803	Semi-Annual Channel				2018-07-10	17134.1667	2020-08-11	End of service	2020-11-10
1803	Semi-Annual Channel (Targeted)	2018-04-30	17134.1667	2020-08-11	End of service	2020-11-10
1709	Semi-Annual Channel				2018-01-18	16299.2045	2020-08-11	End of service	2020-10-13
1709	Semi-Annual Channel (Targeted)	2017-10-17	16299.2045	2020-08-11	End of service	2020-10-13	# Check OS build

Enterprise and IoT Enterprise LTSB/LTSC editions

Version		Servicing option					Availability OS build	Latest revision date	Mainstream support end date	Extended support end date
1809		Long-Term Servicing Channel (LTSC)	2018-11-13	17763.1432	2020-08-20	2024-01-09	2029-01-09
1607		Long-Term Servicing Branch (LTSB)	2016-08-02	14393.3866	2020-08-11	2021-10-12	2026-10-13
1507 (RTM)	Long-Term Servicing Branch (LTSB)	2015-07-29	10240.18666	2020-08-11	2020-10-13	2025-10-14
#>

Set-Variable -Name OSBuildInfo -Scope Script -Option Constant -Value ([PSCustomObject[]]@(
		[hashtable]@{
			Version = "20H2"
			Build = 19042
		}
		[hashtable]@{
			Version = "2004"
			Build = 19041
		}
		[hashtable]@{
			Version = "1909"
			Build = 18363
		}
		[hashtable]@{
			Version = "1903"
			Build = 18362
		}
		[hashtable]@{
			Version = "1809"
			Build = 17763
		}
		[hashtable]@{
			Version = "1803"
			Build = 17134
		}
		[hashtable]@{
			Version = "1709"
			Build = 16299
		}
		[hashtable]@{
			Version = "1607"
			Build = 14393
		}
		[hashtable]@{
			Version = "1507"
			Build = 10240
		}
	)
) -Description "OS Build\Version map"

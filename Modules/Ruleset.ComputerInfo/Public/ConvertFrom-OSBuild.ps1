
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
The ValidatePattern attribute matches decimal part as (,\d{2,5})? instead of (\.\d{3,5})? because
ex. 19041.450 will convert to 19041,45, last zeroes will be dropped and dot is converted to coma.

.LINK
https://docs.microsoft.com/en-us/windows/release-health/release-information

.LINK
https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information
#>
function ConvertFrom-OSBuild
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/ConvertFrom-OSBuild.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern("^\d{5}(,\d{2,5})?$")]
		[decimal] $Build
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Drop decimal part, not used
	$WholePart = [decimal]::ToUInt32($Build)

	foreach ($Info in $script:OSBuildInfo)
	{
		if ($Info.Build -eq $WholePart)
		{
			return $Info.Version
		}
	}

	if ($Build -gt $script:OSBuildInfo[0].Build)
	{
		# TODO: OS Version is still present and may be older than latest RTM version
		return "Insider"
	}

	Write-Error -Category ObjectNotFound -TargetObject $Build `
		-Message "OS build number $Build is unsupported or not recognized"
}

<#
MSDN: Windows 10

Version	Servicing option				Availability OS build	Latest revision date	End of service
22H2	General Availability Channel    2022-10-18	19045.2251	2022-11-08				2024-05-14
21H2	General Availability Channel	2021-11-16	19044.1415	2021-12-14	2023-06-13	2024-06-11
21H1	Semi-Annual Channel				2021-05-18	19043.1165	2021-08-10	2022-12-13	2022-12-13
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
21H2		Long-Term Servicing Channel (LTSC)	2021-11-16	19044.1415	2021-12-14	2027-01-12	2032-01-13 (IoT Enterprise only)
1809		Long-Term Servicing Channel (LTSC)	2018-11-13	17763.1432	2020-08-20	2024-01-09	2029-01-09
1607		Long-Term Servicing Branch (LTSB)	2016-08-02	14393.3866	2020-08-11	2021-10-12	2026-10-13
1507 (RTM)	Long-Term Servicing Branch (LTSB)	2015-07-29	10240.18666	2020-08-11	2020-10-13	2025-10-14

Windows Server release				Servicing option					Editions							Availability	Build		Mainstream support end date	Extended support end date
Windows Server 2022					Long-Term Servicing Channel (LTSC)	Datacenter, Standard				2021-08-18		20348.169	2026-10-13					2031-10-14
Windows Server, version 20H2		Semi-Annual Channel					Datacenter Core, Standard Core		2020-10-20		19042.508	2022-05-10					Not applicable
Windows Server, version 2004		Semi-Annual Channel					Datacenter Core, Standard Core		2020-05-27		19041.264	End of servicing			Not applicable
Windows Server, version 1909		Semi-Annual Channel					Datacenter Core, Standard Core		2019-11-12		18363.418	End of servicing			Not applicable
Windows Server 2019 (version 1809)	Long-Term Servicing Channel (LTSC)	Datacenter, Essentials, Standard	2018-11-13		17763.107	2024-01-09					2029-01-09
Windows Server 2016 (version 1607)	Long-Term Servicing Channel (LTSC)	Datacenter, Essentials, Standard	2016-10-15		14393.0		2022-01-11					2027-01-11

Windows 11

Version	Servicing option	            Availability date Latest revision date Latest build End of servicing: Home, Pro, Pro Education and Pro for Workstations	End of servicing: Enterprise, Education and IoT Enterprise
23H2    General Availability Channel    2023-10-31        2023-11-14           22631.2715   2025-11-11 2026-11-10
22H2	General Availability Channel	2022-09-20	      2022-11-08	       22621.819    2024-10-08 2025-10-14
21H2	General Availability Channel	2021-10-04	      2022-11-08           22000.1219   2023-10-10 2024-10-08
#>

Set-Variable -Name OSBuildInfo -Scope Script -Option Constant -Value ([PSCustomObject[]]@(
		# Windows Server 2022
		[hashtable]@{
			Version = "21H2" # Version obtained from winver.exe
			Build = 20348
		}
		# Windows 11
		[hashtable]@{
			Version = "23H2"
			Build = 22631
		}
		[hashtable]@{
			Version = "22H2"
			Build = 22621
		}
		[hashtable]@{
			Version = "21H2"
			Build = 22000
		}
		# Windows 10
		[hashtable]@{
			Version = "22H2"
			Build = 19045
		}
		[hashtable]@{
			Version = "21H2"
			Build = 19044
		}
		[hashtable]@{
			Version = "21H1"
			Build = 19043
		}
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
) -Description "OS Version\Build map"

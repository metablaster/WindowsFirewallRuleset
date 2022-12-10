
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
Get operating system SKU information

.DESCRIPTION
Get the SKU (Stock Keeping Unit) information for one or multiple target computers,
or translate SKU number to SKU string

.PARAMETER SKU
Operating system SKU number to convert to SKU string

.PARAMETER Domain
One or more computer names for which to obtain SKU

.PARAMETER CimSession
Specifies the CIM session to use

.EXAMPLE
PS> Get-SystemSKU

Domain      SystemSKU     SKU
MY-DESKTOP  Professional  48

.EXAMPLE
PS> @(Server1, Server2, Server3) | Get-SystemSKU

Domain    SystemSKU                SKU
Server1   Professional             48
Server2   Home Premium N           26
Server3   Microsoft Hyper-V Server 42

.EXAMPLE
PS> Get-SystemSKU -SKU 7

Domain   SystemSKU   SKU
         Server      Standard  7

.INPUTS
[string[]]

.OUTPUTS
[PSCustomObject]

.NOTES
TODO: Accept UPN and NETBIOS computer names

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-SystemSKU.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0

.LINK
https://docs.microsoft.com/en-us/surface/surface-system-sku-reference
#>
function Get-SystemSKU
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-SystemSKU.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = "Number")]
		[ValidatePattern("^[0-9]{1,3}$")]
		[int32] $SKU,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$CimParams = @{
			ErrorAction = "Stop"
			Namespace = "root\cimv2"
			Class = "Win32_OperatingSystem"
			Property = "OperatingSystemSku"
		}

		[ScriptBlock] $GetStringSKU = {
			param ([int32] $SKU)

			switch ($SKU)
			{
				0 { "An unknown product"; break; }
				1 { "Ultimate"; break; }
				2 { "Home Basic"; break; }
				3 { "Home Premium"; break; }
				4 { "Enterprise"; break; }
				5 { "Home Basic N"; break; }
				6 { "Business"; break; }
				7 { "Server Standard"; break; }
				8 { "Server Datacenter (full installation)"; break; }
				9 { "Windows Small Business Server"; break; }
				10 { "Server Enterprise (full installation)"; break; }
				11 { "Starter"; break; }
				12 { "Server Datacenter (core installation)"; break; }
				13 { "Server Standard (core installation)"; break; }
				14 { "Server Enterprise (core installation)"; break; }
				15 { "Server Enterprise for Itanium-based Systems"; break; }
				16 { "Business N"; break; }
				17 { "Web Server (full installation)"; break; }
				18 { "HPC Edition"; break; }
				19 { "Windows Storage Server 2008 R2 Essentials"; break; }
				20 { "Storage Server Express"; break; }
				21 { "Storage Server Standard"; break; }
				22 { "Storage Server Workgroup"; break; }
				23 { "Storage Server Enterprise"; break; }
				24 { "Windows Server 2008 for Windows Essential Server Solutions"; break; }
				25 { "Small Business Server Premium"; break; }
				26 { "Home Premium N"; break; }
				27 { "Enterprise N"; break; }
				28 { "Ultimate N"; break; }
				29 { "Web Server (core installation)"; break; }
				30 { "Windows Essential Business Server Management Server"; break; }
				31 { "Windows Essential Business Server Security Server"; break; }
				32 { "Windows Essential Business Server Messaging Server"; break; }
				33 { "Server Foundation"; break; }
				34 { "Windows Home Server 2011"; break; }
				35 { "Windows Server 2008 without Hyper-V for Windows Essential Server Solutions"; break; }
				36 { "Server Standard without Hyper-V"; break; }
				37 { "Server Datacenter without Hyper-V (full installation)"; break; }
				38 { "Server Enterprise without Hyper-V (full installation)"; break; }
				39 { "Server Datacenter without Hyper-V (core installation)"; break; }
				40 { "Server Standard without Hyper-V (core installation)"; break; }
				41 { "Server Enterprise without Hyper-V (core installation)"; break; }
				42 { "Microsoft Hyper-V Server"; break; }
				43 { "Storage Server Express (core installation)"; break; }
				44 { "Storage Server Standard (core installation)"; break; }
				45 { "Storage Server Workgroup (core installation)"; break; }
				46 { "Storage Server Enterprise (core installation)"; break; }
				46 { "Storage Server Enterprise (core installation)"; break; }
				47 { "Starter N"; break; }
				48 { "Professional"; break; }
				49 { "Professional N"; break; }
				50 { "Windows Small Business Server 2011 Essentials"; break; }
				51 { "Server For SB Solutions"; break; }
				52 { "Server Solutions Premium"; break; }
				53 { "Server Solutions Premium (core installation)"; break; }
				54 { "Server For SB Solutions EM"; break; }
				55 { "Server For SB Solutions EM"; break; }
				56 { "Windows MultiPoint Server"; break; }
				59 { "Windows Essential Server Solution Management"; break; }
				60 { "Windows Essential Server Solution Additional"; break; }
				61 { "Windows Essential Server Solution Management SVC"; break; }
				62 { "Windows Essential Server Solution Additional SVC"; break; }
				63 { "Small Business Server Premium (core installation)"; break; }
				64 { "Server Hyper Core V"; break; }
				72 { "Server Enterprise (evaluation installation)"; break; }
				76 { "Windows MultiPoint Server Standard (full installation)"; break; }
				77 { "Windows MultiPoint Server Premium (full installation)"; break; }
				79 { "Server Standard (evaluation installation)"; break; }
				80 { "Server Datacenter (evaluation installation)"; break; }
				84 { "Enterprise N (evaluation installation)"; break; }
				87 { "Windows Thin PC"; break }
				89 { "Windows Embedded Industry"; break }
				95 { "Storage Server Workgroup (evaluation installation)"; break; }
				96 { "Storage Server Standard (evaluation installation)"; break; }
				97 { "Windows RT"; break }
				98 { "Windows 8 N"; break; }
				99 { "Windows 8 China"; break; }
				100 { "Windows 8 Single Language"; break; }
				101 { "Windows 8"; break; }
				103 { "Professional with Media Center"; break; }
				104 { "Windows Mobile" }
				118 { "Windows Embedded Handheld"; break }
				121 { "Windows 10 Education"; break }
				123 { "Windows IoT (Internet of Things) Core"; break }
				164 { "Windows 10 Pro Education"; break }
				default
				{
					Write-Error -Category ObjectNotFound -TargetObject $CimSKU `
						-Message "Unknown SKU: $($CimSKU.ToString())"
				}
			} # switch SKU
		}
	}
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "Number")
		{
			[PSCustomObject] @{
				Domain = $null
				SystemSKU = & $GetStringSKU $SKU
				SKU = $SKU
			}
		}
		else
		{
			if ($PSCmdlet.ParameterSetName -eq "CimSession")
			{
				$Domain = $CimSession.ComputerName
				$CimParams.CimSession = $CimSession
			}

			foreach ($Computer in $Domain)
			{
				$MachineName = Format-ComputerName $Computer
				if ($PSCmdlet.ParameterSetName -eq "Domain")
				{
					$CimParams.ComputerName = $MachineName
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing computer: $MachineName"

				if (Test-Computer $MachineName)
				{
					try
					{
						$CimSKU = Get-CimInstance @CimParams |
						Select-Object -ExpandProperty OperatingSystemSku

						[PSCustomObject] @{
							Domain = $MachineName
							SystemSKU = & $GetStringSKU $CimSKU
							SKU = $CimSKU
						}
					}
					catch
					{
						Write-Error -ErrorRecord $_

						# Include just computer
						[PSCustomObject] @{
							Domain = $MachineName
							SystemSKU = $null
							SKU = $null
						}
					}
				}
			} # foreach computer
		}
	} # process
}

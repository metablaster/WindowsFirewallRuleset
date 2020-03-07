
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

# Includes
. $PSScriptRoot\External\Get-TypeName.ps1

<#
.SYNOPSIS
Update context for Approve-Execute function
.DESCRIPTION
Execution context is shown in the console every time Approve-Execute is called.
It helps to know the state and progress of execution.
.PARAMETER Root
First context string before . (dot)
.PARAMETER Section
Second context string after . (dot)
.PARAMETER Subsection
Additional string after -> (arrow)
.EXAMPLE
Update-Context "IPv4" "Outbound" "RuleGroup"

[IPv4.Outbound -> RuleGroup]
.INPUTS
None. You cannot pipe objects to Update-Context
.OUTPUTS
None. Script scope context variable is updated.
.NOTES
None.
#>
function Update-Context
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Root,

		[Parameter(Mandatory = $true)]
		[string] $Section,

		[Parameter(Mandatory = $false)]
		[string] $Subsection = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting context"

	$NewContext = $Root + "." + $Section
	if (![System.String]::IsNullOrEmpty($Subsection))
	{
		$NewContext += " -> " + $Subsection
	}

	Set-Variable -Name Context -Scope Script -Value $NewContext
	Write-Debug -Message "Context set to '$NewContext'"
}

<#
.SYNOPSIS
Used to ask user if he wants to run script
.DESCRIPTION
In addition to prompt, execution context is shown.
Asking for approval helps to let run master script and only execute specific
scripts, thus loading only needed rules.
.PARAMETER DefaultAction
Default prompt action, either 'YES' or 'NO'
.PARAMETER Title
Title of the prompt
.PARAMETER Question
Prompt question
.EXAMPLE
Approve-Execute "No" "Sample title" "Sample question"
.INPUTS
None. You cannot pipe objects to Approve-Execute
.OUTPUTS
None. true if user wants to continue, false otherwise
.NOTES
TODO: implement help [?]
TODO: make this function more generic
#>
function Approve-Execute
{
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[ValidateSet("Yes", "No")]
		[string] $DefaultAction = "Yes",

		[Parameter(Mandatory = $false)]
		[string] $Title = "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName),

		[Parameter(Mandatory = $false)]
		[string] $Question = "Do you want to run this script?"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Default action is: $DefaultAction"

	$Choices = "&Yes", "&No"
	$Default = 0
	if ($DefaultAction -like "No")
	{
		$Default = 1
	}

	$Title += " [$Context]"
	$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

	if ($Decision -eq $Default)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] User choose default action"
		return $true
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] User refuses default action"
	return $false
}

<#
.SYNOPSIS
Show-SDDL returns SDDL based on "object" such as path, or registry entry
.DESCRIPTION
TODO: add description
.EXAMPLE
see Test\Show-SDDL.ps1 for example
.INPUTS
None. You cannot pipe objects to Show-SDDL
.OUTPUTS
TODO: describe outputs
.NOTES
This function is used only for debugging and discovery of object SDDL
Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1
TODO: additional work on function to make it more universal, see if we can make use of it somehow, better help comment.
#>
function Show-SDDL
{
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipelineByPropertyName = $true)]
		$SDDL
	)

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

<#
.SYNOPSIS
Convert SDDL entries to computer accounts
.DESCRIPTION
TODO: add description
.PARAMETER SDDL
String array of one or more strings of SDDL syntax
.EXAMPLE
Convert-SDDLToACL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
.INPUTS
None. You cannot pipe objects to Convert-SDDLToACL
.OUTPUTS
[string[]] Array of computer accounts
.NOTES
None.
#>
function Convert-SDDLToACL
{
	[OutputType([string[]])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $SDDL
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string[]] $ACL = @()
	foreach ($Entry in $SDDL)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing $Entry"

		$ACLObject = New-Object -TypeName Security.AccessControl.DirectorySecurity
		$ACLObject.SetSecurityDescriptorSddlForm($Entry)
		$ACL += $ACLObject.Access | Select-Object -ExpandProperty IdentityReference |
		Select-Object -ExpandProperty Value
	}

	return $ACL
}

<#
.SYNOPSIS
Scan all scripts in this repository and get windows service names involved in rules
.PARAMETER Folder
Root folder name which to scan recursively
.EXAMPLE
Get-NetworkServices "C:\PathToRepo"
.INPUTS
None. You cannot pipe objects to Get-NetworkServices
.OUTPUTS
None, File with the list of services is made
.NOTES
None.
#>
function Get-NetworkServices
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Folder
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Scanning rules for network services"

	if (!(Test-Path -Path $Folder))
	{
		Write-Warning -Message "Unable to locate path '$Folder'"
		return
	}

	# Recursively get powershell scripts in input folder
	$Files = Get-ChildItem -Path $Folder -Recurse -Filter *.ps1
	if (!$Files)
	{
		Write-Warning -Message "No powershell script files found in '$Folder'"
		return
	}

	$Content = @()
	# Filter out service names from each powershell file in input folder
	$Files | ForEach-Object {
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading file: $($_.FullName)"
		Get-Content $_.FullName | Where-Object {
			if ($_ -match "(?<= -Service )(.*)(?= -Program)")
			{
				$Content += $Matches[0]
			}
		}
	}

	if (!$Content)
	{
		Write-Warning -Message "No matches found in any of the rules"
		return
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rid of duplicate matches and known bad values"
	$Content = $Content | Select-Object -Unique
	$Content = $Content | Where-Object { $_ -ne '$Service' -and $_ -ne "Any" -and $_ -ne '"*"' }

	# File name where to save all matches
	$File = "$ProjectRoot\Rules\NetworkServices.txt"

	# If output file exists clear it, otherwise create a new file
	if (Test-Path -Path $File)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Clearing file: $File"
		Clear-Content -Path $File
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating file: $File"
		New-Item -ItemType File -Path $File | Out-Null
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing filtered services to: $File"
	Add-Content -Path $File -Value $Content

	Write-Information -Tags "Project" -MessageData "INFO: $($Content.Count) services involved in firewall rules"
}

<#
.SYNOPSIS
Format firewall rule output for display
.DESCRIPTION
Output of Net-NewFirewallRule is large, loading a lot of rules would spam the console
very fast, this function helps to output only relevant content.
.PARAMETER Rule
Firewall rule to format
.EXAMPLE
Net-NewFirewallRule ... | Format-Output
.INPUTS
Microsoft.Management.Infrastructure.CimInstance Firewall rule to format
.OUTPUTS
None. Formatted and colored output
.NOTES
None.
#>
function Format-Output
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'There is no way to replace Write-Host here')]
	[OutputType([System.Void])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[Microsoft.Management.Infrastructure.CimInstance] $Rule
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Host "Load Rule: [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
}

<#
.SYNOPSIS
Set vertical screen buffer to recommended value
.DESCRIPTION
In some cases, depending on project settings a user may need larger buffer
to preserve all the output in the console for review and scroll back.
.EXAMPLE
Set-ScreenBuffer
.INPUTS
None. You cannot pipe objects to Set-ScreenBuffer
.OUTPUTS
None, Screen buffer is set for current powershell session
.NOTES
None.
#>
function Set-ScreenBuffer
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$psHost = Get-Host
	$psWindow = $psHost.UI.RawUI
	$NewSize = $psWindow.BufferSize

	$NewBuffer = (Get-Variable -Name RecommendedBuffer -Scope Script).Value

	if ($NewSize.Height -lt $NewBuffer)
	{
		Write-Warning -Message "Your screen buffer of $($NewSize.Height) is below recommended $NewBuffer to preserve all execution output"

		$Choices = "&Yes", "&No"
		$Default = 0
		$Title = "Increase Screen Buffer"
		$Question = "Would you like to increase screen buffer to $($NewBuffer)?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			$NewSize.Height = $NewBuffer
			$psWindow.BufferSize = $NewSize
			Write-Information -Tags "User" -MessageData "INFO: Screen buffer changed to $NewBuffer"
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting screen buffer canceled"
		return
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Screen buffer check OK"
}

<#
.SYNOPSIS
Test target computer (policy store) on which to apply firewall
.DESCRIPTION
The purpose of this function is to reduce typing checks depending on whether PowerShell
core or desktop edition is used, since parameters for Test-Connection are not the same
for both PowerShell editions.
.PARAMETER ComputerName
Target computer which to test
.PARAMETER ConnectionCount
Valid only for PowerShell Core. Specifies the number of echo requests to send. The default value is 4
.PARAMETER ConnectionTimeout
Valid only for PowerShell Core. The test fails if a response isn't received before the timeout expires
.EXAMPLE
Test-TargetComputer "COMPUTERNAME" 2 1
.EXAMPLE
Test-TargetComputer "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Test-TargetMachine
.OUTPUTS
[bool] false or true if target host is responsive
.NOTES
None.
#>
function Test-TargetComputer
{
	[OutputType([System.Boolean])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(Mandatory = $true,
			Position = 0)]
		[string] $ComputerName,

		[Parameter()]
		[int16] $Count = $ConnectionCount,

		[Parameter()]
		[int16] $Timeout = $ConnectionTimeout
	)

	# Test parameters depend on PowerShell edition
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		return Test-Connection -TargetName $ComputerName -Count $Count -TimeoutSeconds $Timeout -IPv4 -Quiet
	}

	return Test-Connection -ComputerName $ComputerName -Count $Count -Quiet
}

#
# Module variables
#

if (!(Get-Variable -Name CheckInitUtility -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant: CheckInitUtility"
	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUtility -Scope Global -Option Constant -Value $null

	Write-Debug -Message "[$ThisModule] Initialize global constant: ServiceHost"
	# Most used program
	New-Variable -Name ServiceHost -Scope Global -Option Constant -Value "%SystemRoot%\System32\svchost.exe"
}

Write-Debug -Message "[$ThisModule] Initialize module variable: Context"
# Global execution context, used in Approve-Execute
New-Variable -Name Context -Scope Script -Value "Context not set"

Write-Debug -Message "[$ThisModule] Initialize module variable: RecommendedBuffer"
# Recommended vertical screen buffer value, to ensure user can scroll back all the output
New-Variable -Name RecommendedBuffer -Scope Script -Option Constant -Value 1500

# TODO: where to export? here or in manifest file?

#
# Function exports
#

Export-ModuleMember -Function Approve-Execute
Export-ModuleMember -Function Update-Context
Export-ModuleMember -Function Convert-SDDLToACL
Export-ModuleMember -Function Show-SDDL
Export-ModuleMember -Function Get-NetworkServices
Export-ModuleMember -Function Format-Output
Export-ModuleMember -Function Set-ScreenBuffer
Export-ModuleMember -Function Test-TargetComputer

#
# External function exports
#

Export-ModuleMember -Function Get-TypeName

#
# Variable exports
#

Export-ModuleMember -Variable ServiceHost
Export-ModuleMember -Variable CheckInitUtility

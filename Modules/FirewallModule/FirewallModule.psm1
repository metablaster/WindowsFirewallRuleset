
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

<#
.SYNOPSIS
update context for Approve-Execute function
.PARAMETER Root
First context string before . (dot)
.PARAMETER Section
Second context string after . (dot)
.PARAMETER Subsection
Additional string after -> (arrow)
.EXAMPLE
Update-Context "IPv4" "Outbound" "RuleGroup"
.INPUTS
None. You cannot pipe objects to Update-Context
.OUTPUTS
Note, script scope variable is updated
#>
function Update-Context
{
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Root,

		[Parameter(Mandatory = $true, Position = 1)]
		[string] $Section,

		[Parameter(Mandatory = $false, Position = 2)]
		[string] $Subsection = $null
	)

	$NewContext = $Root + "." + $Section
	if (![System.String]::IsNullOrEmpty($Subsection))
	{
		$NewContext += " -> " + $Subsection
	}

	Set-Variable -Name Context -Scope Script -Value $NewContext
	Write-Debug "Context set to '$NewContext'"
}

<#
.SYNOPSIS
Used to ask user if he wants to run script
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
true if user wants to continue, false otherwise
.NOTES
TODO: implement help [?]
TODO: make this function more generic
#>
function Approve-Execute
{
	param (
		[Parameter(Mandatory = $false)]
		[ValidateSet("Yes", "No")]
		[string] $DefaultAction = "Yes",

		[Parameter(Mandatory = $false)]
		[string] $Title = "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName),

		[Parameter(Mandatory = $false)]
		[string] $Question = "Do you want to run this script?"
	)

	$Choices  = "&Yes", "&No"
	$Default = 0
	if ($DefaultAction -like "No") { $Default = 1 }

	$Title += " [$Context]"
	$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

	return $Decision -eq $Default
}

<#
.SYNOPSIS
Show-SDDL returns SDDL based on "object" such as path, or registry entry
.EXAMPLE
see Test\Show-SDDL.ps1 for example
.INPUTS
None. You cannot pipe objects to Show-SDDL
.NOTES
This function is used only for debugging and discovery of object SDDL
Credits to: https://blogs.technet.microsoft.com/ashleymcglone/2011/08/29/powershell-sid-walker-texas-ranger-part-1
#>
function Show-SDDL
{
	param (
		[Parameter(
			Mandatory = $true,
			valueFromPipelineByPropertyName=$true)] $SDDL
	)

	$SDDLSplit = $SDDL.Split("(")

	Write-Host ""
	Write-Host "SDDL Split:"
	Write-Host "****************"

	$SDDLSplit

	Write-Host ""
	Write-Host "SDDL SID Parsing:"
	Write-Host "****************"

	# Skip index 0 where owner and/or primary group are stored
	for ($i=1;$i -lt $SDDLSplit.Length;$i++)
	{
		$ACLSplit = $SDDLSplit[$i].Split(";")

		if ($ACLSplit[1].Contains("ID"))
		{
			"Inherited"
		}
		else
		{
			$ACLEntrySID = $null

			# Remove the trailing ")"
			$ACLEntry = $ACLSplit[5].TrimEnd(")")

			# Parse out the SID using a handy RegEx
			$ACLEntrySIDMatches = [regex]::Matches($ACLEntry,"(S(-\d+){2,8})")
			# NOTE: original changed from $ACLEntrySID = $_.value to $ACLEntrySID += $_.value
			$ACLEntrySIDMatches | ForEach-Object { $ACLEntrySID += $_.value }

			If ($ACLEntrySID)
			{
				$ACLEntrySID
			}
			Else
			{
				"Not inherited - No SID"
			}
		}
	}

	return $null
}

<#
.SYNOPSIS
Convert SDDL entries to computer accounts
.PARAMETER SDDL
String array of one or more strings of SDDL syntax
.EXAMPLE
Convert-SDDLToACL $SDDL1, $SDDL2
.INPUTS
None. You cannot pipe objects to Convert-SDDLToACL
.OUTPUTS
System.String[] array of computer accounts
#>
function Convert-SDDLToACL
{
	param (
		[parameter(Mandatory = $true)]
		[ValidateCount(1, 1000)]
		[ValidateLength(1, 1000)]
		[string[]] $SDDL
	)

	[string[]] $ACL = @()
	foreach ($Entry in $SDDL)
	{
		$ACLObject = New-Object -Type Security.AccessControl.DirectorySecurity
		$ACLObject.SetSecurityDescriptorSddlForm($Entry)
		$ACL += $ACLObject.Access | Select-Object -ExpandProperty IdentityReference | Select-Object -ExpandProperty Value
	}

	return $ACL
}

<#
.SYNOPSIS
Write informational note with 'NOTE:' label and green text
.PARAMETER Notes
string array to write
.EXAMPLE
Write-Note "sample note"
.EXAMPLE
Write-Note "first line", "second line"
.EXAMPLE
Write-Note @(
	"first line"
	"second line"
	"3rd line")
.INPUTS
None. You cannot pipe objects to Write-Note
.OUTPUTS
Formatted note is shown in console on single or multiple lines in form of: NOTE: sample note
.NOTES
TODO: rename to Info
#>
function Write-Note
{
	param (
		[parameter(Mandatory = $true)]
		[string[]] $Notes
	)

	Write-Host "NOTE: $($Notes[0])" -ForegroundColor Green -BackgroundColor Black

	# Skip 'NOTE:' tag for all subsequent messages
	for ($Index = 1; $Index -lt $Notes.Count; ++$Index)
	{
		Write-Host $Notes[$Index] -ForegroundColor Green -BackgroundColor Black
	}
}

<#
.SYNOPSIS
Custom Write-Warning which also sets global warning status
.PARAMETER Message
string to write to console
.PARAMETER Status
boolean to tell if warning status should be updated
.EXAMPLE
Set-Warning "sample warning"
.EXAMPLE
Set-Warning "sample warning" $false
.INPUTS
None. You cannot pipe objects to Set-Warning
.OUTPUTS
Formatted warning message is shown in console in form of: WARNING: sample warning
#>
function Set-Warning
{
	param (
		[parameter(Mandatory = $true)]
		[string[]] $Message,
		[parameter(Mandatory = $false)]
		[bool] $Status = $true
	)

	# Update warning status variable
	Set-Variable -Name WarningStatus -Scope Global -Value ($WarningStatus -or $Status)

	# Append warning to log file
	$FileName = "Warning_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = "$LogsFolder\$FileName"

	if (!(Test-Path -PathType Container -Path $LogsFolder))
	{
		New-Item -ItemType Directory -Path $LogsFolder -ErrorAction Stop | Out-Null
	}

	if (!(Test-Path -PathType Leaf -Path $LogFile))
	{
		New-Item -ItemType File -Path $LogFile -ErrorAction Stop | Out-Null
	}

	# First line
	$LineOne = $Message[0]

	# Show the warning and save to log file
	$Warning = "WARNING: $LineOne"
	Write-Host $Warning -ForegroundColor Yellow -BackgroundColor Black

	# Include time in file
	$Warning = "WARNING: $(Get-Date -Format "HH:mm")h $LineOne"
	Add-Content -Path $LogFile -Value $Warning

	# Skip 'WARNING:' tag for all subsequent lines (both console and log file)
	for ($Index = 1; $Index -lt $Message.Count; ++$Index)
	{
		Write-Host $Message[$Index] -ForegroundColor Yellow -BackgroundColor Black
		Add-Content -Path $LogFile -Value $Message[$Index]
	}
}

<#
.SYNOPSIS
list all generated errors and clear error variable
.EXAMPLE
Save-Errors
.INPUTS
None. You cannot pipe objects to Save-Errors
.OUTPUTS
None, list of all errors is logged into a file
#>
function Save-Errors
{
	if ($global:Error.Count -eq 0)
	{
		Write-Note "No errors detected"
		return
	}

	# Write all errors to log file
	$FileName = "Error_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = "$LogsFolder\$FileName"

	if (!(Test-Path -PathType Container -Path $LogsFolder))
	{
		New-Item -ItemType Directory -Path $LogsFolder -ErrorAction Stop| Out-Null
	}

	if (!(Test-Path -PathType Leaf -Path $LogFile))
	{
		New-Item -ItemType File -Path $LogFile -ErrorAction Stop| Out-Null
	}

	# Include time in file
	$Time = "$(Get-Date -Format "HH:mm")h"

	$AllErrors = @()
	foreach ($Err in $global:Error)
	{
		$AllErrors += "ERROR: $Time $Err`nSTACKTRACE: $($Err.ScriptStackTrace)`n"
	}

	Add-Content -Path $LogFile -Value $AllErrors
	Write-Note @("All errors were saved to:"
	$LogsFolder
	"you can review these logs to see which scripts need to be fixed and where")

	$global:Error.Clear()
}

<#
.SYNOPSIS
Scan all scripts in this repository and get windows service names involved in rules
.PARAMETER Folder
Root folder name which to scan
.EXAMPLE
Get-NetworkServices C:\PathToRepo
.INPUTS
None. You cannot pipe objects to Get-NetworkServices
.OUTPUTS
None, file with the list of services is made
#>
function Get-NetworkServices
{
	param (
		[parameter(Mandatory = $true)]
		[string] $Folder
	)

	if (!(Test-Path -Path $Folder))
	{
		Set-Warning "Unable to locate path '$Folder'"
		return
	}

	# Recusively get powershell scripts in input folder
	$Files = Get-ChildItem -Path $Folder -Recurse -Filter *.ps1
	if (!$Files)
	{
		Set-Warning "No powershell script files found in '$Folder'"
		return
	}

	$Content = @()
	# Filter out service names from each powershell file in input folder
	$Files | Foreach-Object {
		Get-Content $_.FullName | Where-Object {
			if ($_ -match "(?<= -Service )(.*)(?= -Program)")
			{
				$Content += $Matches[0]
			}
		}
	}

	if (!$Content)
	{
		Set-Warning "No matches found in any of the bellow files:"
		Write-Host "$($Files | Select-Object -ExpandProperty Name)"
		return
	}

	# Get rid of duplicate matches and known bad values
	$Content = $Content | Select-Object -Unique
	$Content = $Content | Where-Object { $_ -ne '$Service' -and $_ -ne "Any" }

	# File name where to save all matches
	$File = "$RepoDir\Rules\NetworkServices.txt"

	# If output file exists clear it
	# otherwise create a new file
	if (Test-Path -Path $File)
	{
		Clear-Content -Path $File
	}
	else
	{
		New-Item -ItemType File -Path $File| Out-Null
	}

	# Save filtered services to a new file
	Add-Content -Path $File -Value $Content
	Write-Note "$($Content.Count) services involved in firewall rules"
}

<#
.SYNOPSIS
format firewall rule output for display
.PARAMETER Rule
Firewall rule to format
.EXAMPLE
Net-NewFirewallRule ... | Format-Output
.INPUTS
Microsoft.Management.Infrastructure.CimInstance Firewall rule to format
.OUTPUTS
Formatted text
#>
function Format-Output
{
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true,
		ValueFromPipeline = $true)]
		[Microsoft.Management.Infrastructure.CimInstance] $Rule
	)

	process
	{
		Write-Host "Load Rule: [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
	}
}

<#
.SYNOPSIS
set vertical screen buffer to recommended value
.EXAMPLE
Set-ScreenBuffer
.INPUTS
None. You cannot pipe objects to Set-ScreenBuffer
.OUTPUTS
None, screen buffer is set for current powershell session
#>
function Set-ScreenBuffer
{
	$psHost = Get-Host
	$psWindow = $psHost.UI.RawUI
	$NewSize = $psWindow.BufferSize

	$NewBuffer = (Get-Variable -Name RecommendedBuffer -Scope Script).Value

	if ($NewSize.Height -lt $NewBuffer)
	{
		Write-Warning "Your screen buffer of $($NewSize.Height) is below recommended $NewBuffer to preserve all execution output"

		$Choices  = "&Yes", "&No"
		$Default = 0
		$Title = "Increase Screen Buffer"
		$Question = "Would you like to increase screen buffer to $($NewBuffer)?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			$NewSize.Height = $NewBuffer
			$psWindow.BufferSize = $NewSize
			Write-Note "Screen buffer changed to $NewBuffer"
		}
	}
}

#
# Module variables
#

if (!(Get-Variable -Name CheckInitFirewallModule -Scope Global -ErrorAction Ignore))
{
	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckInitFirewallModule -Scope Global -Option Constant -Value $null

	# Most used program
	New-Variable -Name ServiceHost -Scope Global -Option Constant -Value "%SystemRoot%\System32\svchost.exe"
}

# Global execution context, used in Approve-Execute
New-Variable -Name Context -Scope Script -Value "Context not set"
# Recommended vertical screen buffer value, to ensure user can scroll back all the output
New-Variable -Name RecommendedBuffer -Scope Script -Option Constant -Value 1500
# Folder where logs get saved
New-Variable -Name LogsFolder -Scope Script -Option Constant -Value ($RepoDir + "\Logs")

#
# Function exports
#

Export-ModuleMember -Function Approve-Execute
Export-ModuleMember -Function Update-Context
Export-ModuleMember -Function Convert-SDDLToACL
Export-ModuleMember -Function Show-SDDL
Export-ModuleMember -Function Write-Note
Export-ModuleMember -Function Get-NetworkServices
Export-ModuleMember -Function Format-Output
Export-ModuleMember -Function Save-Errors
Export-ModuleMember -Function Set-Warning
Export-ModuleMember -Function Set-ScreenBuffer

#
# Variable exports
#

Export-ModuleMember -Variable ServiceHost
Export-ModuleMember -Variable CheckInitFirewallModule

#
# Module preferences
#

if ($Develop)
{
	$DebugPreference = $ModuleDebugPreference
}


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

. $PSScriptRoot\..\..\Utility\Get-TypeName.ps1

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
Return a log file name for logging functions
.DESCRIPTION
Generates log file name composed of current date and time and log level label.
.PARAMETER Folder
[System.String] path to folder where to save logs
.PARAMETER FileLabel
[System.String] file label which preceeds file name
.EXAMPLE
Get-LogFile "C:\Logs" "Warning"
.INPUTS
None. You cannot pipe objects to Get-LogFile
.OUTPUTS
[System.String] full path to log file
.NOTES
TODO: Maybe a separate folder for each day?
#>
function Get-LogFile
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Folder,

		[Parameter(Mandatory = $true)]
		[string] $FileLabel
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	# Generate file name
	$FileName = $FileLabel + "_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = Join-Path -Path $Folder -ChildPath $FileName

	# Create Logs directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log directory $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Logs folder is: $Folder"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending $FileLabel to log file: $FileName"

	return $LogFile
}

<#
.SYNOPSIS
Log generated error and set global error status
.DESCRIPTION
Resume-Error takes error record stream which is shown in the console
and optionally logged into a file.
Gobal error status variable is set to true or optionally left alone.
.PARAMETER Stream
[System.Management.Automation.ErrorRecord] stream
.PARAMETER Preference
[System.Management.Automation.ActionPreference] ErrorActionPreference
.PARAMETER Folder
[System.String] path to folder on either C or D drive where to save logs
.PARAMETER Log
[switch] to control if the error should be logged to file
.EXAMPLE
Write-Error -Message "sample message" 2>&1 | Resume-Error -Log
.EXAMPLE
Write-Error -Message "sample message" 2>&1 | Resume-Error -Folder "C:\Logs" -Log
.INPUTS
[System.Management.Automation.ErrorRecord] Error record stream
.OUTPUTS
None.
.NOTES
TODO: Pass error variable to avoid pipeline?
TODO: [ValidateNotNullOrEmpty()] does not work
#>
function Resume-Error
{
	[CmdletBinding(PositionalBinding = $false)]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be ErrorRecord")]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.ErrorRecord] $Stream,

		[Parameter(Mandatory = $true,
		HelpMessage = "Error action preference")]
		[System.Management.Automation.ActionPreference] $Preference,

		[Parameter()]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $Log
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting error status variable"
			Set-Variable -Name ErrorStatus -Scope Global -Value $true

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write error to terminal"
			$Stream
		}

		if ($Log)
		{
			$LogFile = Get-LogFile $Folder "Error"

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write error to log file"
			$Stream | Select-Object * | Out-File -Append -FilePath $LogFile
		}
	}
}

<#
.SYNOPSIS
Log generated warnings and set global warning status
.DESCRIPTION
Resume-Warning takes warning record stream which is shown in the console
and optionally logged into a file.
Gobal warning status variable is set to true or optionally left alone.
.PARAMETER Stream
[System.Management.Automation.WarningRecord] stream
.PARAMETER Preference
[System.Management.Automation.ActionPreference] WarningPreference
.PARAMETER Folder
[System.String] path to folder on either C or D drive where to save logs
.PARAMETER NoStatus
[switch] to tell if updating global warning status variable should be skipped.
This global variable will help tell if warnings were generated.
.PARAMETER Log
[switch] to control if the warning should be logged to file
.EXAMPLE
Write-Warning -Message "sample message" 3>&1 | Resume-Warning -NoStatus -Log
.EXAMPLE
Write-Warning -Message "sample message" 3>&1 | Resume-Warning -Folder "C:\Logs" -Log
.INPUTS
[System.Management.Automation.WarningRecord] Warning record stream
.OUTPUTS
None.
.NOTES
TODO: Pass warning variable to avoid pipeline?
TODO: Stream parameter defines no type, otherwise warning is not colored and label is gone
TODO: [ValidateNotNullOrEmpty()] does not work
#>
function Resume-Warning
{
	[CmdletBinding(PositionalBinding = $false)]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be WarningRecord")]
		[ValidateNotNullOrEmpty()]
		# [System.Management.Automation.WarningRecord]
		$Stream,

		[Parameter(Mandatory = $true,
		HelpMessage = "Warning action preference")]
		[System.Management.Automation.ActionPreference] $Preference,

		[Parameter()]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $Log
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

		# NOTE: we have to add the WARNING label, it's gone for some reason
		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting warning status variable"
			Set-Variable -Name WarningStatus -Scope Global -Value $true

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write warning to terminal"
			$Stream
		}

		if ($Log)
		{
			$LogFile = Get-LogFile $Folder "Warning"

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write warning to log file"
			"WARNING: $(Get-Date -Format "HH:mm:ss") $Stream" | Out-File -Append -FilePath $LogFile
		}
	}
}

<#
.SYNOPSIS
Log generated information
.DESCRIPTION
Resume-Info takes Information record stream which is shown in the console
and logged into a file.
.PARAMETER Stream
[System.Management.Automation.InformationRecord] stream
.PARAMETER Preference
[System.Management.Automation.ActionPreference] InformationPreference
.PARAMETER Folder
[System.String] path to folder on either C or D drive where to save logs
.EXAMPLE
Write-Information -MessageData "sample info" -Tags MyTag 6>&1 | Resume-Info
.INPUTS
[System.Management.Automation.InformationRecord] Information record stream
.OUTPUTS
None.
.NOTES
TODO: Pass infomration variable to avoid pipeline?
TODO: [ValidateNotNullOrEmpty()] does not work
#>
function Resume-Info
{
	[CmdletBinding(PositionalBinding = $false)]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be InformationRecord")]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.InformationRecord] $Stream,

		[Parameter(Mandatory = $true,
		HelpMessage = "Information action preference")]
		[System.Management.Automation.ActionPreference] $Preference,

		[Parameter()]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $Log
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write information to terminal"
			"INFO: " + $Stream
		}

		if ($Log)
		{
			$LogFile = Get-LogFile $Folder "Info"

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write information to log file"
			$Stream | Select-Object * | Out-File -Append -FilePath $LogFile
		}
	}
}

<#
.SYNOPSIS
Log and format errors, warnings and infos generated by advanced functions
.DESCRIPTION
Advanced functions are first given "@Commons" splating for 6 common parameters, which are then filled with streams.
Write-Log is called right afterwards and it reads error, warning and information stream records generated by advaned functions,
Write-Log forwards these records to apprpriate Resume-* handlers for formatting, status checking and logging into a file.
Error, Warning and info preferences and log switch can be overriden at any time and the Write-Log will pick up
those values automatically since both these variables and Write-Log are local to script.
.EXAMPLE
Some-Function @Commons
Write-Log

Another-Function @Commons
Write-Log
.EXAMPLE
Some-Function @Commons | Another-Function @Commons
Write-Log
.INPUTS
None. You cannot pipe objects to Write-Log
.OUTPUTS
None.
#>
function Write-Log
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading common parameters from caller space"
	$EV = $PSCmdlet.GetVariableValue('EV')
	$WV = $PSCmdlet.GetVariableValue('WV')
	$IV = $PSCmdlet.GetVariableValue('IV')

	if ($EV)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing ErrorVariable"
		$EV | Resume-Error -Log:$ErrorLogging -Preference $ErrorActionPreference
		$EV.Clear()
	}

	if ($WV)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing WarningVariable"

		# This is a workaround, since warning variable is missing the
		# WARNING label and coloring, reported bellow:
		# https://github.com/PowerShell/PowerShell/issues/11900
		$WV | Write-Warning -WarningAction "Continue" 3>&1 | Resume-Warning -Log:$WarningLogging -Preference $WarningPreference
		$WV.Clear()
	}

	if ($IV)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing InformationVariable"
		$IV | Resume-Info -Log:$InformationLogging -Preference $InformationPreference
		$IV.Clear()
	}
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
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[string] $Folder
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	if (!(Test-Path -Path $Folder))
	{
		Write-Warning -Message "Unable to locate path '$Folder'"
		return
	}

	# Recusively get powershell scripts in input folder
	$Files = Get-ChildItem -Path $Folder -Recurse -Filter *.ps1
	if (!$Files)
	{
		Write-Warning -Message "No powershell script files found in '$Folder'"
		return
	}

	$Content = @()
	# Filter out service names from each powershell file in input folder
	$Files | Foreach-Object {
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
		Write-Warning -Message "No matches found in any of the bellow files:"
		Write-Host "$($Files | Select-Object -ExpandProperty Name)"
		return
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rid of duplicate matches and known bad values"
	$Content = $Content | Select-Object -Unique
	$Content = $Content | Where-Object { $_ -ne '$Service' -and $_ -ne "Any" -and $_ -ne '"*"' }

	# File name where to save all matches
	$File = "$RepoDir\Rules\NetworkServices.txt"

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

	Write-Information -MessageData "[$($MyInvocation.InvocationName)] $($Content.Count) services involved in firewall rules"
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
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	$psHost = Get-Host
	$psWindow = $psHost.UI.RawUI
	$NewSize = $psWindow.BufferSize

	$NewBuffer = (Get-Variable -Name RecommendedBuffer -Scope Script).Value

	if ($NewSize.Height -lt $NewBuffer)
	{
		# TODO: $PSBoundParameters.Keys. check it's not @Commons
		# NOTE: this message must go out now
		Write-Warning -Message "Your screen buffer of $($NewSize.Height) is below recommended $NewBuffer to preserve all execution output" `
		-WarningAction "Continue" 3>&1 | Resume-Warning -Log:$WarningLogging -Preference $PSCmdlet.GetVariableValue('WarningPreference')

		$Choices  = "&Yes", "&No"
		$Default = 0
		$Title = "Increase Screen Buffer"
		$Question = "Would you like to increase screen buffer to $($NewBuffer)?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			$NewSize.Height = $NewBuffer
			$psWindow.BufferSize = $NewSize
			Write-Information -MessageData "Screen buffer changed to $NewBuffer"
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting screen buffer canceled"
		return
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Screen buffer check OK"
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

	# These defaults are for advanced functions to enable logging, do not modify!
	Set-Variable -Name Commons -Scope Global -Option Constant -Value @{
		ErrorAction = "SilentlyContinue"
		ErrorVariable = "+EV"
		WarningAction = "SilentlyContinue"
		WarningVariable = "+WV"
		InformationAction = "SilentlyContinue"
		InformationVariable = "+IV"
	}
}

# Global variable to tell if errors were generated
# Will not be set if preference is "SilentlyContinue"
Set-Variable -Name ErrorStatus -Scope Global -Value $false

# Global variable to tell if warnings were generated
# Will not be set if preference is "SilentlyContinue"
Set-Variable -Name WarningStatus -Scope Global -Value $false

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
Export-ModuleMember -Function Get-NetworkServices
Export-ModuleMember -Function Format-Output
Export-ModuleMember -Function Resume-Error
Export-ModuleMember -Function Resume-Warning
Export-ModuleMember -Function Resume-Info
Export-ModuleMember -Function Set-ScreenBuffer
Export-ModuleMember -Function Get-TypeName
Export-ModuleMember -Function Write-Log

#
# Variable exports
#

Export-ModuleMember -Variable ServiceHost
Export-ModuleMember -Variable CheckInitFirewallModule
Export-ModuleMember -Variable Commons

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
}

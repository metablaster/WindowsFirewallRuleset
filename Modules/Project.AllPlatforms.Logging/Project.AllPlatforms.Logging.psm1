
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

# TODO: let Write-Log select object in piple, process it's commons and transfer down the pipe
# TODO: stream logging instead of open/close file for performance
# TODO: what if cmdlet throws? will we capture that into log?

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

#
# Module variables
#

if (!(Get-Variable -Name CheckInitLogging -Scope Global -ErrorAction Ignore))
{
	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckInitLogging -Scope Global -Option Constant -Value $null

	# These defaults are for advanced functions to enable logging, do not modify!
	New-Variable -Name Commons -Scope Global -Option Constant -Value @{
		ErrorAction = "SilentlyContinue"
		ErrorVariable = "+EV"
		WarningAction = "SilentlyContinue"
		WarningVariable = "+WV"
		InformationAction = "SilentlyContinue"
		InformationVariable = "+IV"
	}
}

# TODO: set to script scope and get with functions?

# Global variable to tell if errors were generated
# Will not be set if preference is "SilentlyContinue"
Set-Variable -Name ErrorStatus -Scope Global -Value $false

# Global variable to tell if warnings were generated
# Will not be set if preference is "SilentlyContinue"
Set-Variable -Name WarningStatus -Scope Global -Value $false

# Folder where logs get saved
New-Variable -Name LogsFolder -Scope Script -Option Constant -Value ($RepoDir + "\Logs")

#
# Function exports
#

Export-ModuleMember -Function Resume-Error
Export-ModuleMember -Function Resume-Warning
Export-ModuleMember -Function Resume-Info
Export-ModuleMember -Function Write-Log

#
# Variable exports
#

Export-ModuleMember -Variable Commons
Export-ModuleMember -Variable ErrorStatus
Export-ModuleMember -Variable WarningStatus

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

	$ThisModule = $MyInvocation.MyCommand.Name -replace ".{5}$"

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

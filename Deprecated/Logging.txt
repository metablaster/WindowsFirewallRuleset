<#
.SYNOPSIS
Log generated error and set global error status
.DESCRIPTION
Resume-Error takes error record stream which is optionally logged into a file.
Gobal error status variable is set to true.
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
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting error status variable"
			Set-Variable -Name ErrorStatus -Scope Global -Value $true
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
Resume-Warning takes warning record stream which is optionally logged into a file.
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
TODO: [ValidateNotNullOrEmpty()] does not work
#>
function Resume-Warning
{
	[CmdletBinding(PositionalBinding = $false)]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be WarningRecord")]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.WarningRecord] $Stream,

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
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting warning status variable"
			Set-Variable -Name WarningStatus -Scope Global -Value $true
		}

		if ($Log)
		{
			$LogFile = Get-LogFile $Folder "Warning"

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write warning to log file"
			# NOTE: we have to add the WARNING label, it's not included in the message by design
			"WARNING: $(Get-Date -Format "HH:mm:ss") $Stream" | Out-File -Append -FilePath $LogFile
		}
	}
}

<#
.SYNOPSIS
Log generated information
.DESCRIPTION
Resume-Info takes Information record stream which is optionally logged into a file.
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

		[Parameter()]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $Log
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		if ($Log)
		{
			$LogFile = Get-LogFile $Folder "Info"

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Write information to log file"
			$Stream | Select-Object * | Out-File -Append -FilePath $LogFile
		}
	}
}

# Export-ModuleMember -Function Resume-Error
# Export-ModuleMember -Function Resume-Warning
# Export-ModuleMember -Function Resume-Info

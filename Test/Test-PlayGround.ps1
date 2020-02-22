
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

#
# Not an acctual unit test but a playground for testing stuff out
#
. $PSScriptRoot\..\Config\ProjectSettings.ps1

# # Check requirements for this project
# Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
# Test-SystemRequirements

# # Includes
# . $ProjectRoot\Test\ContextSetup.ps1
# Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ComputerInfo
# Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# # Ask user if he wants to load these rules
# Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
# if (!(Approve-Execute)) { exit }

# $ProjectRoot = "C:\Users\haxor\GitHub\WindowsFirewallRuleset"
New-Variable -Name LogsFolder -Scope Script -Option Constant -Value ($ProjectRoot + "\Logs")

function Resume-Error
{
	[CmdletBinding()]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be ErrorRecord")]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.ErrorRecord]
		$Stream,

		[Parameter(Position = 0)]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $Log
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Show the error and save to variable
	$Stream | Tee-Object -Variable Message

	# Update error status variable
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting error status variable"
	Set-Variable -Name ErrorStatus -Scope Global -Value $true

	if ($Log)
	{
		# Generate file name
		$FileName = "Error_$(Get-Date -Format "dd.MM.yy HH")h.log"
		$LogFile = "$Folder\$FileName"

		# Create Logs directory if it doesn't exist
		if (!(Test-Path -PathType Container -Path $Folder))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
			New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending error to log file: $FileName"

		# Show the error and append log to file
		$Message | Select-Object * |
		Out-File -Append -FilePath $LogFile
	}
}

function Resume-Warning
{
	[CmdletBinding()]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be WarningRecord")]
		[ValidateNotNullOrEmpty()]
		# [System.Management.Automation.WarningRecord]
		$Stream,

		[Parameter(Position = 0)]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder,

		[Parameter()]
		[switch] $NoStatus,

		[Parameter()]
		[switch] $Log
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Show the warning and save to variable
	$Stream | Tee-Object -Variable Message

	if ($NoStatus)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Warning status stays the same: $WarningStatus"
	}
	else
	{
		# Update warning status variable
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting warning status variable"
		Set-Variable -Name WarningStatus -Scope Global -Value $NoStatus
	}


	if ($Log)
	{
		# Generate file name
		$FileName = "Warning_$(Get-Date -Format "dd.MM.yy HH")h.log"
		$LogFile = "$Folder\$FileName"

		# Create Logs directory if it doesn't exist
		if (!(Test-Path -PathType Container -Path $Folder))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
			New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending warning to log file: $FileName"
		"WARNING: $(Get-Date -Format "HH:mm:ss") $Message" | Out-File -Append -FilePath $LogFile
	}
}

function Resume-Info
{
	[CmdletBinding()]
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
		HelpMessage = "Input object must be InformationRecord")]
		[System.Management.Automation.InformationRecord] $Stream,

		[Parameter(Position = 0)]
		[ValidateDrive("C", "D")]
		[string] $Folder = $LogsFolder
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Generate file name
	$FileName = "Info_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = "$Folder\$FileName"

	# Create Logs directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending information to log file: $FileName"

	# Show the information and append log to file
	"INFO:" + ($Stream | Select-Object * |
	Tee-Object -Append -FilePath $LogFile |
	Select-Object -ExpandProperty MessageData)
}

function superduper
{
	param (
		[string] $AddressFamily,
		[bool] $AddressFamily2
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)]"

	# [string] $ComputerName = "COMPUTERNAME"

	# Write-Error -Message "[$($MyInvocation.InvocationName)] sample message" -Category PermissionDenied `
	# -ErrorId SampleID -TargetObject $ComputerName 2>&1 | Resume-Error -Log

	Write-Warning -Message "[$($MyInvocation.InvocationName)] warning message" 3>&1 | Resume-Warning -NoStatus -Log

	# Write-Information -Tags "Test" -MessageData "INFO: sample info" `
	# -Tags Result 6>&1 | Resume-Info
}

$DebugPreference = "Continue"
$WarningPreference = "Continue"

superduper "IPv4" $false

# $Group = "Test - Multiple package users"
# $Profile = "Any"

# Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

# [int] $Choice = -1
# $Count = 2

# while ($Choice -lt 0 -or $Choice -gt $Count)
# {
# 	Write-Host "Input number"
# 	$Input = Read-Host

# 	if($Input -notmatch '^-?\d+$')
# 	{
# 		Write-Host "Digits only please!"
# 		continue
# 	}

# 	$Choice = $Input
# }

# New-Test "Test all aps for Admins"
# $OwnerSID1 = Get-UserSID "Admin"
# $OwnerSID2 = Get-UserSID "User"

# looks like not possible to combine rules
# New-NetFirewallRule -Platform $Platform `
# -DisplayName "All store apps" -Program Any -Service Any `
# -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -LocalUser Any -Owner @($OwnerSID1, $OwnerSID2) -Package "*" `
# -Description "" | Format-Output

# Exit-Test

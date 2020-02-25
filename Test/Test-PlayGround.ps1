
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
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ComputerInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

# $ProjectRoot = "C:\Users\haxor\GitHub\WindowsFirewallRuleset"
# New-Variable -Name LogsFolder -Scope Script -Option Constant -Value ($ProjectRoot + "\Logs")

# function Resume-Error
# {
# 	[CmdletBinding()]
#     param (
# 		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
# 		HelpMessage = "Input object must be ErrorRecord")]
# 		[ValidateNotNullOrEmpty()]
# 		[System.Management.Automation.ErrorRecord]
# 		$Stream,

# 		[Parameter(Position = 0)]
# 		[ValidateDrive("C", "D")]
# 		[string] $Folder = $LogsFolder,

# 		[Parameter()]
# 		[switch] $Log
# 	)

# 	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

# 	# Show the error and save to variable
# 	$Stream | Tee-Object -Variable Message

# 	# Update error status variable
# 	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting error status variable"
# 	Set-Variable -Name ErrorStatus -Scope Global -Value $true

# 	if ($Log)
# 	{
# 		# Generate file name
# 		$FileName = "Error_$(Get-Date -Format "dd.MM.yy HH")h.log"
# 		$LogFile = "$Folder\$FileName"

# 		# Create Logs directory if it doesn't exist
# 		if (!(Test-Path -PathType Container -Path $Folder))
# 		{
# 			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
# 			New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
# 		}

# 		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending error to log file: $FileName"

# 		# Show the error and append log to file
# 		$Message | Select-Object * |
# 		Out-File -Append -FilePath $LogFile
# 	}
# }

# function Resume-Warning
# {
# 	[CmdletBinding()]
#     param (
# 		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
# 		HelpMessage = "Input object must be WarningRecord")]
# 		[ValidateNotNullOrEmpty()]
# 		# [System.Management.Automation.WarningRecord]
# 		$Stream,

# 		[Parameter(Position = 0)]
# 		[ValidateDrive("C", "D")]
# 		[string] $Folder = $LogsFolder,

# 		[Parameter()]
# 		[switch] $NoStatus,

# 		[Parameter()]
# 		[switch] $Log
# 	)

# 	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

# 	# Show the warning and save to variable
# 	$Stream | Tee-Object -Variable Message

# 	if ($NoStatus)
# 	{
# 		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Warning status stays the same: $WarningStatus"
# 	}
# 	else
# 	{
# 		# Update warning status variable
# 		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting warning status variable"
# 		Set-Variable -Name WarningStatus -Scope Global -Value $NoStatus
# 	}


# 	if ($Log)
# 	{
# 		# Generate file name
# 		$FileName = "Warning_$(Get-Date -Format "dd.MM.yy HH")h.log"
# 		$LogFile = "$Folder\$FileName"

# 		# Create Logs directory if it doesn't exist
# 		if (!(Test-Path -PathType Container -Path $Folder))
# 		{
# 			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
# 			New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
# 		}

# 		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending warning to log file: $FileName"
# 		"WARNING: $(Get-Date -Format "HH:mm:ss") $Message" | Out-File -Append -FilePath $LogFile
# 	}
# }

# function Resume-Info
# {
# 	[CmdletBinding()]
#     param (
# 		[Parameter(Mandatory = $true, ValueFromPipeline = $true,
# 		HelpMessage = "Input object must be InformationRecord")]
# 		[System.Management.Automation.InformationRecord] $Stream,

# 		[Parameter(Position = 0)]
# 		[ValidateDrive("C", "D")]
# 		[string] $Folder = $LogsFolder
# 	)

# 	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

# 	# Generate file name
# 	$FileName = "Info_$(Get-Date -Format "dd.MM.yy HH")h.log"
# 	$LogFile = "$Folder\$FileName"

# 	# Create Logs directory if it doesn't exist
# 	if (!(Test-Path -PathType Container -Path $Folder))
# 	{
# 		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory $Folder"
# 		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
# 	}

# 	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending information to log file: $FileName"

# 	# Show the information and append log to file
# 	"INFO:" + ($Stream | Select-Object * |
# 	Tee-Object -Append -FilePath $LogFile |
# 	Select-Object -ExpandProperty MessageData)
# }

# function superduper
# {
# 	param (
# 		[string] $AddressFamily,
# 		[bool] $AddressFamily2
# 	)

# 	Write-Debug -Message "[$($MyInvocation.InvocationName)]"

# 	# [string] $ComputerName = "COMPUTERNAME"

# 	# Write-Error -Message "[$($MyInvocation.InvocationName)] sample message" -Category PermissionDenied `
# 	# -ErrorId SampleID -TargetObject $ComputerName 2>&1 | Resume-Error -Log

# 	Write-Warning -Message "[$($MyInvocation.InvocationName)] warning message" 3>&1 | Resume-Warning -NoStatus -Log

# 	# Write-Information -Tags "Test" -MessageData "INFO: sample info" `
# 	# -Tags Result 6>&1 | Resume-Info
# }

# $DebugPreference = "Continue"
# $WarningPreference = "Continue"

# superduper "IPv4" $false

$Group = "Test - Multiple users SDDL"
$Profile = "Any"

Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

function Merge-SDDL
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ref] $SDDL1,

		[Parameter(Mandatory = $true)]
		[string] $SDDL2
	)

	$SDDL1.Value += $SDDL2.Substring(2)
}

function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Computer", "Machine")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true, ParameterSetName="Account")]
		[Parameter(Mandatory = $false, ParameterSetName="Group")]
		[string[]] $Users,

		[Alias("UserGroup", "UserGroups", "Group")]
		[Parameter(Mandatory = $true, ParameterSetName="Group")]
		[string[]] $Groups
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($User in $Users)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for account: $Domain\$User"

		$SID = Get-AccountSID $Domain $User
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	foreach ($Group in $Groups)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for group: $Group"

		$SID = Get-GroupSID $Group
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	return $SDDL
}

function Get-GroupSID
{
	[CmdletBinding()]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true)]
		[string] $UserGroup
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for user group: $UserGroup"

	return Get-LocalGroup -Name $UserGroup | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
}

function Get-AccountSID
{
	[CmdletBinding()]
	param (
		[Alias("Computer", "Machine")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true)]
		[string] $User
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $Domain\$User"
		$NTAccount = New-Object System.Security.Principal.NTAccount($Domain, $User)
		return $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
	}
	catch
	{
		Write-Error -TargetObject $_.TargetObject -Message "[$($MyInvocation.InvocationName)] Account '$Domain\$User' cannot be resolved to a SID."
	}
}

Start-Test
New-Test "Get-SDDL"
# "NT AUTHORITY\SYSTEM"
[string[]] $Users = @("")# @("haxor", "blah", "test")
[string] $Domain = [System.Environment]::MachineName
[string[]] $Groups = @("Users", "Administrators")
$UsersSDDL = Get-SDDL -Users $Users -Groups $Groups
$UsersSDDL

#

# $UsersSDDL = Get-SDDL -Groups $Groups
# $UsersSDDL

# $UsersSDDL = Get-SDDL -Users $Users -Groups $Groups
# $UsersSDDL

# $NewSDDL = Get-SDDL -Domain "NT AUTHORITY" -Users "System"
# Merge-SDDL ([ref] $UsersSDDL) $NewSDDL
# $UsersSDDL

# looks like not possible to combine rules
# New-NetFirewallRule -Platform $Platform `
# -DisplayName "Huzah" -Program Any -Service Any `
# -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -LocalUser $UsersSDDL `
# -Description "" | Format-Output


# New-Test "Test all aps for Admins"
# $OwnerSID1 = Get-UserSID "Admin"
# $OwnerSID2 = Get-UserSID "User"

# # looks like not possible to combine rules
# New-NetFirewallRule -Platform $Platform `
# -DisplayName "All store apps" -Program Any -Service Any `
# -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -LocalUser Any -Owner @($OwnerSID1, $OwnerSID2) -Package "*" `
# -Description "" | Format-Output

Exit-Test

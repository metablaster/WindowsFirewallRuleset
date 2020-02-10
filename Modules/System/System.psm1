
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# TODO: learn required NET version by scaning scripts
# TODO: learn repo dir automaticaly (using git?)
# TODO: check for iphelper service
# about: Test and print system requirements required for this project
# input: true or false to check or not to check
# output: error message and abort if check failed, system info otherwise
# sample: Test-SystemRequirements $true
function Test-SystemRequirements
{
    param (
        [parameter(Mandatory = $false)]
        [bool] $Check = $script:VersionCheck
    )

    # disabled when runing scripts from SetupFirewall.ps1 script
    if ($Check)
    {
        $OSPlatform = [System.Environment]::OSVersion.Platform
        $OSMajor = [System.Environment]::OSVersion.Version.Major
        $OSMinor = [System.Environment]::OSVersion.Version.Minor

        # Check operating system
        if (!($OSPlatform -eq "Win32NT" -and $OSMajor -ge 10))
        {
            Write-Host ""
            Write-Host "Unable to proceed, minimum required operating system is Win32NT 10.0 to run these scripts" -ForegroundColor Red -BackgroundColor Black
            Write-Host "Your operating system is: $OSPlatform $OSMajor.$OSMinor"
            Write-Host ""
            exit
        }

        $PowershellEdition = $PSVersionTable.PSEdition

        # Check Powershell edition
        if ($PowershellEdition -ne "Desktop")
        {
            Write-Host ""
            Write-Host "Unable to proceed, 'Desktop' edition of Powershell is required to run these scripts" -ForegroundColor Red -BackgroundColor Black
            Write-Host "Your Powershell edition is: $PowershellEdition"
            Write-Host ""
            exit
        }

        # Check Powershell version
        $PowershellMajor = $PSVersionTable.PSVersion | Select-Object -ExpandProperty Major
        $PowershellMinor = $PSVersionTable.PSVersion | Select-Object -ExpandProperty Minor

        $local:VersionStatus = $true
        switch ($PowershellMajor)
        {
            1 { $VersionStatus = $false }
            2 { $VersionStatus = $false }
            3 { $VersionStatus = $false }
            4 { $VersionStatus = $false }
            5 {
                if ($PowershellMinor -lt 1)
                {
                    $VersionStatus = $false
                }
            }
        }

        if (!$VersionStatus)
        {
            Write-Host ""
            Write-Host "Unable to proceed, minimum required Powershell required to run these scripts is: Desktop 5.1" -ForegroundColor Red -BackgroundColor Black
            Write-Host "Your Powershell version is: $PowershellEdition $PowershellMajor.$PowershellMinor"
            Write-Host ""
            exit
        }

        # Now that OS and Powershell is OK we can import these modules
        Import-Module -Name $RepoDir\Modules\ProgramInfo
        Import-Module -Name $RepoDir\Modules\ComputerInfo

        # Check NET Framework version
        $NETFramework = Get-NetFramework (Get-ComputerName)
        $Version = $NETFramework | Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version
        [int] $NETMajor, [int] $NETMinor, $NETBuild, $NETRevision = $Version.Split(".")

        switch ($NETMajor)
        {
            1 { $VersionStatus = $false }
            2 { $VersionStatus = $false }
            3 { $VersionStatus = $false }
            4 {
                if ($NETMinor -lt 8)
                {
                    $VersionStatus = $false
                }
            }
        }

        if (!$VersionStatus)
        {
            Write-Host ""
            Write-Host "Unable to proceed, minimum requried NET Framework version to run these scripts is 4.8" -ForegroundColor Red -BackgroundColor Black
            Write-Host "Your NET Framework version is: $NETMajor.$NETMinor"
            Write-Host ""
            exit
        }

        Write-Host ""
        Write-Host "System:`t`t $OSPlatform v$OSMajor.$OSMinor" -ForegroundColor Cyan
        Write-Host "Powershell:`t $PowershellEdition v$PowershellMajor.$PowershellMinor" -ForegroundColor Cyan
        Write-Host "NET Framework:`t v$NETMajor.$NETMinor" -ForegroundColor Cyan
        Write-Host ""
    }
}

#
# Module variables
#

# $DebugPreference = "Continue"

if (!(Get-Variable -Name CheckInitSystem -Scope Global -ErrorAction Ignore))
{
    # check if constants alreay initialized, used for module reloading
    New-Variable -Name CheckInitSystem -Scope Global -Option Constant -Value $null

    # Repository root directory
    New-Variable -Name RepoDir -Scope Global -Option Constant -Value (Resolve-Path -Path "$PSScriptRoot\..\.." | Select-Object -ExpandProperty Path)
}

# Set to false to avoid checking system requirements
New-Variable -Name VersionCheck -Scope Script -Option Constant -Value $false

#
# Function exports
#

Export-ModuleMember -Function Test-SystemRequirements

#
# Variable exports
#

# Realocating scripts should be easy if root directory is constant
Export-ModuleMember -Variable RepoDir

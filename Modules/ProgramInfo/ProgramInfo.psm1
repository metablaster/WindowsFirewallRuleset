
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

# about: get store app SID
# input: Username and "PackageFamilyName" string
# output: store app SID (security identifier) as string
# sample: Get-AppSID("User", "Microsoft.MicrosoftEdge_8wekyb3d8bbwe")
function Get-AppSID
{
    param (
        [parameter(Mandatory = $true, Position=0)]
        [ValidateLength(1, 100)]
        [string] $UserName,

        [parameter(Mandatory = $true, Position=1)]
        [ValidateLength(1, 100)]
        [string] $AppName
    )
    
    $ACL = Get-ACL "C:\Users\$UserName\AppData\Local\Packages\$AppName\AC"
    $ACE = $ACL.Access.IdentityReference.Value
    
    $ACE | ForEach-Object {
        # package SID starts with S-1-15-2-
        if($_ -match "S-1-15-2-") {
            return $_
        }
    }
}

# about: check if file such as an *.exe exists
# input: path to file
# output: warning message if file not found
# sample: Test-File("C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe")
function Test-File
{
    param (
        [parameter(Mandatory = $true)]
        [string] $FilePath
    )

    if ($global:InstallationStatus)
    {
        $ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)

        if (!([System.IO.File]::Exists($ExpandedPath)))
        {
            # NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
            $Script = (Get-PSCallStack)[1].Command
            $SearchPath = Split-Path -Path $ExpandedPath -Parent
            $Executable = Split-Path -Path $ExpandedPath -Leaf
            Set-Variable -Name WarningsDetected -Scope Global -Value $true
            
            Write-Warning "Executable '$Executable' was not found, rule won't have any effect
         Searched path was: $SearchPath"

            Write-Host "NOTE: To fix the problem find '$Executable' then adjust the path in $Script and re-run the script later again" -ForegroundColor Green
        }
    }
}

# about: Same as Test-Path but expands system environment variables
function Test-Environment
{
    param (
        [parameter(Mandatory = $true)]
        [string] $FilePath
    )

    return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)))
}

# input: User account in form of "COMPUTERNAME\USERNAME"
# output: list of programs for specified USERNAME
# sample: Get-UserPrograms "COMPUTERNAME\USERNAME"
function Get-UserPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $UserAccount
    )

    $ComputerName = ($UserAccount.split("\"))[0]

    if (Test-Connection -ComputerName $ComputerName -Count 3 -Quiet)
    {
        $HKU = Get-AccountSID $UserAccount
        $HKU += "\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        
        $RegistryHive = [Microsoft.Win32.RegistryHive]::Users
    
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)
        $UserKey = $RemoteKey.OpenSubkey($HKU)

        $UserPrograms = @()
        if ($UserKey)
        {
            foreach ($SubKey in $UserKey.GetSubKeyNames())
            {
                foreach ($KeyEntry in $UserKey.OpenSubkey($SubKey))
                {
                    # Get more key entries as needed
                    $UserPrograms += (New-Object PSObject -Property @{
                    "ComputerName" = $ComputerName
                    "Name" = $KeyEntry.GetValue("displayname")
                    "InstallLocation" = $KeyEntry.GetValue("InstallLocation")})
                }
            }
        }
        else
        {
            Write-Warning "Failed to open registry key: $HKU"
        }

        return $UserPrograms
    } 
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact $ComputerName"
    }
}

# input: ComputerName
# output: list of programs installed for all users
# sample: Get-SystemPrograms "COMPUTERNAME"
function Get-SystemPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 3 -Quiet)
    {
        # The value of the [IntPtr] property is 4 in a 32-bit process, and 8 in a 64-bit process.
        if ([IntPtr]::Size -eq 4)
        {
            $HKLM = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        }
        else
        {
            $HKLM = @(
                "Software\Microsoft\Windows\CurrentVersion\Uninstall"
                "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            )
        }
        
        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $SystemPrograms = @()
        foreach ($HKLMKey in $HKLM)
        {
            $UserKey = $RemoteKey.OpenSubkey($HKLMKey)

            if ($UserKey)
            {
                foreach ($SubKey in $UserKey.GetSubKeyNames())
                {
                    foreach ($KeyEntry in $UserKey.OpenSubkey($SubKey))
                    {
                        # Get more key entries as needed
                        $SystemPrograms += (New-Object PSObject -Property @{
                        "ComputerName" = $ComputerName
                        "Name" = $KeyEntry.GetValue("DisplayName")
                        "InstallLocation" = $KeyEntry.GetValue("InstallLocation")})
                    }
                }
            }
            else
            {
                Write-Warning "Failed to open registry key: $HKLMKey"
            }
        }

        return $SystemPrograms | Where-Object { $_.InstallLocation }
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact $ComputerName"
    }
}

# about: test if given installation directory is valid
# input: predefined program name and path to program (excluding executable)
# output: if test OK same path, if not try to update path, else return given path back
# sample: Test-Installation "Office" "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
function Test-Installation
{
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string] $Program,

        [parameter(Mandatory = $true, Position = 1)]
        [ref] $FilePath,

        [parameter(Mandatory = $false, Position = 2)]
        [bool] $Terminate = $true
    )

    if ($FilePath -contains "%UserProfile%")
    {
        Write-Warning "Bad environment variable detected '%UserProfile%', rule may not work!"
        Set-Variable -Name WarningsDetected -Scope Global -Value $true
    }

    if (!(Test-Environment $FilePath))
    {
        $InstallRoot = Find-Installation $Program
        if ([string]::IsNullOrEmpty($InstallRoot))
        {
            if ($InstallRoot -ne "")
            {
                if ($Terminate)
                {
                    exit # installation not found, exit script
                }
                else
                {
                    return $null # installation not found, don't exit script
                }
            }
        }
        else
        {
            Write-Host "NOTE: Path corrected from: $($FilePath.Value)
to: $InstallRoot" -ForegroundColor Green
            $FilePath.Value = $InstallRoot
            return $true # path updated
        }

        return $false # installation not found
    }

    return $true # path exists
}

# about: find installation directory for given program
# input: predefined program name
# output: installation directory if found, otherwise empty string
# sample: Find-Installation "Office"
function Find-Installation
{
    param (
        [parameter(Mandatory = $true)]
        [string] $Program
    )

    [string] $InstallationRoot = ""

    # NOTE: we want to preserve system environment variables for firewall GUI,
    # otherwise firewall GUI will show full paths which is not desired for sorting reasons
    switch -Wildcard ($Program)
    {
        "MicrosoftOffice"
        {
            $InstallationRoot = "%ProgramFiles%\Microsoft Office\root\Office16"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            $InstallationRoot = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "TeamViewer"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\TeamViewer"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "Chrome"
        {
            # TODO: need default directory too
            # TODO: need to return array of directories for multiple users
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\Google"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }    
            }
            break
        }
        "Firefox"
        {
            # TODO: need default directory too
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\Mozilla Firefox"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        "Yandex"
        {
            # TODO: need default directory too
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\Yandex"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        "Tor"
        {
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\Tor Browser"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        "uTorrent"
        {
            # TODO: need default directory too
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\uTorrent"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        "Thuderbird"
        {
            $InstallationRoot = "%ProgramFiles%\Mozilla Thunderbird"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "Steam"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\Steam"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "Nvidia64"
        {
            $InstallationRoot = "%ProgramFiles%\NVIDIA Corporation"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "Nvidia86"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\NVIDIA Corporation"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "WarThunder"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "PokerStars"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\PokerStars.EU"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "VisualStudio"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "MSYS2"
        {
            $InstallationRoot = "%ProgramFiles%\msys64"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "VisualStudioInstaller"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "Git"
        {
            $InstallationRoot = "%ProgramFiles%\Git"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "GithubDesktop"
        {
            # TODO: need to overcome version number
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\AppData\Local\GitHubDesktop\app-2.2.3"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        "EpicGames"
        {
            $InstallationRoot = "%ProgramFiles(x86)%\Epic Games\Launcher"
            if (Test-Environment $InstallationRoot)
            {
                return $InstallationRoot
            }
            break
        }
        "UnrealEngine"
        {
            # TODO: need default installation
            foreach ($User in $global:UserNames)
            {
                $InstallationRoot = "%SystemDrive%\Users\$User\source\repos\UnrealEngine\Engine"
                if (Test-Environment $InstallationRoot)
                {
                    return $InstallationRoot
                }
            }
            break
        }
        Default
        {
            Write-Warning "Parameter '$Program' not recognized"
            return ""
        }
    }

    Write-Warning "Installation directory for '$Program' not found"
    # NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
    $Script = (Get-PSCallStack)[2].Command

    Write-Host "NOTE: If you installed $Program elsewhere adjust the path in $Script and re-run the script later again,
otherwise ignore this warning if you don't have $Program installed." -ForegroundColor Green
    if (Approve-Execute "No" "Rule group for $Program" "Do you want to load these rules anyway?")
    {
        return $null
    }

    return ""
}


# Global status to check if installation directory exists, used by Test-File
New-Variable -Name InstallationStatus -Scope Global -Value $false

#
# Function exports
#

Export-ModuleMember -Function Get-UserPrograms
Export-ModuleMember -Function Get-SystemPrograms
Export-ModuleMember -Function Test-File
Export-ModuleMember -Function Find-Installation
Export-ModuleMember -Function Test-Installation
Export-ModuleMember -Function Get-AppSID
Export-ModuleMember -Function Test-Environment

#
# Variable exports
#

Export-ModuleMember -Variable InstallationStatus

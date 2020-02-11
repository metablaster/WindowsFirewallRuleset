
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

# Includes
Import-Module -Name $PSScriptRoot\..\UserInfo
Import-Module -Name $PSScriptRoot\..\ComputerInfo
Import-Module -Name $PSScriptRoot\..\FirewallModule

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

    $ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)

    if (!([System.IO.File]::Exists($ExpandedPath)))
    {
        # NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
        $Script = (Get-PSCallStack)[1].Command
        $SearchPath = Split-Path -Path $ExpandedPath -Parent
        $Executable = Split-Path -Path $ExpandedPath -Leaf

        Set-Warning @("Executable '$Executable' was not found, rules for '$Executable' won't have any effect"
        "Searched path was: $SearchPath")

        Write-Note @("To fix the problem find '$Executable' then adjust the path in"
        "$Script and re-run the script later again")
    }
}

# about: Same as Test-Path but expands system environment variables, and checks if compatible path
# input: Path to folder, Allow null or empty since input may come from other commandlets which can return empty or null
# output: $true if path exists, false otherwise
# sample: Test-Evnironment %SystemDrive%
function Test-Environment
{
    param (
        [parameter(Mandatory = $false)]
        [string] $FilePath = $null
    )

    if ([System.String]::IsNullOrEmpty($FilePath))
    {
        return $false
    }

    if ([Array]::Find($UserProfileEnvironment, [Predicate[string]]{ $FilePath -like "$($args[0])*" }))
    {
        Set-Warning "Bad environment variable detected, paths with environment variables that lead to user profile are not valid"
        Write-Note "Bad path detected is: $FilePath"
        return $false
    }

    return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)))
}

# about: check if service exists on system
# input: service name (not display name)
# output: warning and info message if service not found
# sample: Test-Service dnscache
function Test-Service
{
    param (
        [parameter(Mandatory = $true)]
        [string] $Service
    )

    if (!(Get-Service -Name $Service -ErrorAction SilentlyContinue))
    {
        Set-Warning "Service '$Service' not found, rule won't have any effect"
        Write-Note "To fix the problem update or comment out all firewall rules for '$Service' service"
    }
}

# TODO: see references and how to make it shorter
function Test-UserProfile
{
    param (
        [string] $FilePath
    )

    # Impssible to know what the imput may be
    if ([System.String]::IsNullOrEmpty($FilePath))
    {
        return $false
    }

    # Make an array of (environment variable/path) value pair,
    # user profile environment variables only
    $Variables = @()
    foreach ($Entry in @(Get-ChildItem Env:))
    {
        $Entry.Name = "%" + $Entry.Name + "%"

        if ($UserProfileEnvironment -contains $Entry.Name)
        {
            $Variables += $Entry
        }
    }

    # TODO: sorted result will have multiple same variables,
    # Sorting from longest paths which should be checked first
    $Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

    # Strip away quotations from path
    $FilePath = $FilePath.Trim('"')
    $FilePath = $FilePath.Trim("'")

    # Replace double slasses with single ones
    $FilePath = $FilePath.Replace("\\", "\")

    # If input path is root drive, removing a slash would produce bad path
    # Otherwise remove trailing slahs for cases where entry path is convertible to variable
    if ($FilePath.Length -gt 3)
    {
        $FilePath = $FilePath.TrimEnd('\\')
    }

    # Make a copy of file path because modification can be wrong
    $SearchString = $FilePath

    # Check if file path already contains user profile environment variable
    foreach ($Variable in $Variables)
    {
        if ($FilePath -like "$($Variable.Name)*")
        {
            Write-Debug "[Format-Path] Input path already formatted"
            return $true
        }
    }

    # See if path is convertible to environment variable
    while (![System.String]::IsNullOrEmpty($SearchString))
    {
        foreach ($Entry in $Variables)
        {
            if ($Entry.Value -like "*$SearchString")
            {
                # Environment variable found, if this is first hit, trailing slash is already removed
                return $true
            }
        }

        # Strip away file or last folder in path then try again (also trims trailing slash)
        $SearchString = Split-Path -Path $SearchString -Parent
    }

    Write-Debug "[Format-Path] Environment variables for input path don't exist"
    return $false
}

# about: format path into firewall compatible path
# input: path to folder
# output: formatted path, includes environment variables, stripped off of junk
# sample: Format-Path "C:\Program Files\Dir\"
function Format-Path
{
    param (
        [string] $FilePath
    )

    # Impssible to know what the imput may be
    if ([System.String]::IsNullOrEmpty($FilePath))
    {
        return $FilePath
    }

    # Make an array of (environment variable/path) value pair,
    # excluding user profile environment variables
    $Variables = @()
    foreach ($Entry in @(Get-ChildItem Env:))
    {
        $Entry.Name = "%" + $Entry.Name + "%"

        if ($BlackListEnvironment -notcontains $Entry.Name)
        {
            $Variables += $Entry
        }
    }

    # TODO: sorted result will have multiple same variables,
    # Sorting from longest paths which should be checked first
    $Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

    # Strip away quotations from path
    $FilePath = $FilePath.Trim('"')
    $FilePath = $FilePath.Trim("'")

    # Replace double slasses with single ones
    $FilePath = $FilePath.Replace("\\", "\")

    # If input path is root drive, removing a slash would produce bad path
    # Otherwise remove trailing slahs for cases where entry path is convertible to variable
    if ($FilePath.Length -gt 3)
    {
        $FilePath = $FilePath.TrimEnd('\\')
    }

    # Make a copy of file path because modification can be wrong
    $SearchString = $FilePath

    # Check if file path already contains environment variable
    foreach ($Variable in $Variables)
    {
        if ($FilePath -like "$($Variable.Name)*")
        {
            Write-Debug "[Format-Path] Input path already formatted"
            return $FilePath
        }
    }

    # See if path is convertible to environment variable
    while (![System.String]::IsNullOrEmpty($SearchString))
    {
        foreach ($Entry in $Variables)
        {
            if ($Entry.Value -like "*$SearchString")
            {
                # Environment variable found, if this is first hit, trailing slash is already removed
                return $FilePath.Replace($SearchString, $Entry.Name)
            }
        }

        # Strip away file or last folder in path then try again (also trims trailing slash)
        $SearchString = Split-Path -Path $SearchString -Parent
    }

    # path has been reduced to root drive so get that
    $SearchString = Split-Path -Path $FilePath -Qualifier
    # Since there are duplicate entries, we grab first one
    $Replacement = @(($Variables | Where-Object { $_.Value -eq $SearchString} ).Name)[0]

    if ([System.String]::IsNullOrEmpty($Replacement))
    {
        Write-Debug "[Format-Path] Environment variables for input path don't exist"
        # There are no environment variables for this drive
        # Just trim trailing slash
        return $FilePath.TrimEnd('\\')
    }

    # Only root drive is converted, just trim away trailing slash
    return $FilePath.Replace($SearchString, $Replacement).TrimEnd('\\')
}

# about: search installed programs in userprofile for specifit user account
# input: User account in form of "COMPUTERNAME\USERNAME"
# output: list of programs for specified USERNAME
# sample: Get-UserPrograms "COMPUTERNAME\USERNAME"
function Get-UserPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $UserAccount
    )

    $ComputerName = ($UserAccount.Split("\"))[0]

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
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
                foreach ($Key in $UserKey.OpenSubkey($SubKey))
                {
                    [string] $InstallLocation = $Key.GetValue("InstallLocation")

                    if (![System.String]::IsNullOrEmpty($InstallLocation))
                    {
                        # TODO: move all instances to directly format (first call above)
                        $InstallLocation = Format-Path $InstallLocation

                        # Get more key entries as needed
                        $UserPrograms += New-Object PSObject -Property @{
                            "ComputerName" = $ComputerName
                            "RegKey" = Split-Path $SubKey.ToString() -Leaf
                            "Name" = $Key.GetValue("displayname")
                            "InstallLocation" = $InstallLocation }
                    }
                    else
                    {
                        Set-Warning "Failed to read registry entry $Key\InstallLocation"
                    }
                }
            }
        }
        else
        {
            Set-Warning "Failed to open registry key: $HKU"
        }

        return $UserPrograms
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: search installed programs for all users, system wide
# input: ComputerName
# output: list of programs installed for all users
# sample: Get-SystemPrograms "COMPUTERNAME"
function Get-SystemPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        if ([System.Environment]::Is64BitOperatingSystem)
        {
            # 64 bit system
            $HKLM = @(
                "Software\Microsoft\Windows\CurrentVersion\Uninstall"
                "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            )
        }
        else
        {
            # 32 bit system
            $HKLM = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        }

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $SystemPrograms = @()
        foreach ($HKLMKey in $HKLM)
        {
            $RootKey = $RemoteKey.OpenSubkey($HKLMKey)

            if ($RootKey)
            {
                foreach ($SubKey in $RootKey.GetSubKeyNames())
                {
                    foreach ($KeyEntry in $RootKey.OpenSubkey($SubKey))
                    {
                        # First we get InstallLocation by normal means
                        # Strip away quotations and ending backslash
                        [string] $InstallLocation = $KeyEntry.GetValue("InstallLocation")
                        $InstallLocation = Format-Path $InstallLocation

                        if ([System.String]::IsNullOrEmpty($InstallLocation))
                        {
                            # Some programs do not install InstallLocation entry
                            # so let's take a look at DisplayIcon which is the path to executable
                            # then strip off all of the junk to get clean and relevant directory output
                            $InstallLocation = $KeyEntry.GetValue("DisplayIcon")
                            $InstallLocation = Format-Path $InstallLocation

                            # regex to remove: \whatever.exe at the end
                            $InstallLocation = $InstallLocation -Replace "\\(?:.(?!\\))+exe$", ""
                            # once exe is removed, remove unistall folder too if needed
                            #$InstallLocation = $InstallLocation -Replace "\\uninstall$", ""

                            if ([System.String]::IsNullOrEmpty($InstallLocation) -or
                            $InstallLocation -like "*{*}*" -or
                            $InstallLocation -like "*.exe*")
                            {
                                continue
                            }
                        }

                        # Get more key entries as needed
                        $SystemPrograms += New-Object PSObject -Property @{
                            "ComputerName" = $ComputerName
                            "RegKey" = Split-Path $SubKey.ToString() -Leaf
                            "Name" = $KeyEntry.GetValue("DisplayName")
                            "InstallLocation" = $InstallLocation }
                    }
                }
            }
            else
            {
                Set-Warning "Failed to open registry key: $HKLMKey"
            }
        }

        return $SystemPrograms
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: search program install properties for all users
# input: ComputerName
# output: list of programs installed for all users
# sample: Get-SystemPrograms "COMPUTERNAME"
function Get-AllUserPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    # TODO: make global connection timeout
    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        $HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $AllUserPrograms = @()
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Set-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            foreach ($HKLMKey in $RootKey.GetSubKeyNames())
            {
                $UserProducts = $RootKey.OpenSubkey("$HKLMKey\Products")

                if (!$UserProducts)
                {
                    Set-Warning "Failed to open UserKey: $HKLMKey\Products"
                    continue
                }

                foreach ($HKLMSubKey in $UserProducts.GetSubKeyNames())
                {
                    $ProductKey = $UserProducts.OpenSubkey("$HKLMSubKey\InstallProperties")

                    if (!$ProductKey)
                    {
                        Set-Warning "Failed to open ProductKey: $HKLMSubKey\InstallProperties"
                        continue
                    }

                    [string] $InstallLocation = $ProductKey.GetValue("InstallLocation")

                    if (![System.String]::IsNullOrEmpty($InstallLocation))
                    {
                        $InstallLocation = Format-Path $InstallLocation

                        # Get more key entries as needed
                        $AllUserPrograms += New-Object PSObject -Property @{
                            "ComputerName" = $ComputerName
                            "RegKey" = Split-Path $ProductKey.ToString() -Leaf
                            "Name" = $ProductKey.GetValue("DisplayName")
                            "Version" = $ProductKey.GetValue("DisplayVersion")
                            "InstallLocation" = $InstallLocation }
                    }
                }
            }

            return $AllUserPrograms
        }
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: Create data table used to hold information for specific program for each user
# input: Table name, but not mandatory
# output: Empty table with 2 columns, user entry and install location
# sample: $MyTable = Initialize-Table
function Initialize-Table
{
    param (
        [parameter(Mandatory = $false)]
        [string] $TableName = "InstallationTable"
    )

    # Create Table object
    Set-Variable -Name InstallTable -Scope Global -Value (New-Object System.Data.DataTable $TableName)

    # Define Columns
    $UserColumn = New-Object System.Data.DataColumn User, ([string])
    $InstallColumn = New-Object System.Data.DataColumn InstallRoot, ([string])

    # Add the Columns
    $InstallTable.Columns.Add($UserColumn)
    $InstallTable.Columns.Add($InstallColumn)

    #return Write-Output -NoEnumerate $InstallTable
}

# about: Search and add new program installation directory to the global table
# input: Search string which corresponds to the output of "Get programs" functions
# input: true if user profile is to be searched too, system locations only otherwise
# output: Global installation table is updated
# sample: Update-Table "Google Chrome"
function Update-Table
{
    param (
        [parameter(Mandatory = $true)]
        [string] $SearchString,

        [parameter(Mandatory = $false)]
        [bool] $UserProfile = $false
    )

    Write-Debug "Update-Table, Search string = $SearchString"

    # TODO: try to search also for path in addition to program name (3rd parameter)
    # TODO: SearchString may pick up irrelevant paths (ie. unreal), or even miss
    # Search system wide installed programs
    if ($SystemPrograms.Name -like "*$SearchString*")
    {
        # TODO: need better mechanism for multiple maches
        $TargetPrograms = $SystemPrograms | Where-Object { $_.Name -like "*$SearchString*" }

        foreach ($User in $UserNames)
        {
            foreach ($Program in $TargetPrograms)
            {
                # Create a row
                $Row = $InstallTable.NewRow()

                # Enter data into row
                $Row.User = $User
                $Row.InstallRoot = $Program | Select-Object -ExpandProperty InstallLocation

                # Add row to the table
                $InstallTable.Rows.Add($Row)
            }
        }
    }
    #Program not found on system, attempt alternative search
    elseif ($AllUserPrograms.Name -like "*$SearchString*")
    {
        $TargetPrograms = $AllUserPrograms | Where-Object { $_.Name -like "*$SearchString*" }

        # TODO: it not known if it's for specific user in AllUserPrograms registry entry (most likely applies to all users)
        foreach ($User in $UserNames)
        {
            foreach ($Program in $TargetPrograms)
            {
                # Create a row
                $Row = $InstallTable.NewRow()

                # Enter data into row
                $Row.User = $User
                $Row.InstallRoot = $Program | Select-Object -ExpandProperty InstallLocation

                # Add row to the table
                $InstallTable.Rows.Add($Row)
            }
        }
    }

    # Search user profiles
    if ($UserProfile)
    {
        foreach ($Account in $UserAccounts)
        {
            $UserPrograms = Get-UserPrograms $Account

            if ($UserPrograms.Name -like "*$SearchString*")
            {
                $TargetPrograms = $UserPrograms | Where-Object { $_.Name -like "*$SearchString*" }

                foreach ($Program in $TargetPrograms)
                {
                    # Create a row
                    $Row = $InstallTable.NewRow()

                    # Enter data into row
                    $Row.User = $Account.Split("\")[1]
                    $Row.InstallRoot = $Program | Select-Object -ExpandProperty InstallLocation

                    # Add the row to the table
                    $InstallTable.Rows.Add($Row)
                }
            }
        }
    }
}

# about: Manually add new program installation directory to the global table from string for each user
# input: Program installation directory
# output: Global installation table is updated
# sample: Edit-Table "%ProgramFiles(x86)%\TeamViewer"
function Edit-Table
{
    param (
        [parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    # Nothing to do if the path does not exist
    if (!(Test-Environment $InstallRoot))
    {
        return
    }

    # Check if input path leads to user profile
    if (Test-UserProfile $InstallRoot)
    {
        # Make sure user profile variables are removed
        $InstallRoot = Format-Path ([System.Environment]::ExpandEnvironmentVariables($InstallRoot))

        # Create a row
        $Row = $InstallTable.NewRow()

        # Enter data into row
        $Row.User = ($InstallRoot.Split("\"))[2]
        $Row.InstallRoot = $InstallRoot

        # Add the row to the table
        $InstallTable.Rows.Add($Row)
        return
    }

    $InstallRoot = Format-Path $InstallRoot

    # Not user profile path, so it applies to all users
    foreach ($User in $UserNames)
    {
        # Create a row
        $Row = $InstallTable.NewRow()

        # Enter data into row
        $Row.User = $User
        $Row.InstallRoot = $InstallRoot

        # Add the row to the table
        $InstallTable.Rows.Add($Row)
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
        [ref] $FilePath
    )

    # If input path is valid just make sure it's formatted
    if (Test-Environment $FilePath.Value)
    {
        $FilePath.Value = Format-Path $FilePath.Value
    }
    elseif (Find-Installation $Program)
    {
        # NOTE: the paths in installation table are supposed to be formatted
        $InstallRoot = "unknown install location"
        $Count = $InstallTable.Rows.Count

        if ($Count -gt 1)
        {
            Write-Host "Table data"
            $InstallTable | Format-Table -AutoSize

            Write-Note "Found multiple candidate installation directories for $Program"

            # Print out all candidate installation directories
            for ($Index = 0; $Index -lt $Count; ++$Index)
            {
                Write-Host "$($Index + 1). $($InstallTable.Rows[$Index].Item("InstallRoot"))"
            }

            # Prompt user to chose one
            [int] $Choice = 0
            while ($Choice -lt 1 -or $Choice -gt $Count)
            {
                Write-Host "Input number to choose which one is correct"
                $Choice = Read-Host
            }

            $InstallRoot = $InstallTable.Rows[$Choice - 1].Item("InstallRoot")
        }
        else
        {
            $InstallRoot = $InstallTable | Select-Object -ExpandProperty InstallRoot
        }

        Write-Note "Path corrected from: $($FilePath.Value)", "to: $InstallRoot"
        $FilePath.Value = $InstallRoot
    }
    else
    {
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

    Initialize-Table

    # TODO: if it's program in user profile then how do we know it that applies to admins or users in rule?
    # TODO: need to check some of these search strings (cases), also remove hardcoded directories
    # TODO: Update-Table calls Get-SystemPrograms for every iteration, make it global and singe call
    # NOTE: we want to preserve system environment variables for firewall GUI,
    # otherwise firewall GUI will show full paths which is not desired for sorting reasons
    switch -Wildcard ($Program)
    {
        "ArenaChess"
        {
            Update-Table "Arena Chess"
            break
        }
        "GoogleDrive"
        {
            Update-Table "Google Drive"
            break
        }
        "RivaTuner"
        {
            Update-Table "RivaTuner Statistics Server"
            break
        }
        "Incredibuild"
        {
            Update-Table "Incredibuild"
            break
        }
        "Metatrader"
        {
            Update-Table "InstaTrader"
            break
        }
        "RealWorld"
        {
            Edit-Table "%ProgramFiles(x86)%\RealWorld Cursor Editor"
            break
        }
        "qBittorrent"
        {
            Update-Table "qBittorrent"
            break
        }
        "OpenTTD"
        {
            Update-Table "OpenTTD"
            break
        }
        "EveOnline"
        {
            Update-Table "Eve Online"
            break
        }
        "DemiseOfNations"
        {
            Update-Table "Demise of Nations - Rome"
            break
        }
        "CounterStrikeGO"
        {
            Update-Table "Counter-Strike Global Offensive"
            break
        }
        "PinballArcade"
        {
            Update-Table "PinballArcade"
            break
        }
        "JavaPlugin"
        {
            Update-Table "Java\jre1.8.0_45\bin"
            break
        }
        "JavaUpdate"
        {
            Update-Table "Java Update"
            break
        }
        "JavaRuntime"
        {
            Update-Table "Java\jre7\bin"
            break
        }
        "AdobeARM"
        {
            Update-Table "Adobe\ARM"
            break
        }
        "AdobeAcrobat"
        {
            Update-Table "Acrobat Reader DC"
            break
        }
        "Filezilla"
        {
            Update-Table "FileZilla FTP Client"
            break
        }
        "PathOfExile"
        {
            Update-Table "Path of Exile"
            break
        }
        "HWMonitor"
        {
            Update-Table "HWMonitor"
            break
        }
        "CPU-Z"
        {
            Update-Table "CPU-Z"
            break
        }
        "MSIAfterburner"
        {
            Update-Table "MSI Afterburner"
            break
        }
        "GPG"
        {
            Update-Table "GNU Privacy Guard"
            break
        }
        "OBSStudio"
        {
            Update-Table "OBSStudio"
            break
        }
        "PasswordSafe"
        {
            Update-Table "Password Safe"
            break
        }
        "Greenshot"
        {
            Update-Table "Greenshot" $true
            break
        }
        "DnsCrypt"
        {
            Update-Table "Simple DNSCrypt"
            break
        }
        "OpenSSH"
        {
            Edit-Table "%ProgramFiles%\OpenSSH-Win64"
            break
        }
        "PowerShell64"
        {
            Edit-Table "%SystemRoot%\System32\WindowsPowerShell\v1.0"
            break
        }
        "PowerShell86"
        {
            Edit-Table "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
            break
        }
        "OneDrive"
        {
            Edit-Table "%ProgramFiles(x86)%\Microsoft OneDrive"
            break
        }
        "HelpViewer"
        {
            # TODO: is version number OK?
            Edit-Table "%ProgramFiles(x86)%\Microsoft Help Viewer\v2.3"
            break
        }
        "VSCode"
        {
            Update-Table "Visual Studio Code"
            break
        }
        "MicrosoftOffice"
        {
            Update-Table "Microsoft Office"
            break
        }
        "TeamViewer"
        {
            Update-Table "Team Viewer"
            break
        }
        "EdgeChromium"
        {
            Update-Table "Microsoft Edge"
            break
        }
        "Chrome"
        {
            Update-Table "Google Chrome" $true
            break
        }
        "Firefox"
        {
            Update-Table "Firefox" $true
            break
        }
        "Yandex"
        {
            Update-Table "Yandex" $true
            break
        }
        "Tor"
        {
            Update-Table "Tor" $true
            break
        }
        "uTorrent"
        {
            Update-Table "uTorrent" $true
            break
        }
        "Thuderbird"
        {
            Update-Table "Thuderbird" $true
            break
        }
        "Steam"
        {
            Update-Table "Steam"
            break
        }
        "Nvidia64"
        {
            Edit-Table "%ProgramFiles%\NVIDIA Corporation"
            break
        }
        "Nvidia86"
        {
            Edit-Table "%ProgramFiles(x86)%\NVIDIA Corporation"
            break
        }
        "WarThunder"
        {
            Edit-Table "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"
            break
        }
        "PokerStars"
        {
            Update-Table "PokerStars"
            break
        }
        "VisualStudio"
        {
            Update-Table "Visual Studio"
            break
        }
        "MSYS2"
        {
            Update-Table "MSYS2" $true
            break
        }
        "VisualStudioInstaller"
        {
            Edit-Table "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
            break
        }
        "Git"
        {
            Update-Table "Git"
            break
        }
        "GithubDesktop"
        {
            Update-Table "GitHubDesktop" $true
            break
        }
        "EpicGames"
        {
            Edit-Table "%ProgramFiles(x86)%\Epic Games\Launcher"
            break
        }
        "UnrealEngine"
        {
            Update-Table "UnrealEngine"
            break
        }
        default
        {
            Set-Warning "Parameter '$Program' not recognized" $false
        }
    }

    if ($InstallTable.Rows.Count -gt 0)
    {
        return $true
    }
    else
    {
        Set-Warning "Installation directory for '$Program' not found" $false

        # NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
        $Script = (Get-PSCallStack)[2].Command

        # TODO: this loops seem to be skiped, probably missing Test-File, need to check
        Write-Note @("If you installed $Program elsewhere you can input the correct path now"
        "or adjust the path in $Script and re-run the script later."
        "otherwise ignore this warning if you don't have $Program installed.")

        if (Approve-Execute "Yes" "Rule group for $Program" "Do you want to input path now?")
        {
            while ($InstallTable.Rows.Count -eq 0)
            {
                [string] $InstallRoot = Read-Host "Input path to '$Program' root directory"

                if (![System.String]::IsNullOrEmpty($InstallRoot))
                {
                    Edit-Table $InstallRoot

                    if ($InstallTable.Rows.Count -gt 0)
                    {
                        return $true
                    }
                }

                Set-Warning "Installation directory for '$Program' not found" $false
                if (Approve-Execute "No" "Unable to locate '$InstallRoot'" "Do you want to try again?")
                {
                    break
                }
            }
        }

        # Finaly status is bad
        Set-Variable -Name WarningStatus -Scope Global -Value $true
        return $false
    }
}

# about: Return installed NET Frameworks
# input: Computer name for which to list installed installed framework
# output: Table of installed NET Framework versions and install paths
# sample: Get-NetFramework COMPUTERNAME
function Get-NetFramework
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        $HKLM = "SOFTWARE\Microsoft\NET Framework Setup\NDP"

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $NetFramework = @()
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Set-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            foreach ($HKLMKey in $RootKey.GetSubKeyNames())
            {
                $KeyEntry = $RootKey.OpenSubkey($HKLMKey)

                if (!$KeyEntry)
                {
                    Set-Warning "Failed to open KeyEntry: $HKLMKey"
                    continue
                }

                $Version = $KeyEntry.GetValue("Version")
                if (![System.String]::IsNullOrEmpty($Version))
                {
                    $InstallLocation = $KeyEntry.GetValue("InstallPath")

                    # else not warning because some versions are built in
                    if (![System.String]::IsNullOrEmpty($InstallLocation))
                    {
                        $InstallLocation = Format-Path $InstallLocation
                    }

                    #  we add entry regarldess of presence of install path
                    $NetFramework += New-Object -TypeName PSObject -Property @{
                        "ComputerName" = $ComputerName
                        "RegKey" = Split-Path $KeyEntry.ToString() -Leaf
                        "Version" = $Version
                        "InstallPath" = $InstallLocation }
                }
                else # go one key down
                {
                    foreach ($SubKey in $KeyEntry.GetSubKeyNames())
                    {
                        $SubKeyEntry = $KeyEntry.OpenSubkey($SubKey)
                        if (!$SubKeyEntry)
                        {
                            Set-Warning "Failed to open SubKeyEntry: $SubKey"
                            continue
                        }

                        $Version = $SubKeyEntry.GetValue("Version")
                        if (![System.String]::IsNullOrEmpty($Version))
                        {
                            $InstallLocation = $SubKeyEntry.GetValue("InstallPath")

                            # else not warning because some versions are built in
                            if (![System.String]::IsNullOrEmpty($InstallLocation))
                            {
                                $InstallLocation = Format-Path $InstallLocation
                            }

                            # we add entry regarldess of presence of install path
                            $NetFramework += New-Object -TypeName PSObject -Property @{
                                "ComputerName" = $ComputerName
                                "RegKey" = Split-Path $SubKey.ToString() -Leaf
                                "Version" = $Version
                                "InstallPath" = $InstallLocation }
                        }
                    }
                }
            }
        }

        return $NetFramework
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: Return installed Windows SDK
# input: Computer name for which to list installed installed framework
# output: Table of installed Windows SDK versions and install paths
# sample: Get-WindowsSDK COMPUTERNAME
function Get-WindowsSDK
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        if ([System.Environment]::Is64BitOperatingSystem)
        {
            # 64 bit system
            $HKLM = "SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows"
        }
        else
        {
            # 32 bit system
            $HKLM = "SOFTWARE\Microsoft\Microsoft SDKs\Windows"

        }

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $WindowsSDK = @()
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Set-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            foreach ($HKLMKey in $RootKey.GetSubKeyNames())
            {
                $SubKey = $RootKey.OpenSubkey($HKLMKey)

                if (!$SubKey)
                {
                    Set-Warning "Failed to open SubKey: $HKLMKey"
                    continue
                }

                $RegKey = Split-Path $SubKey.ToString() -Leaf
                $InstallLocation = $SubKey.GetValue("InstallationFolder")

                if (![System.String]::IsNullOrEmpty($InstallLocation))
                {
                    $InstallLocation = Format-Path $InstallLocation
                }
                else
                {
                    Set-Warning "Failed to read registry entry $RegKey\InstallationFolder"
                }

                # we add entry regarldess of presence of install path
                $WindowsSDK += New-Object -TypeName PSObject -Property @{
                    "ComputerName" = $ComputerName
                    "RegKey" = $RegKey
                    "Product" = $SubKey.GetValue("ProductName")
                    "Version" = $SubKey.GetValue("ProductVersion")
                    "InstallPath" = $InstallLocation }
            }
        }

        return $WindowsSDK
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: Return installed Windows Kits
# input: Computer name for which to list installed installed framework
# output: Table of installed Windows Kits versions and install paths
# sample: Get-WindowsKits COMPUTERNAME
function Get-WindowsKits
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        if ([System.Environment]::Is64BitOperatingSystem)
        {
            # 64 bit system
            $HKLM = "SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"

        }
        else
        {
            # 32 bit system
            $HKLM = "SOFTWARE\Microsoft\Windows Kits\Installed Roots"
        }

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $WindowsKits = @()
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Set-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            foreach ($Entry in $RootKey.GetValueNames())
            {
                $InstallLocation = $RootKey.GetValue($Entry)

                if (![System.String]::IsNullOrEmpty($InstallLocation) -and $InstallLocation -like "C:\Program Files*")
                {
                    $InstallLocation = Format-Path $InstallLocation

                    $WindowsKits += New-Object -TypeName PSObject -Property @{
                        "ComputerName" = $ComputerName
                        "RegKey" = Split-Path $RootKey.ToString() -Leaf
                        "Product" = $Entry
                        "InstallPath" = $InstallLocation}
                }
            }
        }

        return $WindowsKits
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

# about: Return installed Windows Defender
# input: Computer name for which to list installed Windows Defender
# output: Table of installed Windows Defender, version and install paths
# sample: Get-WindowsDefender COMPUTERNAME
function Get-WindowsDefender
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        # 32 bit system
        $HKLM = "SOFTWARE\Microsoft\Windows Defender"

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $WindowsDefender = $null
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Set-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            $InstallLocation = $RootKey.GetValue("InstallLocation")
            $RegKey = Split-Path $RootKey.ToString() -Leaf

            if (![System.String]::IsNullOrEmpty($InstallLocation))
            {
                $WindowsDefender = New-Object -TypeName PSObject -Property @{
                    "ComputerName" = $ComputerName
                    "RegKey" = $RegKey
                    "InstallPath" = Format-Path $InstallLocation }
            }
            else
            {
                Set-Warning "Failed to read registry entry $RegKey\InstallLocation"
            }
        }

        return $WindowsDefender
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
        return $null
    }
}

#
# Module variables
#

# $DebugPreference = "Continue"

# Installation table holds user and program directory pair
New-Variable -Name InstallTable -Scope Global -Value $null

# Any environment variables to user profile are not valid for firewall
New-Variable -Name BlackListEnvironment -Scope Script -Option Constant -Value @(
    "%APPDATA%"
    "%HOME%"
    "%HOMEPATH%"
    "%LOCALAPPDATA%"
    "%OneDrive%"
    "%OneDriveConsumer%"
    "%Path%"
    "%PSModulePath%"
    "%TEMP%"
    "%TMP%"
    "%USERNAME%"
    "%USERPROFILE%")

New-Variable -Name UserProfileEnvironment -Scope Script -Option Constant -Value @(
    "%APPDATA%"
    "%HOME%"
    "%HOMEPATH%"
    "%LOCALAPPDATA%"
    "%OneDrive%"
    "%OneDriveConsumer%"
    "%TEMP%"
    "%TMP%"
    "%USERNAME%"
    "%USERPROFILE%")

# Computer name for use use in this module
New-Variable -Name ComputerName -Scope Script -Option ReadOnly -Value (Get-ComputerName)

# Programs installed for all users
New-Variable -Name SystemPrograms -Scope Script -Option ReadOnly -Value (Get-SystemPrograms $ComputerName)

# Programs installed for all users
New-Variable -Name AllUserPrograms -Scope Script -Option ReadOnly -Value (Get-AllUserPrograms $ComputerName)

#
# Function exports
#

Export-ModuleMember -Function Test-File
Export-ModuleMember -Function Test-Installation
Export-ModuleMember -Function Get-AppSID
Export-ModuleMember -Function Test-Service

# Exporting for testing only
Export-ModuleMember -Function Format-Path
Export-ModuleMember -Function Test-UserProfile
Export-ModuleMember -Function Find-Installation
Export-ModuleMember -Function Test-Environment

Export-ModuleMember -Function Update-Table
Export-ModuleMember -Function Edit-Table
Export-ModuleMember -Function Initialize-Table

Export-ModuleMember -Function Get-UserPrograms
Export-ModuleMember -Function Get-AllUserPrograms
Export-ModuleMember -Function Get-SystemPrograms
Export-ModuleMember -Function Get-NetFramework
Export-ModuleMember -Function Get-WindowsKits
Export-ModuleMember -Function Get-WindowsSDK
Export-ModuleMember -Function Get-WindowsDefender

#
# Variable exports
#

# For deubgging only
Export-ModuleMember -Variable InstallTable

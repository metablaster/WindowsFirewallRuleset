
# Command Help

Powershell and other commands and command samples are here primarily to quickly copy/paste them as
needed, to recall things or to perform specific console tasks useful for Windows firewall
development as opposed to running scripts.

In addition to the table below, see:

[Windows PowerShell Cmdlets for Networking](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj717268(v=ws.11))

## Table of Contents

- [Command Help](#command-help)
  - [Table of Contents](#table-of-contents)
  - [Store Apps](#store-apps)
    - [List all system apps beginning with word "Microsoft"](#list-all-system-apps-beginning-with-word-microsoft)
    - [List all provisioned Windows apps](#list-all-provisioned-windows-apps)
    - [Lists the app packages that are installed for specific user account on the computer](#lists-the-app-packages-that-are-installed-for-specific-user-account-on-the-computer)
    - [Get specific package](#get-specific-package)
    - [Get app details](#get-app-details)
    - [Update store apps](#update-store-apps)
  - [Users and computers](#users-and-computers)
    - [List all users](#list-all-users)
    - [List only users](#list-only-users)
    - [Only Administrators](#only-administrators)
    - [Prompt user for credentials](#prompt-user-for-credentials)
    - [Computer information](#computer-information)
    - [Currently logged in user](#currently-logged-in-user)
    - [Well known SID's](#well-known-sids)
    - [Computer name](#computer-name)
  - [CIM (Common Information Model)](#cim-common-information-model)
    - [CIM classes](#cim-classes)
    - [CIM Cmdlets](#cim-cmdlets)
  - [Network interfaces](#network-interfaces)
    - [All possible adapters and their relevant info](#all-possible-adapters-and-their-relevant-info)
    - [Physical, virtual and loopback IP interfaces](#physical-virtual-and-loopback-ip-interfaces)
    - [All adapters configured with an IP regardless of connection state](#all-adapters-configured-with-an-ip-regardless-of-connection-state)
  - [git and GitHub](#git-and-github)
    - [Repository creation date](#repository-creation-date)
    - [Go to first commit on GitHub](#go-to-first-commit-on-github)
    - [Clean up repository](#clean-up-repository)
  - [Troubleshooting](#troubleshooting)
    - [Get rule special properties](#get-rule-special-properties)
    - [Get new services](#get-new-services)
    - [Gpg agent does not work](#gpg-agent-does-not-work)
  - [Code design and development](#code-design-and-development)
    - [Get type accelerators](#get-type-accelerators)
    - [Get approved verbs](#get-approved-verbs)
    - [Invoke PSScriptAnalyzer](#invoke-psscriptanalyzer)
    - [Add or use types from .NET assembly in PowerShell](#add-or-use-types-from-net-assembly-in-powershell)
    - [Get function definition](#get-function-definition)
    - [List all of the assemblies loaded in a PowerShell session](#list-all-of-the-assemblies-loaded-in-a-powershell-session)
  - [Firewall and rule management](#firewall-and-rule-management)
    - [Get a list of predefined rule groups](#get-a-list-of-predefined-rule-groups)
    - [Apply predefined rules to GPO](#apply-predefined-rules-to-gpo)
    - [Temporarily toggle all blocking rules](#temporarily-toggle-all-blocking-rules)
  - [Package provider management](#package-provider-management)
    - [List of package providers that are loaded or installed but not loaded](#list-of-package-providers-that-are-loaded-or-installed-but-not-loaded)
    - [List of package sources that are registered for a package provider](#list-of-package-sources-that-are-registered-for-a-package-provider)
    - [List of Package providers available for installation](#list-of-package-providers-available-for-installation)
    - [Install package provider](#install-package-provider)
  - [Module management](#module-management)
  - [Windows System](#windows-system)
    - [Clear event logs](#clear-event-logs)
  - [VSCode](#vscode)

## Store Apps

There are two categories:

1. Apps - All other apps, installed in `C:\Program Files\WindowsApps`. There are two classes of apps:
    - Provisioned: Installed in user account the first time you sign in with a new user account.
    - Installed: Installed as part of the OS.
2. System apps - Apps that are installed in the `C:\Windows\*` directory.
These apps are integral to the OS.

### List all system apps beginning with word "Microsoft"

```powershell
Get-AppxPackage -PackageTypeFilter Main |
Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } |
Sort-Object Name | ForEach-Object {$_.Name}
```

### List all provisioned Windows apps

Not directly useful, but returns a few more packages than `Get-AppxPackage -PackageTypeFilter Bundle`

```powershell
Get-AppxProvisionedPackage -Online | Sort-Object DisplayName | Format-Table DisplayName, PackageName
```

### Lists the app packages that are installed for specific user account on the computer

```powershell
Get-AppxPackage -User User -PackageTypeFilter Bundle | Sort-Object Name | ForEach-Object {$_.Name}
```

### Get specific package

```powershell
Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} |
Select-Object -ExpandProperty Name
```

[Reference App Management][reference app management]

[Reference Get-AppxPackage][reference appxpackage]

### Get app details

```powershell
(Get-AppxPackage -Name "*Yourphone*" | Get-AppxPackageManifest).Package.Capabilities
```

### Update store apps

```powershell
$NamespaceName = "root\cimv2\mdm\dmmap"
$ClassName = "MDM_EnterpriseModernAppManagement_AppManagement01"
$WmiObj = Get-WmiObject -Namespace $NamespaceName -Class $ClassName
$Result = $WmiObj.UpdateScanMethod()
```

OR

```powershell
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" `
-ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" |
Invoke-CimMethod -MethodName UpdateScanMethod
```

[Table of Contents](#table-of-contents)

## Users and computers

### List all users

```powershell
Get-WmiObject -Class Win32_UserAccount
[Enum]::GetValues([System.Security.Principal.WellKnownSidType])
```

### List only users

```powershell
Get-LocalGroupMember -name users
```

```powershell
Get-LocalGroupMember -Group "Users"
```

### Only Administrators

```powershell
Get-LocalGroupMember -Group "Administrators"
```

### Prompt user for credentials

```powershell
Get-Credential
```

### Computer information

```powershell
Get-WMIObject -class Win32_ComputerSystem
```

### Currently logged in user

user name, prefixed by its domain

```powershell
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```

### Well known SID's

```powershell
$Group = 'Administrators'
$account = New-Object -TypeName System.Security.Principal.NTAccount($Group)
$sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
```

OR

```powershell
[System.Security.Principal.WellKnownSidType]::NetworkSid
```

### Computer name

```powershell
[System.Net.Dns]::GetHostName()
```

```powershell
Get-WMIObject -class Win32_ComputerSystem | Select-Object -ExpandProperty Name
```

[Table of Contents](#table-of-contents)

## CIM (Common Information Model)

### CIM classes

```powershell
Get-CimClass -Namespace root/CIMV2 |
Where-Object CimClassName -like Win32* |
Select-Object CimClassName
```

### CIM Cmdlets

```powershell
Get-Command -Module CimCmdlets
```

[Table of Contents](#table-of-contents)

## Network interfaces

### All possible adapters and their relevant info

```powershell
Get-NetadApter -IncludeHidden | Select-Object -Property Name, InterfaceIndex, InterfaceAlias, `
InterfaceDescription, MediaConnectionState, Status, HardwareInterface, Hidden, Virtual, `
AdminStatus, ifOperStatus, ConnectionState
```

### Physical, virtual and loopback IP interfaces

```powershell
Get-NetIPInterface -IncludeAllCompartments | Select-Object -Property InterfaceIndex, `
InterfaceAlias, AddressFamily, ConnectionState, Store
```

### All adapters configured with an IP regardless of connection state

Loopback and probably hidden adapters are not shown

```powershell
Get-NetIPConfiguration -AllCompartments -Detailed
```

[Table of Contents](#table-of-contents)

## git and GitHub

### Repository creation date

To figure out the date and time some repository was created run curl against following URL format:

`https://api.github.com/repos/<REPO_OWNER>/<REPO_NAME>`

For example to see creation date and time of this repository run:

```powershell
curl https://api.github.com/repos/metablaster/WindowsFirewallRuleset |
ConvertFrom-Json | Select-Object -ExpandProperty "created_at"
```

### Go to first commit on GitHub

Get first commit SHA with `git log --reverse`

Copy SHA and paste into "Search or Jump to..." on GitHub, search "In this repository"

### Clean up repository

`git clean -d -x --dry-run`\
`git clean -d -x -f`

`git prune --dry-run`\
`git prune`

`git repack -d -F`

[Table of Contents](#table-of-contents)

## Troubleshooting

Commands useful to troubleshoot random issues

### Get rule special properties

Update `PolicyStore`, `DisplayGroup` and `Direction` before running

```powershell
Get-NetFirewallRule -PolicyStore PersistentStore -DisplayGroup "Network Discovery" `
-Direction Outbound | Select-Object DisplayName, PolicyDecisionStrategy, ConditionListType, `
ExecutionStrategy, SequencedActions, Profiles, LocalOnlyMapping, LooseSourceMapping
```

### Get new services

Quickly detect which services started after some system state change

```powershell
$ReferenceServices = Get-Service | Where-Object -Property Status -eq "Running"
($ReferenceServices | Measure-Object).Count

$DifferenceServices = Get-Service | Where-Object -Property Status -eq "Running"
($DifferenceServices | Measure-Object).Count

$NewServices = Compare-Object -ReferenceObject $ReferenceServices -DifferenceObject $DifferenceServices
$NewServices | Select-Object -ExpandProperty InputObject
```

### Gpg agent does not work

Problem:

```none
gpg: can't connect to the agent
```

Fix:

```none
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

If not working:

```none
gpgconf: error running 'C:\Program Files (x86)\GnuPG\bin\gpg-connect-agent.exe'
```

Then close down all programs, open new PowerShell or CMD console instance and run the fix again
but with pause of at least 5 seconds between each command.

[Table of Contents](#table-of-contents)

## Code design and development

Most useful commands for design

### Get type accelerators

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | Sort-Object Key
```

### Get approved verbs

```powershell
# PowerShell Core
Get-Verb | Select-Object Verb, Group, Description | Sort-Object Verb

# Windows PowerShell
Get-Verb | Select-Object Verb, Group | Sort-Object Verb
```

### Invoke PSScriptAnalyzer

```powershell
Invoke-ScriptAnalyzer -Path .\ -Recurse -Settings Config\PSScriptAnalyzerSettings.psd1 |
Format-List -Property Severity, RuleName, RuleSuppressionID, Message, Line, ScriptPath
```

### Add or use types from .NET assembly in PowerShell

```powershell
Add-Type -AssemblyName "System.Management.Automation"
```

```powershell
using namespace System.Management.Automation
```

### Get function definition

Quickly see definition of some function to learn it's implementation

`Get-ChildItem function:`

```powershell
(Get-ChildItem function:Get-GitStatus).Definition
```

### List all of the assemblies loaded in a PowerShell session

```powershell
[System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object Location | Sort-Object -Property FullName |
Select-Object -Property FullName, Location, GlobalAssemblyCache, IsFullyTrusted | Out-GridView
```

[Table of Contents](#table-of-contents)

## Firewall and rule management

### Get a list of predefined rule groups

```powershell
Get-NetFirewallRule -PolicyStore SystemDefaults | Sort-Object -Unique Group |
Sort-Object DisplayGroup | Format-Table DisplayGroup, Group
```

### Apply predefined rules to GPO

Apply "Remote Assistance" predefined rules to GPO firewall (both inbound and outbound)

```powershell
Get-NetFirewallRule -PolicyStore SystemDefaults -Group "@FirewallAPI.dll,-33002" `
-PolicyStoreSourceType Local | Copy-NetFirewallRule -NewPolicyStore ([Environment]::MachineName)
```

Same but by referencing by DisplayGroup

```powershell
Get-NetFirewallRule -PolicyStore SystemDefaults -DisplayGroup "Network Discovery" `
-PolicyStoreSourceType Local | Copy-NetFirewallRule -NewPolicyStore ([Environment]::MachineName)
```

### Temporarily toggle all blocking rules

To quickly troubleshoot packet drop, should be used in conjunction with allowing default inbound and
outbound.

```powershell
$Rules = Get-NetFirewallRule -PolicyStore ([environment]::MachineName) |
Where-Object { $_.Action -eq "Block" -and $_.Enabled -eq "True" }

Disable-NetFirewallRule -InputObject $Rules
Enable-NetFirewallRule -InputObject $Rules
```

[Table of Contents](#table-of-contents)

## Package provider management

### List of package providers that are loaded or installed but not loaded

```powershell
Get-PackageProvider
Get-PackageProvider -ListAvailable
```

### List of package sources that are registered for a package provider

```powershell
Get-PackageSource
```

### List of Package providers available for installation

```powershell
Find-PackageProvider -Name Nuget -AllVersions
Find-PackageProvider -Name PowerShellGet -AllVersions -Source "https://www.powershellgallery.com/api/v2"
```

### Install package provider

-Scope AllUsers (Install location for all users)

```powershell
"$env:ProgramFiles\PackageManagement\ProviderAssemblies"
```

-Scope CurrentUser (Install location for current user)

```powershell
"$env:LOCALAPPDATA\PackageManagement\ProviderAssemblies"
```

```powershell
Install-PackageProvider -Name Nuget -Verbose -Scope CurrentUser
# Install-PackageProvider -Name PowerShellGet -Verbose -Scope CurrentUser
```

[Table of Contents](#table-of-contents)

## Module management

```powershell
# TODO: Package and module management
```

[reference app management]: https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10 "Visit Microsoft docs"
[reference appxpackage]: https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps "Visit Microsoft docs"

[Table of Contents](#table-of-contents)

## Windows System

Specifc system wide commands that are useful for firewall management

### Clear event logs

WFP and PowerShell may generate log entries

**NOTE:** All credits to [How to Clear All Event Logs in Event Viewer in Windows][tenforums]

```powershell
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount } | ForEach-Object {
  [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName)
}
```

[Table of Contents](#table-of-contents)

## VSCode

Some VSCode commands useful to troubleshoot issues (`CTRL + SHIFT + P`)

```json
// To reload all extensions and VSCode configuration
Developer: Reload Window

// To set verbosity of the outpout window
Developer: Set Log Level...

// To fire up VSCode developer tools
Developer: Toggle Developer Tools

// To restard integrated PS session
PowerShell: Restart Current Session

// To change PS edition of the integrated console
PowerShell: Show Session Menu

// To open user settings file
Preferences: Open User Settings (JSON)

// To clear VSCode editor history
Clear Editor History
```

[Table of Contents](#table-of-contents)

[tenforums]: https://www.tenforums.com/tutorials/16588-clear-all-event-logs-event-viewer-windows.html "Visit tutorial"

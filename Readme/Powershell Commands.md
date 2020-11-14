
# PowerShell commands(lets)

Powershell commands to help gather information useful for Windows firewall development.

These commands are here primarily to quickly copy/paste them as needed to perform specific tasks
by using console as opposed to running scripts.

In addition to table below, see:

[Windows PowerShell Cmdlets for Networking](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj717268(v=ws.11))

## Table of contents

- [PowerShell commands(lets)](#powershell-commandslets)
  - [Table of contents](#table-of-contents)
  - [Store Apps](#store-apps)
    - [List all system apps beginning with word "Microsoft"](#list-all-system-apps-beginning-with-word-microsoft)
    - [List all provisioned Windows apps](#list-all-provisioned-windows-apps)
    - [Lists the app packages that are installed for specific user account on the computer](#lists-the-app-packages-that-are-installed-for-specific-user-account-on-the-computer)
    - [Get specific package](#get-specific-package)
    - [Get app details](#get-app-details)
    - [Update store apps](#update-store-apps)
  - [Get users and computers](#get-users-and-computers)
    - [List all users](#list-all-users)
    - [List only users](#list-only-users)
    - [Only Administrators](#only-administrators)
    - [Prompt user for credentials](#prompt-user-for-credentials)
    - [Computer information](#computer-information)
    - [Currently logged in user](#currently-logged-in-user)
    - [Well known SID's](#well-known-sids)
    - [Computer name](#computer-name)
  - [Get CIM classes and commandlets](#get-cim-classes-and-commandlets)
  - [Data types and aliases](#data-types-and-aliases)
    - [Get type name aliases](#get-type-name-aliases)
    - [Add-Type](#add-type)
  - [Package provider management](#package-provider-management)
    - [List of package providers that are loaded or installed but not loaded](#list-of-package-providers-that-are-loaded-or-installed-but-not-loaded)
    - [List of package sources that are registered for a package provider](#list-of-package-sources-that-are-registered-for-a-package-provider)
    - [List of Package providers available for installation](#list-of-package-providers-available-for-installation)
    - [Install package provider](#install-package-provider)
  - [Module management](#module-management)
  - [Get network interfaces](#get-network-interfaces)
    - [All possible adapters and their relevant info](#all-possible-adapters-and-their-relevant-info)
    - [Physical, virtual and loopback IP interfaces](#physical-virtual-and-loopback-ip-interfaces)
    - [All adapters configured with an IP regardless of connection state](#all-adapters-configured-with-an-ip-regardless-of-connection-state)
  - [Repository creation date](#repository-creation-date)
  - [Troubleshooting](#troubleshooting)
    - [Get rule special properties](#get-rule-special-properties)
    - [Temporarily toggle all blocking rules](#temporarily-toggle-all-blocking-rules)
    - [Get new services](#get-new-services)
  - [Code design and development](#code-design-and-development)
    - [Get type accelerators](#get-type-accelerators)
    - [Get approved verbs](#get-approved-verbs)
    - [Invoke PSScriptAnalyzer](#invoke-psscriptanalyzer)

## Store Apps

There are two categories:

1. Apps - All other apps, installed in C:\Program Files\WindowsApps. There are two classes of apps:
    1. Provisioned: Installed in user account the first time you sign in with a new user account.
    2. Installed: Installed as part of the OS.
2. System apps - Apps that are installed in the C:\Windows* directory.
These apps are integral to the OS.

### List all system apps beginning with word "Microsoft"

We use word "Microsoft" to filter out junk

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

[Reference App Management](https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10)

[Reference Get-AppxPackage](https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps)

### Get app details

```powershell
(Get-AppxPackage -Name "*Yourphone*" | Get-AppxPackageManifest).Package.Capabilities
```

### Update store apps

```powershell
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
```

OR

```powershell
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" `
-ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" |
Invoke-CimMethod -MethodName UpdateScanMethod
```

## Get users and computers

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

## Get CIM classes and commandlets

```powershell
Get-CimClass -Namespace root/CIMV2 |
Where-Object CimClassName -like Win32* |
Select-Object CimClassName
```

```powershell
Get-Command -Module CimCmdlets
```

## Data types and aliases

### Get type name aliases

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get
```

### Add-Type

```powershell
Add-Type -AssemblyName "System.Management.Automation"
```

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

## Module management

```powershell
```

## Get network interfaces

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

## Repository creation date

To figure out the date and time some repository was created run curl against following URL format:

`https://api.github.com/repos/<REPO_OWNER>/<REPO_NAME>`

For example to see creation date and time of this repository run:

```powershell
curl https://api.github.com/repos/metablaster/WindowsFirewallRuleset |
ConvertFrom-Json | Select-Object -ExpandProperty "created_at"
```

Another option is to use `git log --reverse`

## Troubleshooting

Command useful to troubleshoot random issues

### Get rule special properties

Update `PolicyStore`, `DisplayGroup` and `Direction` before running

```powershell
Get-NetFirewallRule -PolicyStore PersistentStore -DisplayGroup "Network Discovery" -Direction Outbound |
Select-Object DisplayName, PolicyDecisionStrategy, ConditionListType, ExecutionStrategy, `
SequencedActions, Profiles, LocalOnlyMapping, LooseSourceMapping
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

## Code design and development

Most useful commands for design

### Get type accelerators

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | Sort-Object Key
```

### Get approved verbs

```powershell
Get-Verb | Select-Object Verb, Group, Description | Sort-Object Verb
```

### Invoke PSScriptAnalyzer

```powershell
Invoke-ScriptAnalyzer -Path .\ -Recurse -Settings Config\PSScriptAnalyzerSettings.psd1
```

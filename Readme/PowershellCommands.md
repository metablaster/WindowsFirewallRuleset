
# About this document
Usefull Powershell commands to help gather information needed for Windows firewall.

# Store Apps

There are two categories:

1. Apps - All other apps, installed in C:\Program Files\WindowsApps. There are two classes of apps:
- Provisioned: Installed in user account the first time you sign in with a new user account.
- Installed: Installed as part of the OS.
2. System apps - Apps that are installed in the C:\Windows* directory. These apps are integral to the OS.

**List all system apps beginning with word "Microsoft"**

We use word "Microsoft" to filter out junk

```powershell
Get-AppxPackage -PackageTypeFilter Main | Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | Sort-Object Name | ForEach-Object {$_.Name}
```

**List all provisioned Windows apps**

Not directly useful, but returns a few more packages than `Get-AppxPackage -PackageTypeFilter Bundle`

```powershell
Get-AppxProvisionedPackage -Online | Sort-Object DisplayName | Format-Table DisplayName, PackageName
```

**Lists the app packages that are installed for specific user account on the computer**

```powershell
Get-AppxPackage -User User -PackageTypeFilter Bundle | Sort-Object Name | ForEach-Object {$_.Name}
```

**Get specific package**

```powershell
Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} | Select-Object -ExpandProperty Name
```

[Reference App Management](https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10)

[Reference Get-AppxPackage](https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps)

**Get app details**

```powershell
(Get-AppxPackage -Name "*Yourphone*" | Get-AppxPackageManifest).Package.Capabilities
```

**Update store apps**
```powershell
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
```

OR

```powershell
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod
```

# Get users and computer name

**List all users**

```powershell
Get-WmiObject -Class Win32_UserAccount
[Enum]::GetValues([System.Security.Principal.WellKnownSidType])
```

**List only users**

```powershell
Get-LocalGroupMember -name users
```

```powershell
Get-LocalGroupMember -Group "Users"
```

**Only Administrators**

```powershell
Get-LocalGroupMember -Group "Administrators"
```

**Prompt user for info**

```powershell
Get-Credential
```

**Computer information**

```powershell
Get-WMIObject -class Win32_ComputerSystem
```

**Curently loged in user**

user name, prefixed by its domain\
```powershell
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```

**Well known SID's**
```powershell
$group = 'Administrators'
$account = New-Object System.Security.Principal.NTAccount($group)
$sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
```

OR

```powershell
[System.Security.Principal.WellKnownSidType]::NetworkSid
```

**Computer name**

```powershell
[System.Net.Dns]::GetHostName()
```

```powershell
Get-WMIObject -class Win32_ComputerSystem | Select-Object -ExpandProperty Name
```

# Get CIM classes and commandlets

```powershell
Get-CimClass -Namespace root/CIMV2 | Where-Object CimClassName -like Win32* | Select-Object CimClassName
```

```powershell
Get-Command –module CimCmdlets
```

# Get type name aliases

```powershell
[PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get
```

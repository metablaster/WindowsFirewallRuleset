
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

```Get-AppxPackage -PackageTypeFilter Main | Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | Sort-Object Name | ForEach-Object {$_.Name}```

**List all provisioned Windows apps**

Not directly useful, but returns a few more packages than `Get-AppxPackage -PackageTypeFilter Bundle`

```Get-AppxProvisionedPackage -Online | Sort-Object DisplayName | Format-Table DisplayName, PackageName```

**Lists the app packages that are installed for specific user account on the computer**

```Get-AppxPackage -User User -PackageTypeFilter Bundle | Sort-Object Name | ForEach-Object {$_.Name}```

**Get specific package**

```Get-AppxPackage -User User | Where-Object {$_.PackageFamilyName -like "*skype*"} | Select-Object -ExpandProperty Name```

[Reference App Management](https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10)

[Reference Get-AppxPackage](https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps)

# Get users and computer name

**List all users**

```Get-WmiObject -Class Win32_UserAccount```

**List only users**

```Get-LocalGroupMember -name users```

```Get-LocalGroupMember -Group "Users"```

**Only Administrators**

```Get-LocalGroupMember -Group "Administrators"```

**Prompt user for info**

```Get-Credential```

**Computer information**

```Get-WMIObject -class Win32_ComputerSystem```

**Curently loged in user**

user name, prefixed by its domain\
```[System.Security.Principal.WindowsIdentity]::GetCurrent().Name```

**Computer name**

```[System.Net.Dns]::GetHostName()```

```Get-WMIObject -class Win32_ComputerSystem | Select-Object -ExpandProperty Name```

# Quick Start Guide

This guide provides several simple examples for how to use this module.
For more information on the commands in this module,
please see the [Module Documentation][ModuleDocs].

[ModuleDocs]: ./Module/WindowsCompatibility.md

## View the Windows Event Log in PowerShell Core

```powershell
Import-WinModule Microsoft.PowerShell.Management
Get-EventLog -Newest 5 -LogName "Application"
```

## View the Windows Event Log on a Remote Computer

```powershell
$Credential = Get-Credential
Initialize-WinSession -ComputerName SQLSERVER01 -Credential $Credential
Import-WinModule Microsoft.PowerShell.Management
Get-EventLog -Newest 5 -LogName "Application"
```

## Create a Windows PowerShell Function in PowerShell Core

```powershell
Add-WinFunction -FunctionName Get-WinPSVersion -ScriptBlock {
    $PSVersionTable
}
Get-WinPSVersion
```

## Run a Command in Windows PowerShell from PowerShell Core

```powershell
Invoke-WinCommand -ScriptBlock { $PSVersionTable }
```

## Compare Modules in Windows PowerShell and PowerShell Core

```powershell
Compare-WinModule
```

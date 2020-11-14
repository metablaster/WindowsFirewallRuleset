---
Module Name: WindowsCompatibility
Module Guid: 9d427bc5-2ae1-4806-b9d1-2ae62461767e
Download Help Link:
Help Version: 0.0.0.1
Locale: en-US
---

# WindowsCompatibility Module

## Description

This module provides PowerShell Core 6 compatibility with existing Windows PowerShell scripts.

## WindowsCompatibility Cmdlets

### [Add-WindowsPSModulePath](Add-WindowsPSModulePath.md)

Appends the existing Windows PowerShell PSModulePath to existing PSModulePath

### [Add-WinFunction](Add-WinFunction.md)

This command defines a global function that always runs in the compatibility session.

### [Compare-WinModule](Compare-WinModule.md)

Compare the set of modules for this version of PowerShell against those available in the compatibility session.

### [Copy-WinModule](Copy-WinModule.md)

Copy modules from the compatibility session that are directly usable in PowerShell Core.

### [Get-WinModule](Get-WinModule.md)

Get a list of the available modules from the compatibility session

### [Import-WinModule](Import-WinModule.md)

Import a compatibility module.

### [Initialize-WinSession](Initialize-WinSession.md)

Initialize the connection to the compatibility session.

### [Invoke-WinCommand](Invoke-WinCommand.md)

Invoke a ScriptBlock that runs in the compatibility runspace.

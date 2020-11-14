---
external help file: WindowsCompatibility-help.xml
Module Name: WindowsCompatibility
online version:
schema: 2.0.0
---

# Add-WindowsPSModulePath

## SYNOPSIS

Appends the existing Windows PowerShell PSModulePath to existing PSModulePath

## SYNTAX

```
Add-WindowsPSModulePath [<CommonParameters>]
```

## DESCRIPTION

If the current PSModulePath does not contain the Windows PowerShell PSModulePath,
it will be appended to the end.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-WindowsPSModulePath
Import-Module Hyper-V
```

### EXAMPLE 2

```powershell
Add-WindowsPSModulePath
Get-Module -ListAvailable
```

## PARAMETERS

## INPUTS

### None.

## OUTPUTS

### None.

## NOTES

## RELATED LINKS

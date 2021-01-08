---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Shortcut.md
schema: 2.0.0
---

# Set-Shortcut

## SYNOPSIS

Set desktop or online shortcut

## SYNTAX

### Local

```powershell
Set-Shortcut [-Name] <String> -Path <DirectoryInfo> -TargetPath <FileInfo> [-IconLocation <FileInfo>]
 [-IconIndex <Int32>] [-Description <String>] [-Hotkey <String>] [-WindowStyle <String>]
 [-WorkingDirectory <FileInfo>] [-Arguments <String>] [-Admin] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Online

```powershell
Set-Shortcut [-Name] <String> -Path <DirectoryInfo> -URL <Uri> [-IconLocation <FileInfo>] [-IconIndex <Int32>]
 [-Hotkey <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Create or set shortcut to file or online location.
Optionally set shortcut properties such as the icon, hotkey or description.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-Shortcut -Path "$env:Home\Desktop\test.lnk" -TargetPath "C:\Windows\program.exe"
```

### EXAMPLE 2

```powershell
Set-Shortcut -Path "$env:Home\Desktop\test.lnk" -TargetPath "C:\Windows\program.exe" -Admin -Index 16
```

## PARAMETERS

### -Name

The name of a schortcut file, optionally with an extension.
Use the .lnk extension for a file system shortcut.
Use the .url extension for an Internet shortcut.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

The full path (excluding file name) to location of the shortcut file you want to create.
Alternatively one of the following keywords can be specified:
"AllUsersDesktop"
"AllUsersStartMenu"
"AllUsersPrograms"
"AllUsersStartup"
"Desktop"
"Favorites"
"Fonts"
"MyDocuments"
"NetHood"
"PrintHood"
"Programs"
"Recent"
"SendTo"
"StartMenu"
"Startup"
"Templates"

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPath

The full path and filename of the location that the shortcut file will open.

```yaml
Type: System.IO.FileInfo
Parameter Sets: Local
Aliases: Source

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -URL

URL of the location that the shortcut file will open.

```yaml
Type: System.Uri
Parameter Sets: Online
Aliases: Link

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IconLocation

Full pathname of the icon file to set on shortcut.

```yaml
Type: System.IO.FileInfo
Parameter Sets: (All)
Aliases: Icon

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IconIndex

Index is the position of the icon within the file (where the first icon is 0)

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases: Index

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

Specify description of the shortcut

```yaml
Type: System.String
Parameter Sets: Local
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hotkey

A string value of the form "Modifier + Keyname",
where Modifier is any combination of Alt, Ctrl, and Shift, and Keyname is one of A through Z or 0 through 12.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WindowStyle

Specify how the application window will appear

```yaml
Type: System.String
Parameter Sets: Local
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkingDirectory

Sets the path of the shortcut's working directory

```yaml
Type: System.IO.FileInfo
Parameter Sets: Local
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Arguments

Optionally set arguments to target file

```yaml
Type: System.String
Parameter Sets: Local
Aliases: ArgumentList

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Admin

If specified, the shortcut is run as Administrator

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Local
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Set-Shortcut

## OUTPUTS

### None. Set-Shortcut does not generate any output

## NOTES

None.

## RELATED LINKS

---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Search-Installation.md
schema: 2.0.0
---

# Search-Installation

## SYNOPSIS

Find installation directory for given predefined program name

## SYNTAX

```powershell
Search-Installation [-Application] <TargetProgram> [-Domain <String>] [<CommonParameters>]
```

## DESCRIPTION

Search-Installation is called by Confirm-Installation, ie.
only if test for existing path
fails then this method kicks in

## EXAMPLES

### EXAMPLE 1

```powershell
Search-Installation "Office"
```

### EXAMPLE 2

```powershell
Search-Installation "VSCode" -Domain Server01
```

## PARAMETERS

### -Application

Predefined program name

```yaml
Type: TargetProgram
Parameter Sets: (All)
Aliases: Program
Accepted values: dotnet, CMake, SQLDTS, SqlManagementStudio, WindowsDefender, NuGet, NETFramework, vcpkg, SysInternals, WindowsKits, WebPlatform, XTU, Chocolatey, ArenaChess, GoogleDrive, RivaTuner, Incredibuild, Metatrader, RealWorld, qBittorrent, OpenTTD, EveOnline, DemiseOfNations, CounterStrikeGO, PinballArcade, JavaUpdate, JavaRuntime, AdobeARM, AdobeReader, AdobeAcrobat, LoLGame, FileZilla, PathOfExile, HWMonitor, CPUZ, MSIAfterburner, GPG, OBSStudio, PasswordSafe, Greenshot, DnsCrypt, OpenSSH, PowerShellCore64, PowerShell64, PowerShell86, OneDrive, HelpViewer, VSCode, MicrosoftOffice, TeamViewer, EdgeChromium, Chrome, Firefox, Yandex, Tor, uTorrent, Thuderbird, Steam, Nvidia64, Nvidia86, GeForceExperience, WarThunder, PokerStars, VisualStudio, VisualStudioInstaller, MSYS2, Git, GitHubDesktop, EpicGames, UnrealEngine, BingWallpaper

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Computer name on which to look for program installation

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Search-Installation

## OUTPUTS

### [bool] true or false if installation directory if found, installation table is updated

## NOTES

None.

## RELATED LINKS

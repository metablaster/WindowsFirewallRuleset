---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Confirm-Installation.md
schema: 2.0.0
---

# Confirm-Installation

## SYNOPSIS

Verify or set program installation directory

## SYNTAX

```powershell
Confirm-Installation [-Program] <TargetProgram> [-Directory] <PSReference> [<CommonParameters>]
```

## DESCRIPTION

Test if given installation directory exists and is valid for firewall, and if not this method will
search system for valid path and return it trough reference parameter.
If the installation directory can't be determined reference variable remains unchanged.

## EXAMPLES

### EXAMPLE 1

```
$MyProgram = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
PS> Confirm-Installation "Office" ([ref] $ProgramInstallPath)
```

## PARAMETERS

### -Program

Predefined program name for which to search

```yaml
Type: TargetProgram
Parameter Sets: (All)
Aliases:
Accepted values: dotnet, CMake, SQLDTS, SqlManagementStudio, WindowsDefender, NuGet, NETFramework, vcpkg, SysInternals, WindowsKits, WebPlatform, XTU, Chocolatey, ArenaChess, GoogleDrive, RivaTuner, Incredibuild, MetaTrader, RealWorld, qBittorrent, OpenTTD, EveOnline, DemiseOfNations, CounterStrikeGO, PinballArcade, JavaUpdate, JavaRuntime, AdobeARM, AdobeReader, AdobeAcrobat, LoLGame, FileZilla, PathOfExile, HWMonitor, CPUZ, MSIAfterburner, GPG, OBSStudio, PasswordSafe, Greenshot, DnsCrypt, OpenSSH, PowerShellCore64, PowerShell64, PowerShell86, OneDrive, HelpViewer, VSCode, MicrosoftOffice, TeamViewer, EdgeChromium, Chrome, Firefox, Yandex, Tor, uTorrent, Thuderbird, Steam, Nvidia64, Nvidia86, GeForceExperience, WarThunder, PokerStars, VisualStudio, VisualStudioInstaller, MSYS2, Git, GitHubDesktop, EpicGames, UnrealEngine, BingWallpaper

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Directory

Reference to variable which should be updated with the path to program installation directory
excluding executable file name.

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Confirm-Installation

## OUTPUTS

### [bool] True if the reference variable contains valid path or was updated, false otherwise.

## NOTES

TODO: ComputerName parameter is missing for remote test

## RELATED LINKS

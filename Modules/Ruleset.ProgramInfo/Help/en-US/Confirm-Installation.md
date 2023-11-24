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

### Domain (Default)

```powershell
Confirm-Installation [-Application] <TargetProgram> [-Directory] <PSReference> [-Domain <String>]
 [-Credential <PSCredential>] [-Interactive] [-Quiet] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Session

```powershell
Confirm-Installation [-Application] <TargetProgram> [-Directory] <PSReference> -Session <PSSession>
 -CimSession <CimSession> [-Interactive] [-Quiet] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Test if given installation directory exists and is valid for firewall, and if not this method will
search system for valid path and return it trough reference parameter.
If the installation directory can't be determined reference variable remains unchanged.

## EXAMPLES

### EXAMPLE 1

```powershell
$MyProgram = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
PS> Confirm-Installation "Office" ([ref] $ProgramInstallPath)
```

## PARAMETERS

### -Application

Predefined program name for which to search

```yaml
Type: TargetProgram
Parameter Sets: (All)
Aliases:
Accepted values: GoogleUpdate, BlueStacks, BlueStacksServices, GooglePlay, calibre, ytdlp, Motrix, LGHUB, nmap, Brave, Psiphon, MSI, EdgeWebView, SteamCMD, Audacity, dotnet, CMake, SqlPath, SqlServer, SqlManagementStudio, WindowsDefender, NuGet, NETFramework, vcpkg, SysInternals, WindowsKits, WebPlatform, OpenSpace, XTU, Chocolatey, ArenaChess, GoogleDrive, RivaTuner, Incredibuild, ColorMania, MetaTrader, RealWorld, AzureDataStudio, qBittorrent, OpenTTD, EveOnline, DemiseOfNations, CounterStrikeGO, PinballArcade, JavaUpdate, JavaRuntime, AdobeARM, AdobeReader, AdobeAcrobat, LoLGame, FileZilla, PathOfExile, HWMonitor, CPUZ, MSIAfterburner, GPG, OBSStudio, PasswordSafe, Greenshot, DnsCrypt, OpenSSH, PowerShellCore64, PowerShell64, PowerShell86, OneDrive, HelpViewer, VSCode, MicrosoftOffice, TeamViewer, EdgeChromium, Chrome, Firefox, Yandex, Tor, uTorrent, Thuderbird, Steam, Nvidia64, Nvidia86, GeForceExperience, WarThunder, PokerStars, VisualStudio, VisualStudioInstaller, MSYS2, Git, GitHubDesktop, EpicGames, UnrealEngine, BingWallpaper

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

### -Domain

Computer name on which to verify for program installation

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession

Specifies the CIM session to use

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: Session
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interactive

If requested program installation directory is not found, Confirm-Installation will ask
user to specify program installation location.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, it suppresses warning, error or informationall messages if user specified or default
program installation directory path does not exist or if it's of an invalid syntax needed for firewall.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Confirm-Installation

## OUTPUTS

### [bool] True if the reference variable contains valid path or was updated, false otherwise

## NOTES

TODO: ComputerName parameter is missing for remote test

## RELATED LINKS

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

### Domain (Default)

```powershell
Search-Installation [-Application] <TargetProgram> [-Domain <String>] [-Credential <PSCredential>]
 [-Interactive] [-Quiet] [<CommonParameters>]
```

### Session

```powershell
Search-Installation [-Application] <TargetProgram> -Session <PSSession> -CimSession <CimSession> [-Interactive]
 [-Quiet] [<CommonParameters>]
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
Accepted values: Psiphon, MSI, EdgeWebView, dotnet, CMake, SqlPath, SqlServer, SqlManagementStudio, WindowsDefender, NuGet, NETFramework, vcpkg, SysInternals, WindowsKits, WebPlatform, OpenSpace, XTU, Chocolatey, ArenaChess, GoogleDrive, RivaTuner, Incredibuild, ColorMania, MetaTrader, RealWorld, AzureDataStudio, qBittorrent, OpenTTD, EveOnline, DemiseOfNations, CounterStrikeGO, PinballArcade, JavaUpdate, JavaRuntime, AdobeARM, AdobeReader, AdobeAcrobat, LoLGame, FileZilla, PathOfExile, HWMonitor, CPUZ, MSIAfterburner, GPG, OBSStudio, PasswordSafe, Greenshot, DnsCrypt, OpenSSH, PowerShellCore64, PowerShell64, PowerShell86, OneDrive, HelpViewer, VSCode, MicrosoftOffice, TeamViewer, EdgeChromium, Chrome, Firefox, Yandex, Tor, uTorrent, Thuderbird, Steam, Nvidia64, Nvidia86, GeForceExperience, WarThunder, PokerStars, VisualStudio, VisualStudioInstaller, MSYS2, Git, GitHubDesktop, EpicGames, UnrealEngine, BingWallpaper

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Computer name on which to search for program installations

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

If requested program installation directory is not found, Search-Installation will ask
user to specify program installation location

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

If specified, it suppresses warning, error or informationall messages if default program
installation directory path does not exist or if it's of an invalid syntax needed for firewall.
Same applies for program path (if found) specified by -Application parameter.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Search-Installation

## OUTPUTS

### [bool] true or false if installation directory if found, installation table is updated

## NOTES

None.

## RELATED LINKS

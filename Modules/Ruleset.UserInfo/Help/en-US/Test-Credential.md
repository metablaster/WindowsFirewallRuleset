---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md
schema: 2.0.0
---

# Test-Credential

## SYNOPSIS

Takes a PSCredential object and validates it

## SYNTAX

```powershell
Test-Credential [-Credential] <PSCredential> -Context <String> [-Domain <String>] [<CommonParameters>]
```

## DESCRIPTION

Takes a PSCredential object and validates it against a domain or local machine

## EXAMPLES

### EXAMPLE 1

```
$Cred = Get-Credential
PS> Test-Credential $Cred -Context Machine
```

### EXAMPLE 2

```
$Cred = Get-Credential
PS> Test-Credential $Cred -Domain Server01 -Context Domain
```

### EXAMPLE 3

```
@($Cred1, $Cred2, $Cred3) | Test-Credential -CN Server01 -Context Domain
```

## PARAMETERS

### -Credential

A PSCredential object with the username/password which is to be tested.
Typically this is generated using the Get-Credential cmdlet.

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Context

Specifies the type of store to which the principal belongs:
Domain:
The domain store.
This represents the AD DS store.
Machine:
The computer store.
This represents the SAM store.
ApplicationDirectory:
The application directory store.
This represents the AD LDS store.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Target computer against which to test local credential object

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

### [PSCredential]

## OUTPUTS

### [bool] true if the credentials are valid, otherwise false

## NOTES

Modifications by metablaster January 2021:
Function interface reworked by removing unnecesarry parameter and changin param block
Simplified logic to validate credential based on context type
Added links, inputs, outputs and notes to comment based help

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md)

[https://github.com/RamblingCookieMonster/PowerShell](https://github.com/RamblingCookieMonster/PowerShell)

[https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.accountmanagement.principalcontext](https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.accountmanagement.principalcontext)


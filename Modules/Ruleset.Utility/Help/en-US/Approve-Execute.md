---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Approve-Execute.md
schema: 2.0.0
---

# Approve-Execute

## SYNOPSIS

Used to prompt user to approve running script

## SYNTAX

### None (Default)

```powershell
Approve-Execute [-Unsafe] [-Title <String>] [-Question <String>] [-Accept <String>] [-Deny <String>] [-Force]
 [<CommonParameters>]
```

### ToAll

```powershell
Approve-Execute [-Unsafe] [-Title <String>] [-Question <String>] [-Accept <String>] [-Deny <String>]
 -YesToAll <PSReference> -NoToAll <PSReference> [-Force] [<CommonParameters>]
```

## DESCRIPTION

In addition to prompt, execution context is shown.
Asking for approval helps to let run master script and only execute specific
scripts, thus loading only needed rules.

## EXAMPLES

### EXAMPLE 1

```powershell
Approve-Execute -Unsafe -Title "Sample title" -Question "Sample question"
```

### EXAMPLE 2

```
[bool] $YesToAll = $false
PS> [bool] $NoToAll = $false
PS> Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
```

## PARAMETERS

### -Unsafe

If specified the command is considered unsafe, and the default action is then "No"

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

### -Title

Prompt title

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "Executing: " + (Split-Path -Leaf $MyInvocation.ScriptName)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Question

Prompt question

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Do you want to run this script?
Accept pipeline input: False
Accept wildcard characters: False
```

### -Accept

Prompt help menu for default action

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Continue with only the next step of the operation
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deny

Prompt help menu for deny action

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Skip this operation and proceed with the next operation
Accept pipeline input: False
Accept wildcard characters: False
```

### -YesToAll

Will be set to true if user selects YesToAll.
If this is already true, Approve-Execute will bypass the prompt and return true.

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: ToAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoToAll

Will be set to true if user selects NoToAll.
If this is already true, Approve-Execute will bypass the prompt and return false.

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: ToAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, this function does nothing and returns true

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

### None. You cannot pipe objects to Approve-Execute

## OUTPUTS

### [bool] True if the user wants to continue, false otherwise

## NOTES

None.

## RELATED LINKS

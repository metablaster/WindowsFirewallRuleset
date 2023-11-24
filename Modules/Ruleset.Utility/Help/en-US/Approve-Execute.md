---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Approve-Execute.md
schema: 2.0.0
---

# Approve-Execute

## SYNOPSIS

Customized user prompt to continue

## SYNTAX

### None (Default)

```powershell
Approve-Execute [-Title <String>] [-Context <String>] [-ContextLeaf <String>] [-Question <String>]
 [-Accept <String>] [-Deny <String>] [-Unsafe] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ToAll

```powershell
Approve-Execute [-Title <String>] [-Context <String>] [-ContextLeaf <String>] [-Question <String>]
 [-Accept <String>] [-Deny <String>] -YesToAll <PSReference> -NoToAll <PSReference> [-YesAllHelp <String>]
 [-NoAllHelp <String>] [-Unsafe] [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Prompt user to continue running script or section of code.
In addition to prompt, an optional execution context can be shown.
Help messages for prompt choices can be optionally customized.
Asking for approval can help to run master script and only execute specific set of scripts.

## EXAMPLES

### EXAMPLE 1

```powershell
Approve-Execute -Unsafe -Title "Sample title" -Question "Sample question"
```

### EXAMPLE 2

```powershell
[bool] $YesToAll = $false
PS> [bool] $NoToAll = $false
PS> Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
```

## PARAMETERS

### -Title

Prompt title

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

### -Context

Optional context to append to the title.
Context is automatically regenerated if the -Title parameter is empty or not set.
Otherwise previous context is reused.

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

### -ContextLeaf

Optional string to append to context.
If not specified, context leaf is automatically generated if both the -Title and -Context parameters
are not set.
Otherwise if -Title is set without -Context this parameter is ignored.

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

Custom help message for "Yes" choice

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

Custom help message for "No" choice

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

### -YesAllHelp

Custom help message for "YesToAll" choice

```yaml
Type: System.String
Parameter Sets: ToAll
Aliases:

Required: False
Position: Named
Default value: Continue with all the steps of the operation
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAllHelp

Custom help message for "NoToAll" choice

```yaml
Type: System.String
Parameter Sets: ToAll
Aliases:

Required: False
Position: Named
Default value: Skip this operation and all subsequent operations
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unsafe

If specified, the command is considered unsafe and the default action is then "No"

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

### -Force

If specified, only module scope last context is set and the function returns true

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

### None. You cannot pipe objects to Approve-Execute

## OUTPUTS

### [bool] True if operation should be performed, false otherwise

## NOTES

TODO: Help messages and question message needs better description to fit more scenarios
TODO: Implement accepting arbitrary amount of choices, ex.
\[ChoiceDescription\[\]\] parameter
TODO: Implement timeout to accept default choice, ex.
Host.UI.RawUI.KeyAvailable
TODO: Standard parameter for help message should be -Prompt

## RELATED LINKS

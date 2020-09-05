---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Approve-Execute.md
schema: 2.0.0
---

# Approve-Execute

## SYNOPSIS
Used to ask user if he wants to run script

## SYNTAX

```
Approve-Execute [[-Default] <String>] [[-Title] <String>] [[-Question] <String>] [[-Accept] <String>]
 [[-Deny] <String>] [<CommonParameters>]
```

## DESCRIPTION
In addition to prompt, execution context is shown.
Asking for approval helps to let run master script and only execute specific
scripts, thus loading only needed rules.

## EXAMPLES

### EXAMPLE 1
```
Approve-Execute "No" "Sample title" "Sample question"
```

## PARAMETERS

### -Default
{{ Fill Default Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Yes
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Title of the prompt

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 3
Default value: Do you want to run this script?
Accept pipeline input: False
Accept wildcard characters: False
```

### -Accept
{{ Fill Accept Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Continue with only the next step of the operation
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deny
{{ Fill Deny Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Skip this operation and proceed with the next operation
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Approve-Execute
## OUTPUTS

### None. true if user wants to continue, false otherwise
## NOTES
None.

## RELATED LINKS

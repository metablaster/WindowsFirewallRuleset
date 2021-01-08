---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-MarkdownLinks.md
schema: 2.0.0
---

# Test-MarkdownLinks

## SYNOPSIS

Test markdown links

## SYNTAX

```powershell
Test-MarkdownLinks [-Path] <String> [-Recurse] [-TimeoutSec <Int32>] [-MaximumRetryCount <Int32>]
 [-RetryIntervalSec <Int32>] [-MaximumRedirection <Int32>] [-SslProtocol <String>] [-NoProxy]
 [<CommonParameters>]
```

## DESCRIPTION

Test each link in markdown file and report if any link is dead

## EXAMPLES

### EXAMPLE 1

```powershell
Test-MarkdownLinks -Path C:\GitHub\MyProject -Recurse
```

### EXAMPLE 2

```powershell
Test-MarkdownLinks -Path C:\GitHub\MyProject -SslProtocol Tls -NoProxy
```

## PARAMETERS

### -Path

The path to directory containing target markdown files

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

### -Recurse

If specified, recurse in to the path specified by Path parameter

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

### -TimeoutSec

Specifies how long the request can be pending before it times out

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumRetryCount

Specifies how many times PowerShell retries a connection when a failure code between 400 and
599, inclusive or 304 is received

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryIntervalSec

Specifies the interval between retries for the connection when a failure code between 400 and
599, inclusive or 304 is received

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumRedirection

Specifies how many times PowerShell redirects a connection to an alternate Uniform Resource
Identifier (URI) before the connection fails.
A value of 0 (zero) prevents all redirection.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -SslProtocol

Sets the SSL/TLS protocols that are permissible for the web request.
This feature was added in PowerShell 6.0.0 and support for Tls13 was added in PowerShell 7.1.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProxy

Indicates the test shouldn't use a proxy to reach the destination.
This feature was added in PowerShell 6.0.0.

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

### None. You cannot pipe objects to Test-MarkdownLinks

## OUTPUTS

### None. Test-MarkdownLinks does not generate any output

## NOTES

WebSslProtocol enum does not list Tls13
TODO: Update time elapsed and remaining when testing links in single file
TODO: Implement parameters for Get-ChildItem

## RELATED LINKS

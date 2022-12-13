
# Ruleset.Test

## about_Ruleset.Test

## SHORT DESCRIPTION

PowerShell unit test module

## LONG DESCRIPTION

Ruleset.Test module is designed for unit testing of "Windows Firewall Ruleset" project

## EXAMPLES

```powershell
Enter-Test
```

Initialize unit test

```powershell
Exit-Test
```

Un-initialize and exit unit test

```powershell
New-Section
```

Print new unit test section

```powershell
Reset-TestDrive
```

Remove all items from test drive

```powershell
Restore-Test
```

Restore disabled error reporting, called only after Start-Test -Force

```powershell
Start-Test
```

Starts test case which prints formatted header

```powershell
Test-MarkdownLink
```

Test links in markdown files

```powershell
Test-Output
```

Verify TypeName and OutputType are referring to same type

## KEYWORDS

- Test
- UnitTest
- PowerShellTest

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Test/Help/en-US

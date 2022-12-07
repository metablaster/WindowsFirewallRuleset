
# Ruleset.Initialize

## about_Ruleset.Initialize

## SHORT DESCRIPTION

Initialize repository development environment

## LONG DESCRIPTION

Ruleset.Initialize module main purpose is automated development environment setup to be able
to perform quick setup on multiple computers and virtual operating systems, in cases such as
frequent system restores for the purpose of testing project code for many environment scenarios
that end users may have.

## EXAMPLES

```powershell
 Find-DuplicateModule
```

Finds duplicate modules installed on system taking care of PS edition being used

```powershell
Initialize-Connection
```

Initialize connection for firewall deployment

```powershell
Initialize-Module
```

Update or install recommended and required modules

```powershell
Initialize-Project
```

Check repository environment requirements

```powershell
Initialize-Provider
```

Update or install package providers required or recommended by this project

```powershell
Initialize-Service
```

Configure and start system services required by this project

```powershell
 Uninstall-DuplicateModule
```

 Uninstalls duplicate modules per PS edition leaving only the most recent versions of a module

```powershell
 Update-ModuleHelp
```

 Updates help files for modules installed with PowerShell edition which is used to run this function

## KEYWORDS

- Initialization
- Environment
- Development

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Initialize/Help/en-US

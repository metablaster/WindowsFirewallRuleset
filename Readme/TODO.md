
# List of stuff that needs to be done

This is a project global list which applies to several or all scripts,
for smaller todo's see individual files

## Modules

### Selected

- Revisit function parameters, their types, aliases etc..
- Change bool parameters to switch where possible
- Revisit naming convention for ConvertFrom/ConvertTo it's not clear
what is being converted, some other functions also have odd names

### High priority

- Revisit code and make consitent PSCustomObject properties for all function outputs
- Need to see which functions/commands may throw and setup try catch blocks
- Revisit parameter validation for functions,
specifically acceptance of NULL or empty

### Medium priority

- make possible to apply rules to remote machine, currently partially supported
- Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
- DefaultParameterSetName for functions with parameter sets is missing
- Revisit how functions return and what they return,
return keyword vs Write-Output, if piping is needed after all
- We probalby don't need VSSetup module
- Line numbers for verbose and debug messages

### Low priority

- Function to check executables for signature and virus total hash
- localhost != `[Environment]::MachineName` because strings are not the same
- Write-Error streams should be extened to include exception record etc.

## Project scripts

### High priority

- Apply only rules for which executable exists, Test-File function
- Implement Importing/Exporting rules
- auto detect interfaces

### Medium priority

- Access is denied randomly while executing rules, need some check around this
- make possible to apply or enable only rules relevant for current firewall profile

### Low priority

- Detect if script ran manually, to be able to reset errors and warning status
- Test already loaded rules if pointing to valid program or service,
also test for weakness
- Count invalid paths in each script
- Measure execution time for each or all scripts.

## Rules

### Selected

- Paths to fix: nvidia, onedrive, visio, project
- rules to fix: qbittorrent, steam, vcpkg, msys2,
store apps for admins, internet browser (auto loads)

### High priority

- Now that common parameters are removed need to update the order of
rule parameters, also not all are the same.

### Medium priority

- some rules are missing comments
- make display names and groups modular for easy search,
ie. group - subgroup, Company - Program

### Low priority

- apply local IP to all rules, as optional feature because it depends if IP is static
- Implement unique names and groups for rules, -Name and -Group paramter vs -Display*

## Code style

### High priority

- Limit code to 80-100 columns rule, subject to exceptoins

## Documentation

### Medium priority

- update FirewallParamters.md with a list of incompatible paramters for reference

## Test and debugging

### High priority

- Convert tests to use Pester if possible or separate them into:
pester tests and experiment tests

### Medium priority

- Move NET.IP tests into test folder, clean up directory add streams

## Other

### Selected

- Take out of deprecated scripts what can be used, remove the rest

### Medium priority

- Do CTRL + F in VSCode and search for "TODO"

### Low priority

- Test for 32bit powershell and OS.

## Never ending TODO's

### Medium priority

- 3rd party scripts and modules need to be checked for updates

## Partially fixed, need testing

### High priority

- Most program query functions return multiple program instances,
need to select latest or add multiple rules.

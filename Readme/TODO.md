
# List of stuff that needs to be done

This is a project global list which applies to several or all scripts,
for smaller todo's see individual files

## Selected (Modules)

- Revisit function parameters, their types, aliases etc..
- Change bool parameters to switch where possible
- Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted,
some other functions also have odd names

## Selected (Rules)

- Paths to fix: nvidia, onedrive, visio, project
- rules to fix: qbittorrent, steam, vcpkg, msys2, store apps for admins,
internet browser (auto loads)

## Selected (Other)

- Take out of deprecated scripts what can be used, remove the rest

## High priority (Modules)

- Revisit code and make consistent PSCustomObject properties for all function outputs
- Need to see which functions/commands may throw and setup try catch blocks
- Revisit parameter validation for functions, specifically acceptance of NULL or empty

## High priority (Project scripts)

- Apply only rules for which executable exists, Test-File function
- Implement Importing/Exporting rules
- auto detect interfaces

## High priority (Rules)

- Now that common parameters are removed need to update the order of rule parameters,
also not all are the same.

## High priority (Code style)

- Limit code to 80-100 columns rule, subject to exceptions

## High priority (Test and debugging)

- Convert tests to use Pester if possible or separate them into:
pester tests and experiment tests
- Some test fail to run in "develop" mode due to missing variables

## High priority (Partially fixed, need testing)

- Most program query functions return multiple program instances,
need to select latest or add multiple rules.

## Medium priority (Modules)

- make possible to apply rules to remote machine, currently partially supported
- Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
- DefaultParameterSetName for functions with parameter sets is missing
- Revisit how functions return and what they return, return keyword vs Write-Output,
if piping is needed after all
- We probably don't need VSSetup module
- Line numbers for verbose and debug messages
- Modules should be imported into global scope

## Medium priority (Project scripts)

- Access is denied randomly while executing rules, need some check around this
- make possible to apply or enable only rules relevant for current firewall profile

## Medium priority (Rules)

- some rules are missing comments
- make display names and groups modular for easy search, ie. group - subgroup, Company - Program

## Medium priority (Documentation)

- update FirewallParameters.md with a list of incompatible parameters for reference

## Medium priority (Test and debugging)

- Move NET.IP tests into test folder, clean up directory add streams

## Medium priority (Other)

- Do CTRL + F in VSCode and search for "TODO"

## Medium priority (Never ending)

- 3rd party scripts and modules need to be checked for updates

## Low priority (Modules)

- Function to check executables for signature and virus total hash
- localhost != `[Environment]::MachineName` because strings are not the same
- Write-Error streams should be extended to include exception record etc.

## Low priority (Project scripts)

- Detect if script ran manually, to be able to reset errors and warning status
- Test already loaded rules if pointing to valid program or service, also test for weakness
- Count invalid paths in each script
- Measure execution time for each or all scripts.

## Low priority (Rules)

- apply local IP to all rules, as optional feature because it depends if IP is static
- Implement unique names and groups for rules, -Name and -Group parameter vs -Display*

## Low priority (Other)

- Test for 32bit powershell and OS.

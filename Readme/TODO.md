
# List of stuff that needs to be done

This is a project global list which applies to several or all scripts.

For smaller TODO's local to specific scripts and files see individual files, for example with
CTRL + F in VSCode and search for "TODO".

If you installed "TODO Tree" extension as discussed in
[CONTRIBUTING.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/CONTRIBUTING.md)
then then this process should be much easier.

Note that some TODO's listed here are are duplicate of TODO's inside individual scripts, this is
intentionally to make is easier to tell where to look at while resolving this list.

TODO's in this file are categorized into following sections:

1. Selected
2. High priority
3. Medium priority
4. Low priority
5. Done

"Selected" means it's currently being worked on.
"Done" obviously means it's done, it's kept here for reference.

## Selected

1. Modules

    - Revisit function parameters, their output types, aliases etc..
    - Change bool parameters to switch where possible
    - Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted,
    some other functions also have odd names

2. Code style

    - Limit code to 100 column rule.

3. Project scripts

    - Take out of deprecated scripts what can be used, remove the rest

## High priority

1. Modules

    - Revisit code and make consistent PSCustomObject properties for all function outputs
    - Need to see which functions/commands may throw and setup try catch blocks
    - Revisit parameter validation for functions, specifically acceptance of NULL or empty

2. Project scripts

    - Apply only rules for which executable exists, Test-File function
    - Implement Importing/Exporting rules
    - auto detect interfaces

3. Rules

    - Paths to fix: nvidia, onedrive, visio, project
    - rules to fix: qbittorrent, steam, vcpkg, msys2, store apps for admins,
    internet browser (auto loads)
    - Now that common parameters are removed need to update the order of rule parameters,
    also not all are the same.

4. Test and debugging

    - Some test fail to run in "develop" mode due to missing variables
    - Need to test rules without "ProgramRoot" variable to see if searching works

5. Partially fixed, need testing

    - Most program query functions return multiple program instances,
    need to select latest or add multiple rules.

## Medium priority

1. Modules

    - make possible to apply rules to remote machine, currently partially supported
    - Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
    - DefaultParameterSetName for functions with parameter sets is missing
    - Revisit how functions return and what they return, return keyword vs Write-Output,
    if piping is needed after all
    - We probably don't need VSSetup module
    - Line numbers for verbose and debug messages
    - Modules should be imported into global scope
    - Use begin/process/end to make functions work on pipeline

2. Project scripts

    - Access is denied randomly while executing rules, need some check around this
    - make possible to apply or enable only rules relevant for current firewall profile
    - Add #Requires -Modules to scripts, possibly removing module inclusions

3. Rules

    - some rules are missing comments
    - make display names and groups modular for easy search, ie. group - subgroup, Company - Program

4. Test and debugging

    - Move NET.IP tests into test folder, clean up directory add streams
    - Convert tests to use Pester if possible or separate them into:
    pester tests and experiment tests
    - What should be initial values for ProgramRoot variables in rule scripts? we should remove
    known non existent paths and handle empty strings to prevent INFO messages for conversion.

5. Documentation

    - update FirewallParameters.md with a list of incompatible parameters for reference
    - a lot of comment based documentation is missing comments

6. Never ending

    - 3rd party scripts and modules need to be checked for updates

## Low priority

1. Modules

    - Function to check executables for signature and virus total hash
    - localhost != `[Environment]::MachineName` because strings are not the same
    - Write-Error streams should be extended to include exception record etc.

2. Project scripts

    - Detect if script ran manually, to be able to reset errors and warning status
    - Test already loaded rules if pointing to valid program or service, also test for weakness
    - Count invalid paths in each script
    - Measure execution time for each or all scripts.

3. Rules

    - apply local IP to all rules, as optional feature because it depends if IP is static
    - Implement unique names and groups for rules, -Name and -Group parameter vs -Display*

4. Code style

    - Separate comment based keywords so that there is one line between a comment and next keyword

5. Other

    - Test for 32bit powershell and OS.

## Done

- Move duplicate and global TODO's from scripts here into global TODO list
- Check spelling for entry project

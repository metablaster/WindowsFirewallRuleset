
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
2. Ongoing
3. High priority
4. Medium priority
5. Low priority
6. Done

"Selected" means it's currently being worked on.
"Ongoing" means never ending or continuous work
"Done" obviously means it's done, it's kept here for reference.

## Selected

1. Modules

    - Revisit function parameters, their output types, aliases etc..
    - Change bool parameters to switch where possible
    - Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted,
    some other functions also have odd names

2. Project scripts

    - Take out of deprecated scripts what can be used, remove the rest

## Ongoing

1. Code style

    - Limit code to 100-120 column rule.

2. Modules

    - 3rd party scripts and modules need to be checked for updates

## High priority

1. Modules

    - Revisit code and make consistent PSCustomObject properties for all function outputs
    - Need to see which functions/commands may throw and setup try catch blocks
    - Revisit parameter validation for functions, specifically acceptance of NULL or empty
    - Registry drilling for some rules are complex and specific, such as for NVIDIA,
    in these and probably most other similar cases we should return installation table which
    would be used inside rule script to get individual paths for individual programs.

2. Project scripts

    - Apply only rules for which executable exists, Test-File function
    - Implement Importing/Exporting rules
    - auto detect interfaces

3. Rules

    - Paths to fix: onedrive, visio, project
    - rules to fix: nvidia, steam, vcpkg, msys2, store apps for admins,
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
    - Add #Requires -Modules to scripts, possibly removing module inclusions, if not
    another possibility is to add module path to our modules for current session.
    - Make $WhatIfPreference for rules, we should skip everything except rules.

3. Rules

    - some rules are missing comments
    - make display names and groups modular for easy search, ie. group - subgroup, Company - Program
    - We need some better and unified approach to write rule descriptions, because it looks ugly
    now, since comments must not be formatted, formatting would be visible in GUI.
    - Some rules apply to both IPv4 and IPv6 such as qBittorrent.ps1, for these we should group them
    into "hybrid" folder instead of IPv4 or IPv6 folder which should be IP version specific rules.

4. Test and debugging

    - Move NET.IP tests into test folder, clean up directory add streams
    - Convert tests to use Pester if possible or separate them into:
    pester tests and experiment tests
    - What should be initial values for ProgramRoot variables in rule scripts? we should remove
    known non existent paths and handle empty strings to prevent INFO messages for conversion.

5. Code style

    - Indentation doesn't work as expected for pipelines, currently using "NoIndentation", and
    there is no indentation for back ticks

6. Documentation

    - update FirewallParameters.md with a list of incompatible parameters for reference
    - a lot of comment based documentation is missing comments

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
    - Many rules are compatible and can be configured to specify platform for Windows 7 or 8

4. Code style

    - Separate comment based keywords so that there is one line between a comment and next keyword

5. Other

    - Test for 32bit powershell and OS.
    - mTail coloring configuration contains gremlins (bad chars), need to test and deal with them.

## Done

- Move duplicate and global TODO's from scripts here into global TODO list
- Check spelling for entry project
- rules to fix: qbittorrent

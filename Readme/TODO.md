
# List of tasks that needs to be done

This is a project global list which applies to several or all scripts.

For smaller todo's local to specific scripts and files see individual files, you can use workspace\
recommended extension `todo-tree` to navigate TODO, HACK and NOTE tags.

Note that some todo's listed here are are duplicate of todo's inside individual scripts, this is\
intentionally for important todo's to make is easier to tell where to look at while resolving this list.

todo's in this file are categorized into following sections:

1. **Ongoing**              Never ending or continuous work
2. **High priority**        Must be resolved ASAP
3. **Medium priority**      Important
4. **Low priority**         Not very important
5. **Done**                 It's done and kept here for reference.

## Table of contents

- [List of tasks that needs to be done](#list-of-tasks-that-needs-to-be-done)
  - [Table of contents](#table-of-contents)
  - [Ongoing](#ongoing)
  - [High priority](#high-priority)
  - [Medium priority](#medium-priority)
  - [Low priority](#low-priority)
  - [Done](#done)

## Ongoing

1. Modules

    - 3rd party scripts and modules need to be checked for updates
    - Find-Installation function is hungry for constant updates and improvements

2. Project scripts

    - Resolving existing and enabling new/disabled analyzer warnings
    - Spellchecking files
    - Move duplicate and global todo's from scripts here into global todo list

3. Code style

    - Limit code to 100-120 column rule.

4. Project release checklist

    - ProgramInfo module manifest, comment out unit test exports
    - ProjectSettings.ps1 disable variables: Develop, ForceLoad,
    - ProjectSettings.ps1 restore variables: UnitTester, UnitTesterAdmin, DefaultUser
    - ProjectSettings.ps1 verify auto updated variables: ProjectCheck, ModulesCheck, ServicesCheck
    - Increment project version in all places mentioning version
    - Run all tests in both release and develop mode, both Desktop and Core editions
    - Load rules on all target OS editions
    - Verify links to repository are pointing to master branch except if develop branch is wanted
    - Run script analyzer

## High priority

1. Modules

    - Revisit code and make consistent PSCustomObject properties for all function outputs, consider
    using formats for custom objects
    - Need to see which functions/commands may throw and setup try catch blocks
    - Revisit parameter validation for functions, specifically acceptance of NULL or empty
    - Registry drilling for some rules are complex and specific, such as for NVIDIA or OneDrive,
    in these and probably most other similar cases we should return installation table which
    would be used inside rule script to get individual paths for individual programs.
    - Revisit function parameters, their output types, aliases etc..
    - Change bool parameters to switch where possible
    - Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted,
    some other functions also have odd names

2. Project scripts

    - Apply only rules for which executable exists, Test-File function
    - Implement Importing/Exporting rules, including rules with no group
    - auto detect interfaces, ie. to be used with InterfaceAlias parameter

3. Rules

    - Paths to fix: visio, project
    - Rules to fix: vcpkg, msys2, store apps for admins, internet browser (auto loads)
    - Now that common parameters are removed need to update the order of rule parameters,
    also not all are the same.
    - Variable to conditionally apply rules for Administrators

4. Test and debugging

    - Some tests fail to run in non "develop" mode due to missing variables
    - Installation variables must be empty in development mode only to be able to test program
    search functions, for release providing a path is needed to prevent "fix" info messages
    - For Write-Debug $PSBoundParameters.Values check if it's in process block or begin block,
    make sure wanted parameters are shown, make sure values are visible instead of object name
    - We should use try/catch in test scripts to avoid writing errors and write information instead,
    So that `Run-AllTests.ps1` gets clean output, not very useful if testing with PS Core since
    -CIM call will fail, see Get-SystemSKU test

5. Code style

    - Need convention for variable naming, such as Group, Groups or User vs Principal, difference is
    that one is expanded property while other can be custom object. Many similar cases for naming.

6. Partially fixed, need testing

    - Most program query functions return multiple program instances,
    need to select latest or add multiple rules.
    - Module functions and rules for OneDrive have partial fix, needs design improvements

7. Other

    - Need convention for output streams, when to use which one, and also common format for quoting
    and pointing out local variables, some place are missing streams while others have too many of them,
    Also somewhere same (ie. debug stream) can be put in 2 places in call stack, which one to chose?
    - Need global setting to allow "advanced" warnings, which will show at a minimum function name
    where the warning was generated, or just save this info to logs.

## Medium priority

1. Modules

    - make possible to apply rules to remote machine, currently partially supported
    - Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
    - DefaultParameterSetName for functions with parameter sets is missing
    - Revisit how functions return and what they return, return keyword vs Write-Output,
    if pipeline support is needed for that function
    - We probably don't need VSSetup module
    - Line numbers for verbose and debug messages
    - Use begin/process/end to make functions work on pipeline
    - Need to add default error description into catch blocks in addition to our own
    for better description
    - Need to check if WinRM service is started when contacting computers via CIM
    - Some functions return multiple return types, how to use [OutputType()]?
    - Modules are named "AllPlatforms" or "Windows" however they contain platform specific or
    non platform specific functions, need to revisit naming convention
    - Functions which use ShouldProcess must not ask for additional input, but use additional
    ShouldProcess instead.
    - Write-Error will fail if -TargetObject is not set, in cases where this is possible we should
    supply string instead. See ComputerInfo\Get-ConfiguredAdapter for example
    - 3rd party modules are not consistent with our own modules regarding folder and structure and
    high level implementation
    - Some function variables such as "ComputerNames" take array or values, make sure this functionality
    actually makes sense, and also for naming consistency for ValueFromPipelineByPropertyName

2. Project scripts

    - Access is denied randomly while executing rules, need some check around this, ex. catching the
    error and ask to re-run the script.
    - make possible to apply or enable only rules relevant for current firewall profile
    - Add #Requires -Modules to scripts to remove module inclusions and load variables
    - Make $WhatIfPreference for rules, we should skip everything except rules.
    - For remote computers need ComputerName variables/parameters, note this could also be
    learned/specified with PolicyStore parameter
    - Select-Object -Last 1 instead of -First 1 to get highest value, need to verify

3. Rules

    - some rules are missing comments
    - make display names and groups modular for easy search, ie. group - subgroup, Company - Program,
    This can also prove useful for wfp state logs to determine blocking rule
    - We need some better and unified approach to write rule descriptions, because it looks ugly
    now, since comments must not be formatted, formatting would be visible in GUI.
    - Some rules apply to both IPv4 and IPv6 such as qBittorrent.ps1, for these we should group them
    into "hybrid" folder instead of IPv4 or IPv6 folder which should be IP version specific rules.
    - We handle mostly client rules and no server rules, same case as with IPv4 vs IPv6
    grouping model, we should define a model for server rules (not necessarily Windows Server,
    workstation PC can also act as server)
    - Rules for programs (ex. userprofile) which apply to multiple users should assign specific
    user to LocalUser instead of assigning user group, there are duplicate todo's in code about this,
    This also implies to todo's about returning installation table to rule scripts!

4. Test and debugging

    - Move NET.IP tests into test folder, clean up directory add streams
    - Many test cases are local to our environment, other people might get different results
    - Test everything on preview Windows
    - Some test outputs will be messed up, ex. some output might be shown prematurely,
    see get-usergroup test for example

5. Code style

    - Indentation doesn't work as expected for pipelines, currently using "NoIndentation", and
    there is no indentation for back ticks
    - We need a script to recursively invoke PSScriptAnalyzer formatter for entry project

6. Documentation

    - update FirewallParameters.md with a list of incompatible parameters for reference
    - a lot of comment based documentation is missing comments
    - FirewallParameters.md contains missing mapping
    - FirewallParameters.md contains no info about compartments and IPSec setup
    - Universal and quick setup to install all required modules for all shells and users.

7. Other

    - Some cmdlets take encoding parameter, we should probably have a variable to specify encoding
    - There are many places where Write-Progress could be useful

## Low priority

1. Modules

    - Function to check executables for signature and virus total hash
    - localhost != `[System.Environment]::MachineName` because strings are not the same
    - Write-Error streams should be extended to include exception record etc.
    - Write-Error categories should be checked, some are inconsistent with error
    - Some executables won't be found in cases where installed program didn't finish installing
    it self but is otherwise present on system, examples such as steam, games with launcher,
    or built in store apps.
    We can show additional information about the failure in the console when this is the case
    - Since the scripts are run as Administrator, we need a way to check who is the actual standard
    user, to be able to check for required modules in user directory if not installed system wide.
    - Checking local or remote computers will be performed multiple times in call stack
    slowing down execution.
    - EXAMPLE comments, at least 3 examples and should be in the form of:
    PS> Get-Something
    Something output
    - User canceling operation should be displayed with warning instead of debug stream

2. Project scripts

    - Detect if script ran manually, to be able to reset errors and warning status
    - Test already loaded rules if pointing to valid program or service, also query rules which are
    missing Local user owner, InterfaceType and similar for improvement
    - Script to scan registry for rules installed by malware or hackers,
    ex. those not consistent with project rules.
    - Count invalid paths in each script
    - Measure execution time for each or all scripts.
    - We use `Set-NetFirewallSetting` but use only a subset of parameters, other parameters are
    meaningful only with IPSec
    - Write a set of scripts for network troubleshooting, such as WORKGROUP troubleshooting
    - Replace -Tags "tag_name" with global variable
    - All streams same convention:
    (ex. doing something $Variable v$Version instead of doing $Variable $Version),
    also same convention regarding variable value quoting with '' single quotes
    - Write a script to add context menus for Windows PowerShell

3. Rules

    - apply local IP to all rules, as optional feature because it depends if IP is static
    - Implement unique names and groups for rules, -Name and -Group parameter vs -Display*
    - Many rules are compatible and can be configured to specify platform for Windows 7 or 8
    - Some executables are not exclusive to all editions of Windows, also some rules such as
    Nvidia drivers won't work in virtual machine since driver was not installed or no hardware access

4. Test and debugging

    - Convert tests to use Pester if possible or separate them into pester tests and experiment tests

5. Code style

    - Separate comment based keywords so that there is one line between a comment and next keyword

6. Documentation

   - ManageGPOFirwall.md contains no documentation
   - Predefined rule list in PredefinedRules.md is out of date

7. Other

    - Test for 32bit powershell and OS, some rules are 64bit OS specific, 32bit specifics may be
    missing
    - mTail coloring configuration contains gremlins (bad chars), need to test and deal with them
    - Important Promt's should probably not depend on $InformationPreference

## Done

1. Modules
    - Importing modules from withing modules should be imported into global scope
    - Versioning of module should be separate from project versioning

2. Project scripts

    - Information output is not enabled for modules and probably other code
    - Use `Get-NetConnectionProfile` to aks user / set default network profile
    - Take out of deprecated scripts what can be used, remove the rest

3. Rules

    - rules to fix: qbittorrent, Steam
    - Rules for NVIDIA need constant updates, software changes are breaking

4. Testing and debugging

    - Need global test variable to set up valid Windows username which is performing tests

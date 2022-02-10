
# List of tasks that needs to be done

This is a global todo list of this repository which applies to several or all scripts.

For smaller todo's local to specific scripts and files see individual files, you can use workspace\
recommended extension `todo-tree` to navigate `TODO`, `HACK` and `NOTE` tags.

Some todo's listed here are duplicate of todo's inside individual scripts, this is intentionally
for important todo's to make is easier to tell where to look at while resolving this list.

Todo's in this file are categorized into following sections:

1. **Ongoing**              Never ending or continuous work
2. **High priority**        Should be resolved ASAP
3. **Medium priority**      Important or worth considering
4. **Low priority**         Not important
5. **Done**                 Already resolved and kept here for reference.

## Table of Contents

- [List of tasks that needs to be done](#list-of-tasks-that-needs-to-be-done)
  - [Table of Contents](#table-of-contents)
  - [Ongoing](#ongoing)
  - [High priority](#high-priority)
  - [Medium priority](#medium-priority)
  - [Low priority](#low-priority)
  - [Done](#done)

## Ongoing

1. Modules

    - 3rd party scripts and modules need to be checked for updates or useful changes
    - `Search-Installation` function is hungry for constant updates and improvements

2. All scripts

    - Resolving existing and enabling new or disabled PScriptAnalyzer warnings
    - Spellchecking files
    - Move duplicate and global todo's from scripts here into global todo list

3. Code style and design

    - Limit code to 100-120 column rule where possible.

4. Release checklist

    - Comment out private function exports in (*.psd1) files
    - Run each module individually with `-Verbose -Debug -Force` and also with
    `Import-Module -Name *.psd1` to ensure expected module load behavior
    - ProjectSettings.ps1 disable variables: Develop, ForceLoad
    - ProjectSettings.ps1 restore variables: TestUser, TestAdmin, DefaultUser, TestDomain
    - ProjectSettings.ps1 verify auto updated variables: ProjectCheck, ModulesCheck, ServicesCheck
    - Increment project version in all places mentioning version:
    (*.psd1, ProjectSettings, CHANGELOG, scripts, New-PSScriptInfo)
    - Run PScriptAnalyzer and resolve issues.
    - Confirm `Deploy-Firewall.ps1` master script calls all rule scripts
    - Test machine should have 2 standard, 2 administrator and 2 MS accounts (one standard one admin),
    and 1 disabled account for each of these 3 groups for best test results.
    - Run all tests in both release and develop mode, both Desktop and Core editions
    - Run master script on all target OS editions
    - Revisit and update `CHANGELOG.md`
    - Revisit and cleanup `TODO.md`
    - Update markdown help and help content, run: `Update-HelpContent.ps1`
    - Verify links to repository are pointing to master except if develop branch is wanted,
    links should be then tested on master branch with `Test-MarkdownLinks.ps1`.
    There are 3 kinds of links to check:\
    WindowsFirewallRuleset/develop\
    WindowsFirewallRuleset/blob/develop\
    WindowsFirewallRuleset/tree/develop
    - Run module manifest test
    - Update software and modules versions in `ProjectSettings.ps1`
    - Cleanup repository:
    - `git clean -d -x --dry-run` `git clean -d -x -f`
    - `git prune --dry-run` `git prune`
    - `git repack -d -F`
    - Generate SHA

5. Documentation

    - Updating documentation, comment based help and rule description
    - Cleanup global and script scope TODO list

6. Test

    - Test everything on Windows insider channels, hopefully catching up with new OS releases

[Table of Contents](#table-of-contents)

## High priority

1. Modules

    - Need to see which functions/commands may throw and setup try catch blocks
    - Revisit parameter validation for functions, specifically acceptance of null or empty
    - Registry drilling for some programs are complex and specific, such as for NVIDIA or OneDrive,
    in these and similar cases we should return installation table which
    would be used within rule scripts to get individual paths for target programs.
    - Finish pipeline support, use begin/process/end blocks to make functions work for pipeline as
    needed, revisit parameter arguments and aliases for this purpose
    - Some function variables such as `ComputerName` take an array of values, make sure this functionality
    actually makes sense, and also for naming consistency for `ValueFromPipelineByPropertyName`
    - If there is `Path` parameter then also `LiteralPath` is required
    - Run `Get-Command -Syntax` for each function and script to verify parameter set names are as expected
    - Compatibility module takes long time to load, need to add streams to module

2. Scripts

    - Auto detect interfaces, ex. to be used with InterfaceAlias parameter
    - null corectness, in specific cases just `if (something)` doesn't work as in other languages,
    ex. `$RegKey.GetValue("name")` may return 0 or "" which is `$false` but valid value.
    - Detect if a script was run manually, to be able to reset errors and warning status, or to
    conditionally run `gpuupdate.exe`
    - Make it possible to deploy firewall to remote computers
    - For remoting `ComputerName` parameters are needed, this could be also
    specified/learned with/from PolicyStore parameter
    - If there is change in remoting parameters PowerShell needs to be restarted, also running
    remoting tests requires change in Domain parameter which is currently mutually exclusive with
    local test cases. This must be avoided so that PS restart is not needed and tests should work.

3. Rules

    - Paths to fix: visio, project
    - Rules to fix: vcpkg, msys2, internet browser (auto loads)
    - Rules to update: nvidia, sql server, steam, visual studio, office
    - Need to update the order of rule parameters to be consistent.
    - Variable to conditionally apply rules for Administrators
    - Rule display name, we need some conventional way to name and to name them uniquely for sortability
    reasons and to make them easy to spot in firewall GUI, `-Name` and `-Group` parameter vs `-Display*`
    - Rules for dropped UDP traffic generated by `System`
    - Some rule defaults are biased or relaxed for troubleshooting purposes, ex. Edge Chromium SSDP,
    such rules should be either removed or explicitly blocking
    - Some programs searches assume userprofile, but same program can also be installed system wide.
    - Need better and unified approach to write rule descriptions, because comments must not be
    formatted, formatting would be visible in GUI.

4. Test and debugging

    - Use try/catch or something similar in test scripts to avoid writing errors and write
    information instead, so that `Run-AllTests.ps1` gets clean output, see `Get-SystemSKU` test
    - Program search test cases should test for either always installed program or certain failure
    - Unit test should have `TestData` which can be used to test pipeline support or to reduce the
    size of unit tests, another benefit is that tests will be easier to update to work on updated data.
    - Some test case outputs will be messed up, ex. some output might be shown prematurely,
    while other won't be shown until 3-4 more test cases run.
    For an example, see `Get-UserGroup` test or `RunAllTests.ps1`

5. Code style and design

    - Revisit functions test for valid implementation of `-Confirm`, `-Force` and `-WhatIf`,
    Confirm for ShouldProcess, Force for ShouldContinue and WhatIf should not do anything.
    For test to be valid, a combination of these parameters should be specified.

6. Partially fixed, need testing and/or improvements

    - Most program query functions return (or could return) multiple program instances,
    need to select latest or add multiple rules.
    - Finish implementation for rule import/export, including rules without group (user made rules)
    - Store app rules for administrators, probably only those that break important functionalities
    - Revisit function parameters, their types, aliases, names are singular, consistent etc..

7. Documentation

    - Remove `?view=powershell-7.1` and similar from reference links

8. Other

    - Need convention for `Write-*` commandlets, when to use which one, and also convention for quoting
    and including local variables in the stream, some places are missing streams while others have
    too many of them.
    Somewhere the same (ie. debug stream) can be put into 2 places in call stack, which one to chose?
    - Need global setting to allow more detailed warnings, which will list at a minimum function name
    where the warning was generated, or this additional data could be logged but not displayed.
    - Any function that depend on "Users" group will fail if there are no users, just Administrator

[Table of Contents](#table-of-contents)

## Medium priority

1. Modules

    - Provide following keywords in function comments: `.COMPONENT` `.ROLE` `.FUNCTIONALITY`
    - `DefaultParameterSetName` for functions with parameter sets is missing but might be desired,
    on another side many functions name default parameter set name to `None` which isn't descriptive.
    - Revisit function return statements, return keyword or Write-Output should be preferred for visibility
    - VSSetup module is likely no longer needed, changes require testing with multiple VS instances
    - Line numbers for verbose and debug messages
    - Use default error (thrown object) description in `catch` blocks instead of custom message if
    possible, see `Set-Permission.ps1`
    - Functions which use `ShouldProcess` must not ask for additional input, but use additional
    ShouldProcess instead.
    - `Write-Error` will fail if `-TargetObject` is not set, in cases where this is possible we should
    supply string instead. See `ComputerInfo\Get-ConfiguredAdapter` for example
    - When drilling registry for programs in user profile we need to load hive for offline
    users into registry, see implementation for OneDrive
    - A few functions (or module) for export/import of configuration into variety of file formats
    - Several module functions and scripts use nested functions, consider converting to either
    scriptblocks or filters.
    - Test each module function as if module only is used, to make sure it's self sufficient, ex.
    `Initialize-Service` function will fail.
    A major issue to solution is module interdependency and dependency on global variables.
    - Module files (*psm1) could generate hashes for scripts to be dot sourced, and compare
    result to predefined hashes to ensure scripts were not modified externally, or sign whole module.
    - For functions which use remoting and call other functions which use remoting there must be
    well established way whether to specify -CIM switch, so that for localhost -CIM is not used

2. Scripts

    - "Access is denied" randomly while loading rules, need some check around this, ex. catching the
    error and ask to re-run the script.
    - Make possible to apply or enable only rules relevant for current firewall profile
    - See if adding `#Requires -Modules` to scripts will help to remove module inclusions and to auto
    load variables
    - Make `$WhatIfPreference` for rules, we should skip everything except rules.
    - Verify `Select-Object -Last 1` is used instead of `-First 1` to get highest value
    - Rules for services, need to check services are networking services, if not write warning,
    could be implemented in `Test-Service` function
    - Parameter HelpMessage for mandatory parameters
    - `Scripts\Remoting` scripts must be part of Ruleset.Initialize module

3. Rules

    - Some rules are missing description
    - Make rule display names and groups modular for easy search, ex. Group - Subgroup,
    Company - Program.
    This can also prove useful for WFP state logs to determine blocking rule.
    - Some rules apply to both IPv4 and IPv6 such as `qBittorrent.ps1`, for these we should probably
    group them into `Hybrid` instead of explicit `IPv4` or `IPv6` directory which are supposed to be
    IP version specific rules.
    - Need to verify rule display group to include IPv4 or IPv6 in cases where these rules
    apply to specific IP version to avoid confusion to which IP these rules apply.
    - We handle mostly client rules and no server rules, same case as with IPv4 vs IPv6
    grouping model, we should define a model for server rules (not necessarily Windows Server,
    workstation PC can also act as a server)
    - Rules for programs (ex. OneDrive in userprofile) which apply to multiple users should assign
    specific user to `-LocalUser` instead of assigning user group, there are duplicate todo's accross
    code about this, this also applies to todo's about returning installation table to rule scripts.
    - If target program does not exist conditionally disable rule and update rule description,
    insert comment into rule name that the rule has no effect, or write a list into separate log file.
    - Rule scripts with multiple rulesets should implement parameters to specify which rulesets to
    load. ex. rule script for PowerShell has rules for Core, Desktop and ISE.

4. Test and debugging

    - Move `Ruleset.IP` tests into test folder, clean up directory add `Write-*` streams
    - Many test cases are local to our environment, other people might get different results
    - There is no test for `Get-Permutation` in `Ruleset.IP`
    - Module `Ruleset.Compatibility` is missing multiple tests
    - Some Pester tests are out of date and don't work well with Pester 5.x
    - A function to detect and confirm file line endings
    - A function to test for duplicate GUID's in scripts that use them

5. Code style and design

    - Indentation doesn't work as expected for pipeline operators, currently using "NoIndentation",
    also there is no indentation for back ticks.
    - Set code regions where applicable

6. Documentation

    - Update `FirewallParameters.md` with a list of incompatible parameters for reference
    - `FirewallParameters.md` contains missing mappings
    - `FirewallParameters.md` contains no info about compartments and IPSec setup
    - Universal and quick setup to install all required modules for all hosts and all users.
    - Modules should have a readme inside their root directory pointing to Help subdirectory, see
    Ruleset.Compatibility for an example, however all language specific files should be inside
    specific language directory.

7. Other

    - There are many places where `Write-Progress` could be useful

[Table of Contents](#table-of-contents)

## Low priority

1. Modules

    - `localhost` != `[System.Environment]::MachineName` because localhost needs to resolve with `WinRM`
    - `Write-Error` streams should be extended to include exception record etc.
    - `Write-Error` categories should be checked, some are inconsistent with the actual error
    - Some executables won't be found in cases where installed program didn't finish installing
    it self but is otherwise present on system, examples such as steam, games with launcher,
    or built in store apps, we can show additional information about the failure in that case.
    - Since the scripts are run as Administrator, we need a way to check who is the actual standard
    user, to be able to check for required modules in user directory if not installed system wide.
    - Checking local or remote computers will be performed multiple times unnecessarily in call stack
    slowing down execution.
    - There should be at least 3 `.EXAMPLE` comments, in the form of:\
    `PS> Get-Something`\
    `Something output`
    - A function or searchable table is needed with a list of executables that don't exist on specific
    editions of Windows to prevent loading rules for missing programs or services.
    - Modules should have updatable help, and, there is no online version for about module topics
    - Need a function to generate a list of files included in module and to perform comparison with
    manifest `FileList` entries
    - Use Module-Qualified Cmdlet Names to avoid name colision
    - Add SHA signature to scripts and modules
    - For completness, specific functions could operate on persistent store firewall, currently
    some functions are GPO only or not tested for persistent store or other stores

2. Scripts

    - Test if already loaded rules are pointing to valid program or service, also functions to query
    rules which are missing `Owner`, `InterfaceType` and similar parameter to easily detect rule
    weaknesses.
    - Script to scan registry for rules installed by malware or hackers,
    ex. those not consistent with project rules.
    - Count invalid paths in each script for statistical purposes
    - Measure execution time for each or all scripts.
    - `Set-NetFirewallSetting` is used, but only with a subset of parameters, other parameters are
    meaningful only with IPSec
    - Write a set of scripts or a module for network troubleshooting, such as `WORKGROUP` troubleshooting
    additionally scripts to generate audit logs and reports.
    - Replace `-Tags "TagName"` with global variable, more granular tags are needed
    - All streams same convention:
    (ex. doing something `$Variable v$Version` instead of doing `$Variable $Version`),
    also same convention regarding quotation of variables with `''` (single quotes)
    - Write a script to add right click context menus for Windows PowerShell
    - Adjust all scripts according to design in templates
    - First time user warnings and notices should be reduced, ex. handled with code if possible
    - Progress line or percentage in script context for master script

3. Rules

    - Apply local IP to all rules, as optional feature because it depends if IP is static
    - Many rules are compatible for older system, and can be configured to specify platform for ex.
    Windows 7 or 8
    - some rules such as Nvidia drivers won't work in virtual machine since driver was not installed
    or no hardware access

4. Test and debugging

    - Convert tests to use Pester if possible or separate them into pester tests and "experiment" tests
    - Testing with `ISE`, different PS hosts and environments
    - Test cases to test templates
    - Some tests are very out of date because rarely useful, ex. `TestProjectSettings` or `TestGlobalVariables`
    - Almost all tests need more test cases and consistency improvements
    - Function to test consistence of comment based help

5. Code style and design

    - For variables with no explicitly decalred type, put "Typename" comment above them from
    `Get-TypeName` or `Get-Member` output
    - After ensuring scripts can't run without edition or version check use newer `$PSEdition`
    instead of older and longer `$PSVersionTable.PSEdition`
    - The "homepage:" comment license notice can be omitted from scripts and replaced with .LINK

6. Documentation

   - `Manage GPO Firwall.md` does not contain enough documentation
   - Predefined rule list in `PredefinedRules.md` is out of date
   - Several rule scripts contain duplicate comments, need to try to keep them in one location and
   and referencing them from other related scripts or single location
   - Markdown documentation should have shorter line width rule than scripts, ex. 80, because not
   everybody has same monitor width and browsers will auto adjust web page.

7. Other

    - Test for 32bit powershell and OS, some rules are x64 OS specific, x86 specifics may be missing
    - `mTail` coloring configuration contains gremlins (bad chars), need to test and deal with them
    - Important Promt's should probably not depend on `$InformationPreference`
    - See how, could we make use of `Plaster` for template generation
    - Just like there is PSScriptAnalyzer to analyse code, there is also a need to develop a script
    or module to analyze code performance.

[Table of Contents](#table-of-contents)

## Done

1. Modules
    - Importing modules from within modules should be imported into global scope
    - Versioning of module should be separate from project versioning
    - Modules are named "AllPlatforms" or "Windows" however they contain platform specific or
    non platform specific functions, need to revisit naming convention
    - Some functions return multiple return types, how to use [OutputType()]?
    - User canceling operation should be displayed with warning instead of debug stream
    - 3rd party modules should be integrated by separating code and generating new GUID
    to avoid confusion due to different versioning and new code
    - Need to check if `WinRM` service is started when contacting computers via CIM
    - 3rd party modules are not consistent with our own modules
    - There are breaks missing for switches all over the place
    - Revisit code and make consistent `PSCustomObject` properties for all function outputs, consider
    using [formats][about format] for custom objects
    - Revisit naming convention for ConvertFrom/ConvertTo it's not clear what is being converted,
    some other functions also have dubious names
    - Change bool parameters to switch where possible
    - `Test-Executable` function could optionally check for "virus total" hash

2. Scripts

    - Information output is not enabled for modules and probably other code
    - Use `Get-NetConnectionProfile` to aks user / set default network profile
    - Take out of deprecated scripts what can be used, remove the rest
    - We should add `Scripts` folder to PS scripts path in ProjectSettings
    - Specify on which adapters Windows firewall is filtering data, see option in
    Windows firewall in control panel
    - Apply only rules for installed executables, `Confirm-Executable` function
    - For individual runs of rule scripts we should call `gpupdate.exe`
    - Instead of `Approve-Execute` we should use `ShouldProcess` or `ShouldContinue` passing in
    context variable and setting help if this is possible.
    - Installation variables must be empty in development mode only to be able to force program
    searches, for release providing a path is needed to prevent "path fixed" info messages
    - Need variables that would avoid prompts and set up firewall with minimum user intervention

3. Rules

    - rules to fix: qbittorrent, Steam
    - Rules for NVIDIA need constant updates, software changes are breaking
    - Allow unicast response to multicast traffic option is there but we have multicast specific
    rules, so it is a bad desing since we break the builtin feature, also it's not clear what effects
    does does this option provide.
    - Setting up `WORKGROUP` doesn't work with this firewall
    - Module functions and rules for OneDrive are partially fixed, needs design improvements

4. Testing and debugging

    - Needed global test variable to set up valid Windows username which is performing tests
    - Some tests fail to run in non "develop" mode due to missing variables
    - A lot of pester tests from `Ruleset.IP` module require private function export,
    make sure the rest of a module works fine without these private exports
    - For `Write-Debug`, `$PSBoundParameters.Values` check if it's in process block or begin block,
    make sure wanted parameters are shown, make sure values are visible instead of object name
    - Unit tests for private functions in `Ruleset.Firewall` module are missing
    - Unit tests for `Ruleset.Logging` include scripts are missing (no longer clear what this means,
    it was likely fixed by the way)

5. Documentation

    - `.INPUTS` and `.OUTPUTS` are not well described, these apply only to pipelines
    - Links in markdown files should be handled with reference links instead of inline links with
    relative paths, this way there is a minimum need to update them, also markdown formatting will
    be much easier.
    - Several comment based documentation is either missing comments or comments are out of date.
    - Windows 10 is the last major version

6. Code style and design

    - Separation of comment based keywords so that there is one line between a comment and next keyword
    - Need convention for variable naming, such as Group, Groups or User vs Principal, difference is
    that one can be expanded property and other could be custom object. Many similar cases for naming.
    - A helper script to recursively invoke `PSScriptAnalyzer` formatter for entire repository

7. Other

    - Some cmdlets take encoding parameter, we should probably have a variable to specify encoding
    - `HelpUri` is valid only when there are no `.LINK` entries and when there is no help content installed
    - Need document for naming convention breakdown probably with links to best practices,
    a few similar documents would be great too.

[Table of Contents](#table-of-contents)

[about format]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_format.ps1xml?view=powershell-7

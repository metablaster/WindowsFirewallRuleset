
# How to contribute

You can use this document not only to see how to contribute code but also to prepare yourself to
extend this firewall project for your own personal or corporate needs.

Here is a list of most important things to keep in mind.

## Table of contents

- [How to contribute](#how-to-contribute)
  - [Table of contents](#table-of-contents)
  - [General guidelines](#general-guidelines)
  - [Environment setup](#environment-setup)
  - [Code style](#code-style)
    - [Automatic formatting](#automatic-formatting)
    - [Script desing](#script-desing)
    - [Rule design](#rule-design)
    - [More information](#more-information)
  - [Modules and 3rd party code](#modules-and-3rd-party-code)
  - [Module design](#module-design)
  - [Static analysis](#static-analysis)
  - [Documentation and comments](#documentation-and-comments)
  - [Writing rules](#writing-rules)
  - [Testing code](#testing-code)
  - [Commits and pull requests](#commits-and-pull-requests)
  - [Portability and other systems](#portability-and-other-systems)
  - [Making new scripts or modules](#making-new-scripts-or-modules)
  - [Repository folder structure](#repository-folder-structure)
  - [Final notes and where to start](#final-notes-and-where-to-start)

## General guidelines

It's recommended to read up to date version of this document which is located on "develop" branch
[here][contributing develop]

2 pages below explain general/starting guidelines regarding open source:\
[How to contribute to open source][contribute to open source]\
[Open Source Contribution Etiquette][open source etiquette]

First step is to fork a project:\
[Forking projects][forking projects]

Next if needed, you might want to set up your SSH keys (don't actually do it yet):\
[Connecting to GitHub with SSH][github ssh]

The reason why not to set up SSH keys right away is because for PowerShell I made this tutorial:\
[PowerShell GPG4Win, SSH, posh-git][tutorial]

Regarding license and Copyright practices adopted by this project see:\
[Maintaining file-scope copyright notices][filescope copyright]\
[Requirements under U.S. and E.U. Copyright Law][copyright law]\
[Copyright Notices][copyright notices]

Regarding versioning adopted see:\
[Semantic Versioning 2.0.0][semantic versioning]

Few additional references regarding open source worth reading:\
[Don't "Push" Your Pull Requests][dont push]\
[Painless Bug Tracking][bug tracking]

And references for tools used by this project:\
[PowerShell documentation][powershell docs]\
[Visual Studio Code][vscode docs]

## Environment setup

It is highly recommended to stick with Visual Studio Code, because this project includes settings
specific to Visual Studio Code, aka. "Workspace", these settings include:

1. Code formatting settings which are automatically enforced, and can also be manually applied
2. List of recommended extensions which are automatically listed for installation when you open
project root folder
3. Debugging and code analysis settings which you can use to debug code
4. Settings for recommended extensions, ex. markdown and script formatting
5. Spelling settings such as random good words which would be detected as misspelled.
6. Many other minor workspace settings to improve coding experience

To work with Windows PowerShell quickly in any folder see:
[Windows PowerShell](Readme/WindowsPowerShell.md)

Recommended extensions in workspace are as follows:

1. [TODO tree][extension todo-tree]

    Required to easily navigate TODO, HACK and NOTE comments located in source files.

2. [PowerShell][extension powershell]

    Should be obvious, syntax highlighting, intellisense, formatting etc.

3. [Markdownlint][extension markdownlint]

    Helps to format and write better markdown, you get a list of problems in VSCode and fix them.

4. [Code Spell Checker][extension spellcheck]

    Helps to spell words correctly, you get a list of misspelled words in VSCode and fix them

5. [Highlight Dodgy Characters][extension gremlins]

    Helps to detect bad chars aka. gremlins, which cause issues such as unable to save file
    in UTF-8 format

6. [Bookmarks][extension bookmarks]

    Helps you to bookmark various places in project to easily navigate back and forth.

7. [Rainbow CSV][extension csv]

    Firewall rules can be exported into CSV file, this extension provides syntax highlighting for
    CSV files

8. [GitLens][extension gitlens]

    It provides so many great features for git inside VSCode it can't be explained in one line

9. [Markdown All in One][extension markdown aio]

    Provides markdown language features

10. [XML Tools][extension xml]

    Useful module xml files navigation

11. [Log File Highlighter][extension logs]

    Custom syntax highlighting for log files, useful for firewall logs as an alternative of mTail.
    This extension complements "Auto Scroll"

12. [Auto Scroll][extension scroll]

    Automatic scrolling of log files, useful to tail firewall logs.
    This extension complements "Log File Highlighter"

13. [Filter Line][extension filterline]

    Filter log files according to json config, string or regex pattern

The continuation of before mentioned link for PowerShell, gpg, ssh etc. is to visit `Config\ProjectSettings.ps1`
located in project root directory, at a minimum you should set following variables to `$true`
before doing anything else:

1. Develop
2. ProjectCheck
3. ModulesCheck
4. ServicesCheck
5. ErrorLogging
6. WarningLogging

Note that some of these may be auto adjusted after setting `Develop` to `$true`\
Then restart PowerShell and run `.\SetupFirewall.ps1` to apply firewall, or at least run
`Initialize-Project` function which will prompt you to perform recommended and required checks.

Detailed description of variables is located in `Config\ProjectSettings.ps1`

After project was intialized `ProjectCheck` variable should be disabled, logging variables can be
disabled too.

If you don't have this environment setup, you'll have to do this some other way around for your
code editor and the rest of environment.

## Code style

### Automatic formatting

This workspace includes code formatting settings, which means you don't have to spend time formatting
source files manually, otherwise it's enough to right click into VSCode and select "Format document".

Lines should be kept within 100-120 columns, however it is not always practical, so it's not a hard
rule, workspace settings are configured to show rulers inside code editor.

If you use some other code editor you should configure it according to these rules which are found
in `.vscode`, `Config` and project root directory.

Not everything is automatically formatted, in short:\
Use **PascalCase** for variables, types, symbols etc; **lowercase** for language keywords,
for more info about type casing run:

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | Sort-Object Key
```

### Script desing

All of the scripts should use the same code style and order of code,
without writing a long list of preferred code style\
it should be enough to take a look at the existing scripts and figure it out right away.

Use following command to see allowed verbs to name your functions

```powershell
Get-Verb | Select-Object Verb, Group, Description | Sort-Object Verb
```

The order of code in scripts is ordered into "sections" which depends on purpose,\
in the following way and may be different if needed for what ever reason:

1. License notice
2. Comment based help
3. Initialization
4. Imports (ex. modules and scripts)
5. User input
6. Local variables (ex. default installation directories)
7. Removal of exiting rules / Unit test startup etc..
8. Rules / functions / code etc..

### Rule design

Each firewall rule uses exactly the same order of parameters split into exactly the same number of lines.\
This is so that when you need to change or search for something or do some regex magic then it's
easy to see what is where, easy to use advanced search/replace or multicursor tricks.

Performing regex operations on firewall rules in combination with multicursor feature can be
done in a matter of minutes, without this strict rule design it would take an entry day and might
result in bugs or security issues!

### More information

Following link explains must know style guidelines to write functions and commandlets:\
[Cmdlet Development Guidelines][develop cmdlets]

Following link describes general rules about PowerShell code style if you like reading,
however keep in mind, it's not completely in line with this repository best practices:\
[The PowerShell Style Guide][powershell style]

## Modules and 3rd party code

Repository contains few custom modules of various type grouped by relevance on
what the module is supposed to expose.

Try to limit dependency on 3rd party modules.\
Existing modules should be extended and new written by using Powershell only if possible.

Only if this is not enough we can try to look for 3rd party modules which could be
easily customized without too much change or learning curve.

3rd party code/scripts are dot sourced into existing modules instead of copy pasted into module
directly, this must be so, to easily see to which file does license/Copyright apply in full.

## Module design

Rules for code in modules is different, most important is to keep each function in it's own script,
separated into Public/Private folders, this is required for 2 valid reasons:

1. To perform tests on private functions without exporting them from module
2. For organizational purposes, to make it easy to maintain and navigate modules.

Module naming convention which are part of this project is simple:

`Ruleset.ModulePurpose`

For example:

1. `Ruleset.ComputerInfo`
2. `Ruleset.Utility`

3rd party modules must not follow this naming convention, that's what word "Ruleset" means here,
to distinguish project modules from 3rd party code.

## Static analysis

[PSStaticAnalyzer][module psscriptanalyzer] is used to perform basic code quality analysis.

VSCode workspace includes static analysis settings file, so all you have to do is cd into project
root directory and invoke analyzer as follows:

```powershell
Invoke-ScriptAnalyzer -Path .\ -Recurse -Settings Config\PSScriptAnalyzerSettings.psd1
```

`PSScriptAnalyzerSettings.psd1` settings file includes all rules, including code formatting rules.

If you get an error such as:\
`Invoke-ScriptAnalyzer: Object reference not set to an instance of an object.`\
then try again and keep repeating until OK.

## Documentation and comments

Documentation and comments reside in 6 places as follows:

1. In scripts (code comments)

    Sections of code should be documented as shown in existing scripts.\
    To comment on things that need to be done add "TODO:" + comment,
    similarly for important notes add "NOTE:" + comment.

    For things which are hard to resolve add "HACK:" + comment, and optionally some links such as
    github issues that may help to resolve problem in the future.

    For any generic code comments you might want to add, use line comments (preferred) and
    block comments only if comment spans 10 or more lines.

2. In rules (rule description)

    It is important that each firewall rule contains good description of it's purpose,
    when the user clicks on rule in firewall GUI he/she wants to see what this rule is about and
    easily conclude whether to enable/disable rule or allow/block network traffic.

3. In command line prompts (current execution help)

    Every script that's being executed either directly or called by other script will not run
    until the user accepts the prompt to run script.

    Each of these prompts have `?` which the user can type to get more information about prompt choices.

4. In comment based help (module main documentation source)

    Functions that are part of a module must have comment based help.\
    Purpose of comment based help is for module user to be able to run `Get-Help` on target function.

    For examples and comment based syntax see:
    - [About Comment-based Help][about comment based help]
    - [Examples of Comment-Based Help][comment based help examples]

    You must avoid following comment based content to avoid errors while generating online help files:
    - .LINK entries must contains only one link and nothing else
    - Avoid dashes in comments such as `------`

5. In module Help folder (module online documentation)

    The `Scripts` folder contains `UpdateHelp.ps1` which when run will scan comment based help and
    generate online documentation for `Get-Help -Online` and help content for `Update-Help` on
    target module.

    Generated module documentation is of markdown format, meaning the 3rd purpose is that project
    users and repository visitors can read module documentation on github site.

6. In Readme folder (general project documentation)

    The `Readme` folder in repository root contains random documentation that covers wide range of
    aspects such as troubleshooting, todo list, FAQ, changelog and general project documentation.

In general regarding firewall rules, provide documentation and official reference for your rules
so that it can be easy to verify that these rules don't contain mistakes, for example, for ICMP
rules you would provide a link to [IANA][iana] with relevant reference document.

Remember, documenting code and features is as important as writing it!

## Writing rules

It is important that a rule is very specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.

For example just saying: allow TCP outbound port 80 for any address or any user or
no explanation what is this supposed to allow or block is not acceptable.

## Testing code

Each function should have it's own test script and each test should cover as much code/test
cases as possible, making changes to exiting code can then be easily tested.\
If test case/concept expands to several functions or if it's completely
unrelated to functions it should be a separate test.

All tests reside in "Test" folder which contains subfolders for each module,
take a look there for examples.

Pester is preferred method to write tests, however some testings needs other way around, or
more specialized setup.

There is a module called "Ruleset.Test", which is customized for this project.\
Tests must pass both Desktop and Core editions of PowerShell to be successful

A hint to quickly run any function from any project module is to run following command in ex.
integrated terminal in VSCode (assuming PowerShell prompt is at project root):

```powershell
Config\ProjectSettings
```

This will add all repository `Modules` to current session module path

## Commits and pull requests

Push small commits that solve or improve single or specific problem,
to reduce merge conflicts and to be able to do `git revert` for specific stuff.

Do not wait too much to push large commits which are not clear enough in terms
of what issue is supposed to be resolved or which component was improved.

If you see something unrelated that could be resolved, put TODO commont, don't fix it.\
Then once you commit open todo-tree to review what to do next.

**Avoid making huge changes to existing code** without first discussing the matter,
new code and additions is not problem though.

## Portability and other systems

At the moment the focus is on Windows Firewall, if you want to port code to other firewalls go ahead.

If you decide to port code it is mandatory that these code changes are done on separate branch.

The plan is to expand this project to manage [nftables][nftables]
firewall on linux and other systems.

## Making new scripts or modules

Inside `Templates` folder there are few template scripts as a starting point.\
Copy them to target location, update starting code and you're ready to start writing.

These templates are fully aligned to rule design, code and formatting style of this project.

## Repository folder structure

See [Directory Structure](Readme/DirectoryStructure.md)

## Final notes and where to start

Please keep in mind that large amount of existing code is not in line with all the guidelines
described here, significant portion of code was written before this "CONTRIBUTING" file even existed.

So it's an ongoing effort that by no means gets fulfilled.

I recommend you start at looking into [TODO](Readme/TODO.md) list and also use "todo-tree"
extension to see even more todo's, unless you have specific ideas or recommendations.

[contributing develop]: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/CONTRIBUTING.md "latest CONTRIBUTING.md"
[contribute to open source]: https://opensource.guide/how-to-contribute "How to contribute to open source"
[open source etiquette]: https://tirania.org/blog/archive/2010/Dec-31.html "Open Source Contribution Etiquette"
[forking projects]: https://guides.github.com/activities/forking "Forking projects"
[github ssh]: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/connecting-to-github-with-ssh "Connecting to GitHub with SSH"
[tutorial]: https://gist.github.com/metablaster/52b1baac5be44e2f1e6d16800813f42f "Tutorial git, powershell, gpg4win, posh-git, commit signing, ssh and key caching"
[filescope copyright]: https://softwarefreedom.org/resources/2012/ManagingCopyrightInformation.html#maintaining-file-scope-copyright-notices "Maintaining file-scope copyright notices"
[copyright law]: http://softwarefreedom.org/resources/2007/originality-requirements.html "Requirements under U.S. and E.U. Copyright Law"
[copyright notices]: https://www.gnu.org/prep/maintain/html_node/Copyright-Notices.html "Copyright Notices"
[semantic versioning]: https://semver.org "Semantic Versionsing"
[dont push]: https://www.igvita.com/2011/12/19/dont-push-your-pull-requests "Don't 'Push' Your Pull Requests"
[bug tracking]: https://www.joelonsoftware.com/2000/11/08/painless-bug-tracking "Painless Bug Tracking"
[powershell docs]: https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs?view=powershell-7.1 "PowerShell documentation"
[vscode docs]: https://code.visualstudio.com/docs "Visual Studio Code documentation"
[extension todo-tree]: https://marketplace.visualstudio.com/items?itemName=Gruntfuggly.todo-tree "Visit Marketplace"
[extension powershell]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell "Visit Marketplace"
[extension markdownlint]: https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint "Visit Marketplace"
[extension spellcheck]: https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker "Visit Marketplace"
[extension gremlins]: https://marketplace.visualstudio.com/items?itemName=nachocab.highlight-dodgy-characters "Visit Marketplace"
[extension bookmarks]: https://marketplace.visualstudio.com/items?itemName=alefragnani.Bookmarks "Visit Marketplace"
[extension csv]: https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv "Visit Marketplace"
[extension gitlens]: https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens "Visit Marketplace"
[extension markdown aio]: https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one "Visit Marketplace"
[extension xml]: https://marketplace.visualstudio.com/items?itemName=DotJoshJohnson.xml "Visit Marketplace"
[extension logs]: https://marketplace.visualstudio.com/items?itemName=emilast.LogFileHighlighter "Visit Marketplace"
[extension scroll]: https://marketplace.visualstudio.com/items?itemName=pejmannikram.vscode-auto-scroll "Visit Marketplace"
[extension filterline]: https://marketplace.visualstudio.com/items?itemName=everettjf.filter-line "Visit Marketplace"
[develop cmdlets]: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines?view=powershell-7 "Visit documentation"
[powershell style]: https://poshcode.gitbooks.io/powershell-practice-and-style/Style-Guide/Introduction.html
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
[about comment based help]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7 "Visit documentation"
[comment based help examples]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7 "Visit documentation"
[iana]: https://www.iana.org "Internet Assigned Numbers Authority (IANA)"
[nftables]: https://en.wikipedia.org/wiki/Nftables "Visit nftables wiki"

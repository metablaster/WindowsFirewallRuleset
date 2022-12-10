
# How to contribute

This document provides details on how to contribute code or to prepare yourself to extend this
firewall for your own needs.

## Table of Contents

- [How to contribute](#how-to-contribute)
  - [Table of Contents](#table-of-contents)
  - [General guidelines](#general-guidelines)
  - [Environment setup](#environment-setup)
    - [Recommended workspace extensions](#recommended-workspace-extensions)
    - [Repository settings](#repository-settings)
  - [Code style](#code-style)
    - [Automatic formatting](#automatic-formatting)
    - [Development Guidelines](#development-guidelines)
    - [Naming convention](#naming-convention)
    - [Script design](#script-design)
    - [Rule design](#rule-design)
    - [Module design](#module-design)
  - [Static analysis](#static-analysis)
  - [Documentation and comments](#documentation-and-comments)
    - [In scripts (code comments)](#in-scripts-code-comments)
    - [In rules (rule description)](#in-rules-rule-description)
    - [In command line prompts (current execution help)](#in-command-line-prompts-current-execution-help)
    - [In comment based help (module and script main documentation source)](#in-comment-based-help-module-and-script-main-documentation-source)
    - [In module Help directory (module online documentation)](#in-module-help-directory-module-online-documentation)
    - [In docs directory (general project documentation)](#in-docs-directory-general-project-documentation)
  - [Writing rules](#writing-rules)
  - [Testing code](#testing-code)
  - [Debugging](#debugging)
    - [Debugging without a virtual machine](#debugging-without-a-virtual-machine)
    - [Debugging with Remote-SSH VSCode extension in virtual machine](#debugging-with-remote-ssh-vscode-extension-in-virtual-machine)
  - [Commits and pull requests](#commits-and-pull-requests)
  - [Portability and other systems](#portability-and-other-systems)
  - [Making new scripts or modules](#making-new-scripts-or-modules)
  - [Repository directory structure](#repository-directory-structure)
  - [Where to start](#where-to-start)

## General guidelines

Here is a list of most relevant things to keep in mind.

It's recommended to read up to date version of this document which is located on "develop" branch
[here][contributing develop]

Following 2 pages below explain general/starting guidelines regarding open source:\
[How to contribute to open source][contribute to open source]\
[Open Source Contribution Etiquette][open source etiquette]

First step is to fork a project:\
[Forking a repo][Forking a repo]

Next if needed, you might want to set up your SSH keys:\
[Connecting to GitHub with SSH][github ssh]

Following optional tutorial may help you setting up git for PowerShell:\
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

For quick markdown referencesee:\
[Mastering Markdown][markdown mastering]\
[Markdown Style Guide][markdown style]\
[Markdown tables generator][markdown tables]

References for tools used by this project:\
[PowerShell documentation][powershell docs]\
[Visual Studio Code][vscode docs]

[Table of Contents](#table-of-contents)

## Environment setup

[![Made for VSCode][badge vscode]][badge vscode link]

It is highly recommended to stick with Visual Studio Code, because this repository includes settings
specific to Visual Studio Code, aka "Workspace", these settings include:

1. Code formatting settings which are automatically enforced, and can also be manually applied
2. List of recommended extensions which are automatically listed for installation once you open\
repository folder with VSCode
3. Debugging and code analysis settings which you can use to debug code
4. Settings for recommended extensions, ex. markdown and script formatting
5. Spelling settings such as random valid words which would be otherwise detected as misspelled.
6. Many other minor workspace settings to improve coding experience

To work with Windows PowerShell quickly in any directory see:
[Windows PowerShell](/docs/WindowsPowerShell.md)

### Recommended workspace extensions

1. [Auto Scroll][extension scroll]

    Automatic scrolling of log files, useful to tail firewall logs.\
    This extension complements `Log File Highlighter` extension above.

2. [Bookmarks][extension bookmarks]

    Helps you to bookmark various places in code to easily navigate various choke points.

3. [Code Spell Checker][extension spellcheck]

    Helps to spell words correctly, you get a list of misspelled words in VSCode and fix them

4. [Filter Line][extension filterline]

    Filter log files according to json config, string or regex pattern

5. [Highlight Bad Chars][extension gremlins]

    Helps to detect gremlins (bad chars), which cause issues such as unable to save file
    in UTF-8 format

6. [Ini for VSCode][extension ini]

    Provides support for `INI` files

7. [Log File Highlighter][extension logs]

    Custom syntax highlighting for log files, useful for firewall logs as an alternative of `mTail`.\
    This extension complements `Auto Scroll` extension below.

8. [Markdown All in One][extension markdown aio]

    Provides markdown language features

9. [Markdownlint][extension markdownlint]

    Helps to format and write better markdown, you get a list of problems in VSCode and fix them.

10. [PowerShell][extension powershell]

    PowerShell syntax highlighting, intellisense, formatting and other language support.

11. [Rainbow CSV][extension csv]

    Firewall rules can be exported into CSV file, this extension provides syntax highlighting for
    CSV files

12. [Remote SSH][extension remote SSH]

    Lets you use any remote machine with a SSH server as your development environment.

13. [Remote SSH editing][extension remote SSH editing]

    This extension complements the `Remote - SSH` extension with syntax colorization,
    keyword intellisense, and simple snippets when editing SSH configuration files.

14. [Remote Explorer][extension remote SSH explorer]

    View remote machines for Remote - SSH in action bar

15. [Select Line Status Bar][extension select line status bar]

    Show count of selected lines in status bar

16. [Sort JSON objects][extension sort json]

    Sorts the keys in selected JSON objects according to selected criteria

17. [Sort Lines][extension sort lines]

    Let's you sort lines in file according to selected criteria

18. [TODO tree][extension todo-tree]

    Required to easily navigate `TODO`, `HACK` and `NOTE` comments located in source files.

19. [Toggle Quotes][extension quotes]

    Toggle single quotes to double or vice versa

20. [Trailing Spaces][extension trailing spaces]

    Highlight trailing spaces and delete them in a flash!

21. [XML][extension xml]

    Useful for xml language support, can also help to detect issues with xml

22. [YAML][extension yaml]

    Useful for xml language support, can also help to detect issues with xml

### Repository settings

Once your environment is set, next step is to visit `Config\ProjectSettings.ps1`
located in repository root directory, at a minimum you should set following variables to `$true`
before doing anything else:

1. Develop
2. ProjectCheck
3. ModulesCheck
4. ServicesCheck
5. ErrorLogging
6. WarningLogging

In addition verify following variables are set to desired user

1. DefaultUser
2. TestAdmin
3. TestUser

Note that some of these may be auto adjusted after setting `Develop` variable to `$true`\
Then restart PowerShell and run `.\Deploy-Firewall.ps1 -Force` to deploy firewall, or at least run
`Initialize-Project` function which will prompt you to perform recommended and required checks.

Detailed description of variables is located in `Config\ProjectSettings.ps1`

Once environment is intialized `$ProjectCheck` variable should be disabled, logging variables can be
disabled too.

If you don't have this environment setup, you'll have to do this some other way around for your
code editor and the rest of environment.

It is recommended to also enable specific development features in Windows which you can find in:\
`Settings -> Update & Security -> For Developers`, there under `File Explorer` apply all settings.

[Table of Contents](#table-of-contents)

## Code style

### Automatic formatting

This workspace includes code formatting settings, which means you don't have to spend time
formatting source files manually, otherwise it's enough to right click into any source file and
select `Format document`.

Lines should be kept within 100-120 columns, however it is not always practical, so it's not a hard
rule, workspace settings are configured to show rulers in code editor.

If you use some other code editor it's recommended you configure it according to these rules which
are found in `.vscode`, `Config` and repository root directory.

[Table of Contents](#table-of-contents)

### Development Guidelines

Following link explains the must know style guidelines to write functions and commandlets:\
[Cmdlet Development Guidelines][develop cmdlets]

Following link describes general rules about PowerShell code style if you like reading,
however keep in mind, it's not completely in line with this repository best practices:\
[The PowerShell Style Guide][powershell style]

Following links may help with exception and error handling:

- [Everything you wanted to know about exceptions][exceptions everything]
- [Our Error Handling - GitHub][exceptions handling]

Use risk mitigation features if applicable for functions that you write, see "Remarks" sections on
the links below to understand how to implement `ShouldProcess` and `ShouldContinue`:

- [Cmdlet.ShouldContinue][should continue]
- [Cmdlet.ShouldProcess][should process]

[Table of Contents](#table-of-contents)

### Naming convention

Not everything is automatically formatted, in short:\
Use **PascalCase** for variables, types, symbols etc. and **lowercase** for language keywords,
for more information about type casing run:

```powershell
[PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | Sort-Object Key
```

Use following command to see allowed verbs to name your functions

```powershell
# PowerShell Core
Get-Verb | Select-Object Verb, Group, Description | Sort-Object Verb

# Windows PowerShell
Get-Verb | Select-Object Verb, Group | Sort-Object Verb
```

For function nouns prefer 1 word or maximum 3 (distinguished by uppercase letters) for example:

- `Invoke-Process`
- `Get-SqlServer`

Sometimes this is not possible, for example `Get-SqlServer` function may collide with existing
PowerShell commandlets, in this case it's better to use 3 words rather than naming your function to
something that doesn't describe it's purpose, ex. `Get-SqlServerInstance` would be fine too,
although such exceptions should be rare.

Noun word must be singular not plural, regardless if input or output is an array of objects.\
For more information about naming see [Naming Convention](/docs/NamingConvention.md)

[Table of Contents](#table-of-contents)

### Script design

All of the scripts should use the same code style and order of code, without writing a long list
of preferred code style it should be enough to take a look at the existing scripts and figure it
out right away.

Code in scripts is ordered into "sections" which depends on script and purpose, in the following
way and may be different if needed for what ever reason:

1. License notice
2. Script info comment (if it's script file)
3. Comment based help
4. Initialization (ex. imports of modules and scripts)
5. User input
6. Script local variables (ex. default installation directories)
7. Removal of exiting rules / Unit test startup etc..
8. Rules / functions / code etc..

[Table of Contents](#table-of-contents)

### Rule design

Each firewall rule uses the same order of parameters split into the same number of lines.\
This is so that when you need to change or search for something or do some regex magic then it's
easy to see what is where, easy to use advanced search/replace or multicursor tricks.

Performing regex operations on firewall rules in combination with multicursor feature can be
done in a matter of minutes, without this strict rule design it would take an entire day and might
result in bugs or random issues.

[Table of Contents](#table-of-contents)

### Module design

Repository contains few custom modules of various purpose, module functionality is grouped by
relevance on what the module is supposed to expose.

Try to limit dependency on 3rd party modules and module code.\
If needed existing modules can be extended or new written without introducing dependencies or new
languages.

Only if this is not enough we can try to look for 3rd party modules which could be
easily customized without too much change or learning curve.

3rd party module scripts or functions should be included into existing modules as scripts instead
of copy pasted into existing code directly, this must be so, to easily see to which file does
license/Copyright apply.

Exception to this rule are complete modules (larger portion of code) which should retain their
directory domain within repository.

Most important is to keep each function in it's own script, separated into Public/Private folders,
this is required for reasons:

1. To perform tests on private functions without exporting them from module
2. For organizational purposes, to make it easy to maintain and navigate module functions.

Module naming convention is simple:

`Ruleset.ModulePurpose`

For example:

1. `Ruleset.ComputerInfo`
2. `Ruleset.Utility`

[Table of Contents](#table-of-contents)

## Static analysis

[PSScriptAnalyzer][module psscriptanalyzer] is used to perform basic code quality analysis.

VSCode workspace includes static analysis settings file, so all you have to do is `cd` into project
root directory and invoke analyzer as follows:

```powershell
Invoke-ScriptAnalyzer -Path .\ -Recurse -Settings Config\PSScriptAnalyzerSettings.psd1 |
Format-List -Property Severity, RuleName, RuleSuppressionID, Message, Line, ScriptPath
```

`Config\PSScriptAnalyzerSettings.psd1` settings file includes all rules, including code formatting
rules.

If you get an error such as:\
`Invoke-ScriptAnalyzer: Object reference not set to an instance of an object.`\
then try again and keep repeating until OK, or cleanup repository and restart VSCode.

There is also a script `Test\PSScriptAnalyzer.ps1` which you can run to invoke code analysis.

[Table of Contents](#table-of-contents)

## Documentation and comments

Documentation and comments reside in 6 places as follows:

### In scripts (code comments)

Sections of code should be documented as shown in existing scripts.\
To comment on things that need to be done add `TODO:` + comment,
similarly for important notes add `NOTE:` + comment.

For things which are hard to resolve or require huge changes add `HACK:` + comment, and
optionally some links such as github issues that may help to resolve problem in the future.

For any generic code comments you might want to add, use line comments (preferred) and
block comments only if comment spans 5 or more lines.

### In rules (rule description)

It is important that each firewall rule contains good description of it's purpose,
when a user clicks on rule in firewall GUI she\he wants to see what this rule is about and
easily conclude whether to enable/disable rule or allow/block network traffic.

In general regarding firewall rules, provide documentation and official reference for your rules
so that it can be easy to verify that these rules don't contain mistakes, for example, for ICMP
rules you would provide a link to [IANA][iana] with relevant reference document.

### In command line prompts (current execution help)

Every script that's being executed either directly or called by other script will not run
until the user accepts the prompt to run script.\
Similar prompts may appear at various points in code during execution.

Each of these prompts have `?` which a user can type to get more information about prompt choices.

Functions `ShouldProcess` and `ShouldContinue` do not support customizing command line help, for
that reason there is `Approve-Execute` function which allows you to customize prompt help.

### In comment based help (module and script main documentation source)

Functions that are part of a module or solo scripts must have comment based help.\
Purpose of comment based help is for the end user or developer to learn what the code does or to be
able to run `Get-Help` on target function, script or module.

For examples, and comment based syntax see:

- [About Comment-based Help][about comment based help]
- [Examples of Comment-Based Help][comment based help examples]

You must avoid following comment based content to avoid errors and unexpected output while
generating online help (markdown) files:

- `.LINK` entries must contains only one link and nothing else
- Do not use multiple dashes in comments such as `------`
- Use spaces instead of tabs and do not indent comments
- Code samples in `.EXAMPLE` portion must not be separated by blank lines except for sample output
- To number out things with `-` keep one line between commend and listed things
- For anything else keep in mind that any markdown syntax in comments will be formatted in the
resulting markdown file as markdown not as plain text, which may give unexpected results.

See also [PlatyPS.schema][platyps_schema]

### In module Help directory (module online documentation)

The `Scripts` directory contains `Update-HelpContent.ps1` which when run will scan comment based
help and generate online documentation for `Get-Help -Online` and help content for `Update-Help`
on target module.

Generated module documentation is in markdown format, meaning the 3rd purpose is that project
users and repository visitors can read module documentation on github site either manually or
with `Get-Help -Online`

`Update-HelpContent.ps1` script is not perfect and requires additional editing of help files once
documentation was regenerated, diff tool in VSCode is essential for this.

### In docs directory (general project documentation)

The `docs` directory in repository root contains random documentation that covers wide range of
aspects such as troubleshooting, todo list, FAQ, changelog and general project documentation.

Remember, documenting code and features is as important as writing it!

[Table of Contents](#table-of-contents)

## Writing rules

It is important that a rule is very specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.

For example just saying: allow TCP outbound port 80 for any address or any user or
no explanation what is this supposed to allow or block is not acceptable.

[Table of Contents](#table-of-contents)

## Testing code

Each function should have it's own unit test and each test should cover as much code/test
cases as possible, making changes to exiting code can then be easily tested.\
If test case/concept expands to several functions or if it's completely
unrelated to functions it should be a separate test.

All tests reside in `Test` directory which contains subdirectories for each module,
take a look there for examples.

Pester is preferred method to write tests, however some test cases need other ways around, or
more customized setup, for example sometimes you want to see the representation of errors.

There is a module called `Ruleset.Test`, which is customized for this repository, the reason why
pester isn't used as much is that I just didn't have enough time and will to learn it.

Tests must pass both Desktop and Core editions of PowerShell on multiple Windows editions to be
successful.

To test code on different OS editions you should use Hyper-V and set up virtual machines, there is
experimental script called `Initialize-Development.ps1` which will attempt to set up git, gpg, ssh,
update or install missing modules and start requires system services.\
It's recommended to do this manually because this script is unfinished.

A hint to quickly run any function from any module in this repository is to run following command
in ex. integrated terminal in VSCode (assuming PowerShell prompt is at project root):

```powershell
.\Modules\Import-All.ps1
```

This will add all repository `Modules` to current session module path

[Table of Contents](#table-of-contents)

## Debugging

At the moment debugging is one area in this repository which can be hard and is not well maintained.

Regarding code major problem is that scripts and modules require elevation, this means you can't
simply use integrated terminal in VSCode nor any VSCode debugging features unless you're
Administrator or run PS and VSCode as Admin which means your machine becomes an elevated test machine.

Secondary aspect of debugging is testing firewall rules and networking issues which may or may not
be as cool or as easy as debugging code.

### Debugging without a virtual machine

Knowing this here are some recommendations if you whish to test without virtual environment:

1. Forget about debugger and instead just use `Write-Debug` and `Write-Verbose` commandlets to see
what the code is doing, this is much faster and more useful and informative than stepping trough
code.

2. Run PS as Admin and type command by commad which you wish to test by copying code out of editor
into the console, this is much more practical than stepping trough code because you can handle
various scenarios by simply modifying variables and using console history to repeat steps.

3. In `Config\ProjectSettings.ps1` debug and verbose preferences are set in single place and entire
repository is affected, you don't even have to restart PS or reimport modules when `$Develop` is set
because each run of some scripts gives you fresh environment for testing.\
Some variables are however exception to this and will require restart of PS.

4. For deployment testing or testing which affects firewall on your host simply set up multiple
Hyper-V guest systems with external switch (NIC) and optionally map your repo from host to guest
system.

5. Regarding testing rules, the easiest method is get confortable with all the tools and methods
described in [MonitoringFirewall.md](/docs/MonitoringFirewall.md)\
For remoting tests of course Hyper-V on same subnet and mapped drive proves most useful.

### Debugging with Remote-SSH VSCode extension in virtual machine

The most efficient and safe method to debug and test code is to use Remote-SSH extension in
combination with virtual machine, this process consists of the following:

1. Set up VM and enable OpenSSH SSH server in optional features in VM
2. Start OpenSSH SSH service and set it to automatic in VM
3. Install VSCode in virtual machine
4. clone `WindowsFirewallRuleset` in your VM
5. On your host create a new SSH key that will be used for Remote-SSH extension and put it into your
your `$HOME\.ssh`
6. On your host system copy `Config\SSH\config` file into your `$HOME\.ssh` folder and modify file
with correct parameters
7. In PowerShell cd into `WindowsFirewallRuleset` and run:

```powershell
.\Modules\Import-All.ps1
# Update UPPERCASE parameters of the command below:
Publish-SshKey -Domain VM_GUEST_NAME -User VM_ADMIN -System -Key $HOME\.ssh\YOUR_KEY.pub
```

Next step is to add following settings into your VSCode settings which is found in:\
`C:\Users\User\AppData\Roaming\Code\User\settings.json`

```json
 // Extension: remote - SSH
 "remote.SSH.remotePlatform": {
  "REMOTE_COMPUTER_NAME": "windows"
 },
 // Local extensions that actually need to run remotely (will appear dimmed and disabled locally)
 // This are all workspace recommended extensions excluding remote SSH:
 "remote.SSH.defaultExtensions": [
  // cSpell:disable
  // AutoScroll
  "pejmannikram.vscode-auto-scroll",
  // Bookmarks
  "alefragnani.bookmarks",
  // Code Spell Checker
  "streetsidesoftware.code-spell-checker",
  // Filter Line
  "everettjf.filter-line",
  // Fix JSON
  "oliversturm.fix-json",
  // Hightlight Bad Chars
  "wengerk.highlight-bad-chars",
  // json
  "zainchen.json",
  // Log File Highlighter
  "emilast.logfilehighlighter",
  // Markdown All in One
  "yzhang.markdown-all-in-one",
  // markdownlint
  "davidanson.vscode-markdownlint",
  // PowerShell
  "ms-vscode.powershell",
  // Rainbow CSV
  "mechatroner.rainbow-csv",
  // Sort JSON objects
  "richie5um2.vscode-sort-json",
  // Todo Tree
  "gruntfuggly.todo-tree",
  // Trailing Spaces
  "shardulm94.trailing-spaces",
  // XML
  "redhat.vscode-xml",
  // YAML
  "redhat.vscode-yaml"
  // cSpell:enable
 ]
```

Now restart VSCode on your host system and under `Remote Explorer` in VSCode you'll find an option
to open VSCode to remote host, once you connect select `WindowsFirewallRuleset` to be your default
remote directory for connection.

At this point you can run code on remote host in VSCode from your host either in a new VSCode window
or in same window.

## Commits and pull requests

Push commits that solve or improve single or specific problem, to reduce merge conflicts and
to be able to do `git revert` easily if needed.

Do not wait too much to push changes which only contributes to less clear intentions in terms
of what issue is supposed to be resolved or which component was improved.

If you see something unrelated that could be resolved or improved, put `TODO` comment, don't fix it.\
Then once you commit, open `todo-tree` to review what to do next.

**Avoid making huge changes to existing code** without first attaching valid reasons,
new code and additions should not problem though.

[Table of Contents](#table-of-contents)

## Portability and other systems

At the moment focus is on Windows Firewall, if you want to extend code base to other firewalls
or operating systems go ahead, it surely won't be easy!

If you decide to do so it is mandatory that these code additions are done on separate branch, which
should then be regularly maintained up until you are done.\
And only when done it could be merged with develop branch for new changes.

It is desired to expand this project to manage [nftables][nftables] firewall on linux and other
systems, but this likely won't happen any time soon.

[Table of Contents](#table-of-contents)

## Making new scripts or modules

Inside `Templates` directory there are few template scripts as a starting point.\
Copy them to target location, update starting code and you're ready to start working.

These templates are always up to date for current rule design, code and formatting style in this
repository.

[Table of Contents](#table-of-contents)

## Repository directory structure

See [Directory Structure](/docs/DirectoryStructure.md)

## Where to start

Please keep in mind that a portion of existing code is not in line with all the guidelines described
here, significant portion of code was written before this `CONTRIBUTING.md` file even existed.

So it's an ongoing effort that by no means gets fulfilled.

It's recommended to take a look into [TODO](/docs/TODO.md) list and also use `todo-tree`
extension to see more specific or smaller todo's, unless you have specific ideas or recommendations.

[Table of Contents](#table-of-contents)

[contributing develop]: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/CONTRIBUTING.md "latest CONTRIBUTING.md"
[contribute to open source]: https://opensource.guide/how-to-contribute "How to contribute to open source"
[open source etiquette]: https://tirania.org/blog/archive/2010/Dec-31.html "Open Source Contribution Etiquette"
[Forking a repo]: https://docs.github.com/en/get-started/quickstart/fork-a-repo "Forking a repo"
[github ssh]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh "Connecting to GitHub with SSH"
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
[extension gremlins]: https://marketplace.visualstudio.com/items?itemName=wengerk.highlight-bad-chars "Visit Marketplace"
[extension bookmarks]: https://marketplace.visualstudio.com/items?itemName=alefragnani.Bookmarks "Visit Marketplace"
[extension csv]: https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv "Visit Marketplace"
[extension markdown aio]: https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one "Visit Marketplace"
[extension xml]: https://marketplace.visualstudio.com/items?itemName=redhat.vscode-xml "Visit Marketplace"
[extension sort lines]: https://marketplace.visualstudio.com/items?itemName=Tyriar.sort-lines  "Visit Marketplace"
[extension yaml]: https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml "Visit Marketplace"
[extension logs]: https://marketplace.visualstudio.com/items?itemName=emilast.LogFileHighlighter "Visit Marketplace"
[extension quotes]: https://marketplace.visualstudio.com/items?itemName=BriteSnow.vscode-toggle-quotes "Visit Marketplace"
[extension scroll]: https://marketplace.visualstudio.com/items?itemName=pejmannikram.vscode-auto-scroll "Visit Marketplace"
[extension select line status bar]: https://marketplace.visualstudio.com/items?itemName=tomoki1207.selectline-statusbar "Visit Marketplace"
[extension filterline]: https://marketplace.visualstudio.com/items?itemName=everettjf.filter-line "Visit Marketplace"
[extension remote SSH]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh "Visit Marketplace"
[extension ini]: https://marketplace.visualstudio.com/items?itemName=DavidWang.ini-for-vscode "Visit Marketplace"
[extension remote SSH editing]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit "Visit Marketplace"
[extension remote SSH explorer]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer "Visit Marketplace"
[extension sort json]: https://marketplace.visualstudio.com/items?itemName=richie5um2.vscode-sort-json "Visit Marketplace"
[extension json]: https://marketplace.visualstudio.com/items?itemName=ZainChen.json "Visit Marketplace"
[extension trailing spaces]: https://marketplace.visualstudio.com/items?itemName=shardulm94.trailing-spaces "Visit Marketplace"
[develop cmdlets]: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines?view=powershell-7 "Visit documentation"
[powershell style]: https://poshcode.gitbook.io/powershell-practice-and-style/introduction/readme "PowerShell code style"
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
[about comment based help]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7 "Visit documentation"
[comment based help examples]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7 "Visit documentation"
[iana]: https://www.iana.org "Internet Assigned Numbers Authority (IANA)"
[nftables]: https://en.wikipedia.org/wiki/Nftables "Visit nftables wiki"
[should continue]: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.shouldcontinue?view=powershellsdk-7.0.0
[should process]: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.shouldprocess?view=powershellsdk-7.0.0
[exceptions everything]: https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know "Visit blog"
[exceptions handling]: https://github.com/MicrosoftDocs/PowerShell-Docs/issues/1583 "Visit GitHub"
[markdown mastering]: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax "Visit GitHub"
[markdown style]: https://cirosantilli.com/markdown-style-guide "Visit markdown guide"
[markdown tables]: https://www.tablesgenerator.com/markdown_tables "Visit table generator site"
[badge vscode]: https://img.shields.io/static/v1?label=Made%20for&message=VSCode&color=informational&style=plastic&logo=Visual-Studio-Code
[badge vscode link]: https://code.visualstudio.com
[platyps_schema]: https://github.com/PowerShell/platyPS/blob/master/platyPS.schema.md "Visit PlatyPS repository"


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
  - [Static code analysis](#static-code-analysis)
  - [Documentation and comments](#documentation-and-comments)
    - [In scripts](#in-scripts)
    - [In firewall rules](#in-firewall-rules)
    - [In command line prompts](#in-command-line-prompts)
    - [In comment based help](#in-comment-based-help)
    - [In module Help directory](#in-module-help-directory)
    - [In docs directory](#in-docs-directory)
  - [Writing rules](#writing-rules)
  - [Testing code](#testing-code)
  - [Debugging](#debugging)
    - [Debugging code](#debugging-code)
    - [Debugging code without a debugger](#debugging-code-without-a-debugger)
    - [Debugging with Remote-SSH extension](#debugging-with-remote-ssh-extension)
    - [Debugging firewall](#debugging-firewall)
  - [Commits and pull requests](#commits-and-pull-requests)
  - [Portability and other systems](#portability-and-other-systems)
  - [Making new scripts or modules](#making-new-scripts-or-modules)
  - [Repository directory structure](#repository-directory-structure)
  - [Where to start](#where-to-start)
  - [This is too much](#this-is-too-much)

## General guidelines

Here is a list of introductory material to help you get started.

It's recommended to read up to date version of this document which is located on `develop` branch
[here][contributing develop]

The following two pages below explain general starting guidelines regarding open source

- [How to contribute to open source][contribute to open source]
- [Open Source Contribution Etiquette][open source etiquette]

First step is to fork a project

- [Forking a repo][Forking a repo]

Next if needed, you might want to set up your `SSH` keys

- [Connecting to GitHub with SSH][github ssh]

The following optional tutorial may help you setting up git for PowerShell (but it's out of date)

- [PowerShell GPG4Win, SSH, posh-git][tutorial]

Regarding license and Copyright practices adopted by this project see

- [Maintaining file-scope copyright notices][filescope copyright]
- [Requirements under U.S. and E.U. Copyright Law][copyright law]
- [Copyright Notices][copyright notices]

Regarding versioning adopted see

- [Semantic Versioning 2.0.0][semantic versioning]

Few additional references regarding open source worth reading

- [Don't "Push" Your Pull Requests][dont push]
- [Painless Bug Tracking][bug tracking]

For quick markdown referencesee

- [Mastering Markdown][markdown mastering]
- [Markdown Style Guide][markdown style]
- [Markdown tables generator][markdown tables]

References for tools used by this project

- [PowerShell documentation][powershell docs]
- [Visual Studio Code][vscode docs]

[Table of Contents](#table-of-contents)

## Environment setup

[![Made for VSCode][badge vscode]][badge vscode link]

It is highly recommended to stick with Visual Studio Code, because this repository includes settings
specific to Visual Studio Code, aka "Workspace", these settings include:

1. Code formatting settings which are automatically enforced, and can also be manually applied.
2. List of recommended extensions which are automatically listed for installation once you open\
repository folder with VSCode.
3. Debugging and code analysis settings which you can use to debug code.
4. Settings for recommended extensions, ex. markdown and script formatting or code editing.
5. Spelling settings which help to detect misspelled words and correct them as you type.
6. Many other minor workspace settings to improve coding experience.

In addition to `VSCode` and setting up `git` which was already covered in introductory section
you'll need a good console setup, `Windows PowerShell` is part of operating system but in addition
you want `PowerShell Core` and `Windows Terminal` installed.

Reason why you need Windows Terminal is because when you run it as Administrator you can create
additional PS consoles (either Core or Desktop editions) without having to type Administrator
password and not needing to fire up console from start menu or taskbar and then navigating to
location each time.

For introduction about `Windows Terminal` see [Windows Terminal](docs/WindowsTerminal.md)\
For introduction about `Windows PowerShell` see [Windows PowerShell](/docs/WindowsPowerShell.md)

To manage your `GPG` keys it's highly recommended to use `Kleopatra` which is part of `Gpg4win` suite.\
You can get it from [gpg4win.org][gpg4win]

If you don't want your computer to be testing ground and subject to potential problems you'll also
want to set up virtual machine, suggested virtual machine is [Hyper-V][hyperv]

### Recommended workspace extensions

When you open up repository with VSCode the following extensions will be suggested for installation.\
It's highly recommended to install them to have a good and stressless coding experience.

1. [Auto Scroll][extension scroll]

    Automatic scrolling of log files, useful to tail firewall logs.\
    This extension complements `Log File Highlighter` extension below.

2. [Bookmarks][extension bookmarks]

    Helps you to bookmark various places in code to easily navigate choke points of interest.

3. [Code Spell Checker][extension spellcheck]

    Helps to spell words correctly, you get a list of misspelled words in VSCode and fix them,
    you also get suggestions to fix words as you type.

4. [Filter Line][extension filterline]

    Filter log files according to json config, string or regex pattern.

5. [Highlight Bad Chars][extension gremlins]

    Helps to detect gremlins (bad chars), which cause issues such as unable to save file
    in `UTF-8` format

6. [Ini for VSCode][extension ini]

    Provides support for `INI` files, ex. document outline in VSCode.

7. [Log File Highlighter][extension logs]

    Custom syntax highlighting for log files, useful for firewall logs as an alternative of `mTail`.\
    This extension complements `Auto Scroll` extension above.

8. [Markdown All in One][extension markdown aio]

    Provides markdown language support such as document formatting and generating table of contents.

9. [Markdownlint][extension markdownlint]

    Helps to write better markdown, you get a list of problems in VSCode and fix them.

10. [PowerShell][extension powershell]

    PowerShell syntax highlighting, intellisense, formatting and other language support.

11. [Rainbow CSV][extension csv]

    Firewall rules can be exported into `CSV` file, this extension provides syntax highlighting for
    `CSV` files.

12. [Remote SSH][extension remote SSH]

    Lets you use any remote machine with a SSH server as your development environment.

13. [Remote SSH editing][extension remote SSH editing]

    This extension complements the `Remote - SSH` extension with syntax colorization,
    keyword intellisense, and simple snippets when editing SSH configuration files.

14. [Remote Explorer][extension remote SSH explorer]

    View a list of remote machines for `Remote - SSH` in action bar.

15. [Select Line Status Bar][extension select line status bar]

    Shows the count of selected lines in status bar.

16. [Sort JSON objects][extension sort json]

    Sorts the keys in selected JSON objects or entire file according to desired criteria.

17. [Sort Lines][extension sort lines]

    Let's you sort lines in file according to desired criteria.

18. [TODO tree][extension todo-tree]

    Required to easily navigate `TODO`, `HACK`, `NOTE` and similar tagged comments located in source
    files.

19. [Toggle Quotes][extension quotes]

    Toggle single quotes to double quotes or vice versa.

20. [Trailing Spaces][extension trailing spaces]

    Highlight trailing spaces and delete them in an instant.

21. [XML][extension xml]

    Provides xml language support, can also help to detect issues with xml files.

22. [YAML][extension yaml]

    Provides yaml language support, can also help to detect issues with yaml files.

### Repository settings

Once your environment is set, next step is to visit `Config\ProjectSettings.ps1`
located in repository root directory, at a minimum you should set the following variables to `$true`
before doing anything else:

1. `Develop`
2. `ProjectCheck`
3. `ModulesCheck`
4. `ServicesCheck`
5. `ErrorLogging`
6. `WarningLogging`

In addition verify the following variables are set to desired user

1. `DefaultUser`
2. `TestAdmin`
3. `TestUser`

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
are found in `.vscode` and `Config` directories.

[Table of Contents](#table-of-contents)

### Development Guidelines

The following link explains the must know style guidelines to write functions and commandlets

- [Cmdlet Development Guidelines][develop cmdlets]

The following link describes general rules about PowerShell code style if you like reading,
however keep in mind, it's not completely in line with this repository best practices

- [The PowerShell Style Guide][powershell style]

The following links may help with exception and error handling:

- [Everything you wanted to know about exceptions][exceptions everything]
- [Our Error Handling - GitHub][exceptions handling]

Use risk mitigation features if applicable for functions that you write, see `Remarks` sections on
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

Use the following command to see allowed verbs to name your functions

```powershell
# PowerShell Core
Get-Verb | Select-Object Verb, Group, Description | Sort-Object Verb

# Windows PowerShell
Get-Verb | Select-Object Verb, Group | Sort-Object Verb
```

For function nouns prefer one word or maximum three (distinguished by uppercase letters) for example:

- `Invoke-Process`
- `Get-SqlServer`

Sometimes this is not possible, for example `Get-SqlServer` function may collide with existing
PowerShell commandlets, in this case it's better to use three words rather than naming your function
to something that doesn't describe it's purpose, ex. `Get-SqlServerInstance` would be fine too,
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
2. `PSScriptInfo` comment (if it's script file)
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
easy to see where stuff is and it's easy to use advanced search/replace or multicursor tricks.

Performing regex operations on firewall rules in combination with multicursor feature can be
done in a matter of minutes, without this strict rule design it would take an entire day and might
result in bugs or random issues.

[Table of Contents](#table-of-contents)

### Module design

Repository contains several custom modules of various purpose, module functionality is grouped by
relevance on what the module is supposed to expose.

Try to limit dependency on 3rd party modules and module code.\
If needed existing modules can be extended or new written without introducing dependencies or new
languages.

Only if this is not enough we can try to look for 3rd party modules which could be
easily customized without too much change or learning curve.

3rd party module scripts or functions should be included into existing modules as scripts instead
of copy pasted into existing code directly, this must be so, to easily see to which file does
license and Copyright apply.

Exception to this rule are complete modules (larger portion of code) which should retain their
directory domain and content within repository.

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

## Static code analysis

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

There is also a script `Test\Invoke-CodeAnalysis.ps1` which you can run to invoke code analysis with
additional options such as logging results to file.

[Table of Contents](#table-of-contents)

## Documentation and comments

Documentation and comments reside in six places as follows:

### In scripts

Sections of code should be documented as shown in existing scripts.\
To comment on things that need to be done add `TODO:` tag + comment,
similarly for important notes add `NOTE:` tag + comment.

For things which are hard to resolve or require huge changes add `HACK:` tag + comment,
if you're pasting Microsoft's documentation add `MSDN:` tag and optionally a link to source.\
similarly if you're pasting documentation from non Microsoft site add `DOCS:` tag + copied comment.

Links to github issues should be prefixed with `ISSUE:` tag which help to resolve problems in the future.

These tags are colored in editor and can be navigaged with `todo-tree` extension in action bar,
for a complete list of tags and their purpose and coloring scheme see `.vscode\settings.json` file.

For any generic code comments you might want to add, use line comments (preferred) and
block comments only if comment spans five or more lines.

### In firewall rules

It is important that each firewall rule contains good description of it's purpose,
when a user clicks on rule in firewall GUI she\he wants to see what this rule is about and
easily conclude whether to enable/disable rule or allow/block network traffic.

In general regarding firewall rules, provide documentation and official reference for your rules
so that it can be easy to verify that these rules don't contain mistakes, for example, for ICMP
rules you would provide a link to [IANA][iana] with relevant reference document.

### In command line prompts

Every script that's being executed either directly or called by other script will not run
until the user accepts the prompt to run the script.\
Similar prompts may appear at various points in code during execution.

Each of these prompts have `?` mark option which a user can type to get more information about
prompt choices.

Functions `ShouldProcess` and `ShouldContinue` do not support customizing command line help, for
that reason there is `Approve-Execute` function which allows you to customize prompt help.

### In comment based help

Functions that are part of a module or solo scripts must have comment based help.\
Purpose of comment based help is for the end user or developer to learn what the code does or to be
able to run `Get-Help` on target function, script or module.

For examples, and comment based syntax see:

- [About Comment-based Help][about comment based help]
- [Examples of Comment-Based Help][comment based help examples]

You must avoid the following comment based content to avoid errors and unexpected output while
generating online help (markdown) files:

- `.LINK` entries must contains only one link and nothing else.
- Do not use multiple dashes in comments such as `------`.
- Use spaces instead of tabs and do not indent comments.
- Code samples in `.EXAMPLE` portion must not be separated by blank lines except for sample output
- To number out things use `-` and keep one line between commend and listed things.
- For anything else keep in mind that your comment based help will be formatted in the
resulting markdown file as markdown not as you type it, which may give unexpected results.

For more information see also [PlatyPS.schema][platyps_schema]

### In module Help directory

The `Scripts\Utility` directory contains `Update-HelpContent.ps1` which when run will scan comment
based help and generate online markdown documentation for `Get-Help -Online` and help content for
`Update-Help` on target module.

Purpose of the generated markdown module documentation is that project users and repository visitors
can read module documentation on github site either manually or with `Get-Help -Online`

`Update-HelpContent.ps1` script is not perfect and requires additional editing of help files once
documentation is regenerated, diff tool in VSCode is essential to finalize generated files manually.

### In docs directory

The `docs` directory in repository root contains random documentation that covers wide range of
aspects such as troubleshooting, todo list, FAQ, changelog and general project documentation.\
`docs` directory is also the root directory for [web site][repo website] of this repository

Remember, documenting code and features is as important as writing code!

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
take a look there for examples.\
Few pester tests are located in some module directories.

Pester is preferred method to write tests, however those non pester tests are not just custom tests,
but they are also used by debugger configuration to debug code for which pester isn't a solution.\
Also some test cases need other ways around, or more customized setup, for example sometimes you
want to see the representation of errors or the actual output for which pester also isn't a solution.

There is a module called `Ruleset.Test`, which is customized for this repository, the reason why
pester isn't used as much is that I just didn't have enough time and will to learn it.

Tests must pass both Desktop and Core editions of PowerShell on multiple Windows editions to be
successful.

To test code on different OS editions you should use Hyper-V and set up virtual machines, there is
experimental script called `Initialize-Development.ps1` which will attempt to set up git, gpg, ssh,
update or install missing modules and start required system services.\
It's recommended to do this manually because this script is unfinished.

A hint to quickly run any function from any module in this repository is to run the following
command in ex. integrated terminal in VSCode (assuming PowerShell prompt is at project root):

```powershell
.\Modules\Import-All.ps1
```

This will import all repository modules at once.

[Table of Contents](#table-of-contents)

## Debugging

Debugging `Windows Firewall Ruleset` consists of two parts, debugging code and auditing firewall
rules.

### Debugging code

Precondition to debug code is to run `VSCode` as Administrator because majority of scripts and
module functions perform administrative tasks which requires elevation.

There is workspace debugging configuration for each module function and script in repository which
you can access from `Run and Debug` badge in action bar, at the top is a drop down list listing
module functions and scripts sorted alphabetically.

These configurations actually run unit tests from `Test` directory, you can set break points in
referenced module function or script if desired and click `Start Debugging` button.

The debugging configuration itself is located in `.vscode\launch.json` file.

For more information on how to debug see the following links:

- [Debugging in VSCode][vscode debugging]
- [Integrate with External Tools via Tasks][tasks]
- [Variables Reference][variables reference]

### Debugging code without a debugger

There are few good reasons why would you wish to debug to wild, such as:

1. A function or script you wish to debug is not configured or appropriate for debugger or there
is no unit test which would call module function or script.

2. A function or script is relatively simple or there is no space for mistakes to appear.

3. You want testing procedure to go faster and immediately affecting target system.

4. You prefer running code in the console as Administrator and\or do everything else as
standard user.

Here are recommendations if you whish to debug code without using debugger:

1. Use `Write-Debug` and `Write-Verbose` commandlets in your code to see what the code is doing,
this is much faster and sometimes more useful and informative than stepping trough code.

2. Run PS as Admin and copy commands which you wish to test out of code editor into the console,
this is much more practical than stepping trough code because you can handle
various scenarios by simply modifying variables and using console history to repeat steps.

3. In `Config\ProjectSettings.ps1` debug and verbose preferences can be set in single place and
entire repository is affected, you don't even have to restart PS or reimport modules when `$Develop`
variable is set because each run of some scripts gives you fresh environment for testing.\
Some variables are however exception to this and will require restart of PS.

4. For deployment testing or testing which affects firewall or system configuration on your host
simply set up multiple Hyper-V guest systems attached to external switch (NIC) and optionally map
your repo from host to guest system.\
For remoting tests Hyper-V guest on same subnet and mapped drive proves most useful since you
neither need additional hardware nor do you affect your host system.

### Debugging with Remote-SSH extension

The most efficient and safe method to debug and test code is to use `Remote-SSH` extension in
combination with virtual machine, this process consists of the following:

1. Set up Hyper-V, install a new guest system and enable `OpenSSH` SSH server in optional features
in the guest system.
2. clone `WindowsFirewallRuleset` into your VM, for this you'll need git and other development
environment setup configured in VM.
3. Edit `Config\SSH\sshd_config` file and update parameters with correct values as needed.
4. Copy your edited `Config\SSH\sshd_config` in the guest system into `%ProgramData%\ssh`
5. Restart `OpenSSH` SSH service to pick up copied configuration and set it to automatic startup
6. Make sure you install VSCode in virtual machine which will provide server services for
`Remote SSH`
7. On your host system create a new SSH key that will be used for `Remote-SSH` extension and put it
into your your `$HOME\.ssh` directory
8. On your host system edit `Config\SSH\config` file and update parameters with correct values as
needed.
9. On your host system copy editted `Config\SSH\config` file into your `$HOME\.ssh` folder
10. On your host system restart `OpenSSH client` service to pick up your config file.
11. Fire up PowerShell console and cd into `WindowsFirewallRuleset` then run:

```powershell
.\Modules\Import-All.ps1
# Update UPPERCASE parameters of the command below:
Publish-SshKey -Domain VM_GUEST_NAME -User VM_ADMIN -System -Key $HOME\.ssh\YOUR_KEY.pub
```

Next step is to add the following settings into your VSCode user settings which is found in:\
`%UserProfile%\AppData\Roaming\Code\User\settings.json`

```jsonc
  // Extension: remote - SSH
  "remote.SSH.remotePlatform": {
  "REMOTE_COMPUTER_NAME": "windows"
  },
  // Local extensions that actually need to run remotely (will appear dimmed and disabled locally)
  // This are all workspace recommended extensions excluding remote SSH which should be omitted:
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
  // Hightlight Bad Chars
  "wengerk.highlight-bad-chars",
  // Ini for VSCode
  "DavidWang.ini-for-vscode",
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
  // Select Line Status Bar
  "tomoki1207.selectline-statusbar",
  // Sort JSON objects
  "richie5um2.vscode-sort-json",
  // Sort Lines
  "Tyriar.sort-lines",
  // Todo Tree
  "gruntfuggly.todo-tree",
  // Toggle Quotes
  "BriteSnow.vscode-toggle-quotes",
  // Trailing Spaces
  "shardulm94.trailing-spaces",
  // XML
  "redhat.vscode-xml",
  // YAML
  "redhat.vscode-yaml"
  // cSpell:enable
]
```

Now restart VSCode on your host system and in `Remote Explorer` in VSCode you'll find an option
to open VSCode to remote host, once you connect select `WindowsFirewallRuleset` to be your default
remote directory for connection.

At this point you can run code on remote host in VSCode from your host either in a new VSCode
window or in same window.

However to run scripts or functions which require elevation you'll need to run VSCode as
Administrator and configure before mentioned steps for your Admin account on host system.

### Debugging firewall

Secondary aspect of debugging is auditing firewall rules and networking issues which may or may not
be as cool or as easy as debugging code.

First step is to get confortable with all the tools and methods described in
[MonitoringFirewall.md](docs/MonitoringFirewall.md) which will help to monitor firewall.

How do you proceed from that point on depends on firewall rules you're auditing or the kind of
networking problems that you're trying to resolve.

## Commits and pull requests

Push commits that solve or improve single or specific problem, to reduce merge conflicts and
to be able to do `git revert` easily if needed.

Do not wait too much to push changes which only contributes to less clear intentions in terms
of what issue is supposed to be resolved or which component was improved.

If you see something unrelated that could be resolved or improved, put `TODO` comment, don't fix it.\
Then once you commit, open `todo-tree` to review what to do next.

**Avoid making huge changes to existing code** without consultation, new code and additions should
not problem though.

[Table of Contents](#table-of-contents)

## Portability and other systems

At the moment focus is on Windows Firewall, if you want to extend code base to other firewalls
or operating systems go ahead, it surely won't be easy!

If you decide to do so it is mandatory that these code additions are done on separate branch, which
should then be regularly maintained up until you are done.\
And only when done it could be merged with develop branch for new changes.

It is desired to expand this project to manage [nftables][nftables] firewall on linux and other
systems, but this likely won't happen any time soon unless more people get involved into this
project.

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

## This is too much

You might find all these guidelines described here too much to chew and that I could understand.

Please run `git log --reverse` search for commit hash and see for yourself how horrible my knowledge
of PowerShell was and perhaps still is, when I started all I knew is how to open the console but
not a single command was known to me, I'm not system admin and this is my first PowerShell project,
all these guidelines described here is what I learned on my own mistakes over time and by reading
various guidelines and documentation online, carefully updating this file with new knowledge and
still learning new stuff.

You might hate pascal case for ex. and a lot of coders don't like it either and there is
surely a bunch of things to disagree with but that's the style used in this repository.

Knowing this I don't expect you follow all of this immediately but I expect you to be pedantic,
explicit and to seek writing quality code.

If you're PowerShell begginner like I was you're most welcome as long as you're interested in
IT security and willing to read the docs online for anything you don't know.\
Otherwise if you're expert that would be great because there is a lot to do and I could surely learn
something from you because I don't consider myself to be expert.

Of course suggestions regarding coding style and practices are welcome, I might consider changing
my mind.

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
[powershell docs]: https://docs.microsoft.com/en-us/powershell/scripting/how-to-use-docs "PowerShell documentation"
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
[extension trailing spaces]: https://marketplace.visualstudio.com/items?itemName=shardulm94.trailing-spaces "Visit Marketplace"
[develop cmdlets]: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines "Visit documentation"
[powershell style]: https://poshcode.gitbook.io/powershell-practice-and-style/introduction/readme "PowerShell code style"
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
[about comment based help]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help "Visit documentation"
[comment based help examples]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help "Visit documentation"
[iana]: https://www.iana.org "Internet Assigned Numbers Authority (IANA)"
[nftables]: https://en.wikipedia.org/wiki/Nftables "Visit nftables wiki"
[should continue]: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.shouldcontinue
[should process]: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.shouldprocess
[exceptions everything]: https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know "Visit blog"
[exceptions handling]: https://github.com/MicrosoftDocs/PowerShell-Docs/issues/1583 "Visit GitHub"
[markdown mastering]: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax "Visit GitHub"
[markdown style]: https://cirosantilli.com/markdown-style-guide "Visit markdown guide"
[markdown tables]: https://www.tablesgenerator.com/markdown_tables "Visit table generator site"
[badge vscode]: https://img.shields.io/static/v1?label=Made%20for&message=VSCode&color=informational&style=plastic&logo=Visual-Studio-Code
[badge vscode link]: https://code.visualstudio.com
[platyps_schema]: https://github.com/PowerShell/platyPS/blob/master/platyPS.schema.md "Visit PlatyPS repository"
[vscode debugging]: https://code.visualstudio.com/docs/editor/debugging "Visit VSCode documentation"
[tasks]: https://code.visualstudio.com/docs/editor/tasks "Visit VSCode documentation"
[variables reference]: https://code.visualstudio.com/docs/editor/variables-reference "Visit VSCode documentation"
[gpg4win]: https://www.gpg4win.org "Visit gpg4win site"
[hyperv]: https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/about "Visit Microsoft site"
[repo website]: https://metablaster.github.io/WindowsFirewallRuleset "Visit repository web site"


# Support

This document provides information on how to get support with `Windows Firewall Ruleset` and
anything related such as networking, security, privacy, troubleshooting and reporting issues.

## Table of Contents

- [Support](#support)
  - [Table of Contents](#table-of-contents)
  - [Documentation](#documentation)
  - [Reporting a problem or bug](#reporting-a-problem-or-bug)
  - [Reporting security or privacy issue](#reporting-security-or-privacy-issue)
  - [Suggesting a feature or information](#suggesting-a-feature-or-information)
  - [Starting a new discussion](#starting-a-new-discussion)
  - [Customization](#customization)
  - [Legacy support](#legacy-support)
  - [Checking for updates](#checking-for-updates)
    - [Using GitHub Desktop app](#using-github-desktop-app)
    - [Manual release download](#manual-release-download)
    - [Manual beta download](#manual-beta-download)
    - [Using git command](#using-git-command)
    - [Which update method is the best](#which-update-method-is-the-best)

## Documentation

Inside [docs](docs) directory you will find useful information not only about this project but
also general information on how to troubleshoot firewall and network problems, or to gather other
relevant information.

It might answer some of your questions, for example [Monitoring Firewall](/docs/MonitoringFirewall.md)
provides instructions on how to monitor firewall in real time.

[Table of Contents](#table-of-contents)

## Reporting a problem or bug

To report bugs or functionality issues please open new [issue][issues] and provide relevant
details as outlined in `Get started` under `Bug report`.

[Table of Contents](#table-of-contents)

## Reporting security or privacy issue

If there is security or privacy issue please refer to [SECURITY.md](SECURITY.md)

[Table of Contents](#table-of-contents)

## Suggesting a feature or information

You are most welcome to suggest new rules or improvements for existing rules, scripts or documentation.

To make a suggestion please try to abide to notices below:

To suggest new rules or changes to existing rules if possible provide some documentation or links
(preferably official) for your rule suggestion so that it can be easy to verify these rules or
changes don't contain mistakes.\
ex. for ICMP rules you would provide a link to [IANA][iana] with relevant reference document.

To contribute your own already made rules, it is desired that each rule contains good description
of it's purpose, when a user clicks on rule in firewall GUI she\he wants to see what this rule is
about to easily conclude whether to enable/disable rule or allow/block network traffic.\
If possible, the rule should be specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.

To suggest other code changes or anything related to this project it's as well desired to provide
some links, screenshots or anything which could better present your suggestion.

If you lack some of the details, no problem but please try to collect as much information as
possible.

To actually make a suggestion please open new [issue][issues] and provide relevant details as
outlined in `Get started` under `Feature request`.

[Table of Contents](#table-of-contents)

## Starting a new discussion

If you have random questions that don't fit anywhere else or you just want to say something then\
you're most welcome to open new discussion in [Discussions][discussions]

[Table of Contents](#table-of-contents)

## Customization

If you would like to customize how scripts run, such as force loading rules and various defaults
then visit `Config\ProjectSettings.ps1` and there you'll find global variables which are used for
this.

If you would like to customize code or add more firewall rules to suit your interests then first
step is to set up development environment and learn about best practices used by this repository
all of which is explained in [CONTRIBUTING.md](CONTRIBUTING.md)

[Table of Contents](#table-of-contents)

## Legacy support

For information on how to make use of this firewall on older Windows systems such as Windows 7 or
Windows Server 2008 see [Legacy Support](/docs/LegacySupport.md)

[Table of Contents](#table-of-contents)

## Checking for updates

Just like any other software on your computer, this firewall will go out of date as well,
become obsolete, and may no longer function properly.

This repository consists of two branches, `master` (stable) and `develop` (possibly unstable).\
The "develop" branch is where all updates directly go but updates are not actively tested,
so it's work in progress, unlike "master" branch which is updated from develop once in a while and
not before all scripts are thoroughly tested on fresh installed systems, which is what makes master
brach stable.

If you want to experiment with development version to check out new stuff, switch to "develop"
branch and try it out, however if it produces errors, you can either attempt to fix problems or
switch back to "master".

There are at least four methods to be up to date with this firewall, each with it's own benefits:

[Table of Contents](#table-of-contents)

### Using GitHub Desktop app

[![GitHub Desktop][badge github desktop]][github desktop]

This method is similar to git command, but instead you'll use a graphical interface which
you can get from here: [GitHub Desktop][github desktop]

The benefit of using GitHub Desktop is that you easily see code changes on you desktop for each
individual update.

To use it you will need [github account][github join] and a [fork][github fork] of this repository
in your GitHub account.

To configure GitHub Desktop see [GitHub Desktop Documentation][github desktop docs] or search for
some tutorial online.

### Manual release download

[![Releases][badge github]][releases]

This method requires you to simply download released zip file which can be found in
[Releases][releases], this is always from "master" branch

### Manual beta download

This method is good if you want to download from "develop" branch, to do so, use the `branch` button
here on this site and switch to develop branch, next use `Code` button and choose option to either
clone or download zip file .

[Table of Contents](#table-of-contents)

### Using git command

[![Download Git][badge git]][download git]

This method is similar to GitHub Desktop above but good if you need specific git features.\
In addition to two mentioned requirements for GitHub Desktop you will also need [git][download git]
and optionally (but recommended) [SSH keys][github ssh]

Follow steps below to check for updates once you installed git and [cloned][clone] your own fork:

- Right click on Start button in Windows
- Click `Windows PowerShell` to open PowerShell
- First navigate to directory where your instance of Windows Firewall Ruleset instance is, for example:
- Type: `dir` to list directories, ```cd SomeDirectoryName``` to move to some directory or
```cd ..``` to go one directory back
- Type: ```cd WindowsFirewallRuleset``` to move into WindowsFirewallRuleset directory

The following two sets of commands are typed only once for initial setup:

1. If you cloned your fork with `SSH` then run following command:

    ```git remote add upstream git@github.com:metablaster/WindowsFirewallRuleset.git```

2. Otherwise if you cloned your fork with `HTTPS` run:

    ```git remote add upstream https://github.com/metablaster/WindowsFirewallRuleset.git```

Next two sets of commands are typed each time you want to check for updates:

1. To get updates from master branch run:

    - Type: ```git checkout master```
    - Type: ```git fetch upstream```
    - Type: ```git merge upstream/master```

2. Otherwise to get updates from develop branch run:

    - Type: ```git checkout develop```
    - Type: ```git fetch upstream```
    - Type: ```git merge upstream/develop```

For this to work, you need to make sure your working tree is "clean", which means
you need to save and upload your modifications to your fork, for example:

 ```cpp
 cd Path\To\WindowsFirewallRuleset
 git add .
 git commit -m "my changes"
 git push
 ```

 You can switch from one branch to another with git in PowerShell as many times as you  want and
 all files will be auto updated without the need to re-download or re-setup anything.

 For more information on how to use git see [git documentation][git docs]\
 There are also many great tutorials online to learn how to use git.

[Table of Contents](#table-of-contents)

### Which update method is the best

If your goal is to just get updates then `GitHub Desktop` is the best, otherwise if your goal is
firewall customization, using `git` command would be more productive because it offers specific
functionalities that you might need.

You can have both setups in same time and use them as needed in specific situation.\
There is no benefit with manual zip download in comparison with git or GitHub Desktop.

[Table of Contents](#table-of-contents)

[issues]: https://github.com/metablaster/WindowsFirewallRuleset/issues "GitHub issues"
[clone]: https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository "Cloning a repository"
[discussions]: https://github.com/metablaster/WindowsFirewallRuleset/discussions "GitHub discussions"
[iana]: https://www.iana.org "Internet Assigned Numbers Authority (IANA)"
[github join]: https://github.com/join "Join GitHub"
[github fork]: https://docs.github.com/en/get-started/quickstart/fork-a-repo "Create a fork on GitHub"
[github ssh]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh "Connecting to GitHub with SSH"
[git docs]: https://git-scm.com/doc "Git Documentation"
[github desktop]: https://desktop.github.com "Visit GitHub Desktop download page"
[github desktop docs]: https://docs.github.com/en/desktop "Visit GitHub Desktop docs"
[badge github]: https://img.shields.io/static/v1?label=Releases%20on&message=GitHub&color=white&style=plastic&logo=GitHub
[badge github desktop]: https://img.shields.io/static/v1?label=Download&message=GitHub%20Desktop&color=purple&style=plastic&logo=GitHub
[badge git]: https://img.shields.io/static/v1?label=Download&message=Git&color=red&style=plastic&logo=Git
[releases]: https://github.com/metablaster/WindowsFirewallRuleset/releases "Visit releases page now"
[download git]: https://git-scm.com/downloads "Visit Git downloads page"


# WindowsPowerShell

Note that Windows PowerShell is not the same thing as PowerShell Core, for more information see:

[About PowerShell Editions][about pseditions]

## How to open Windows PowerShell in Windows 10

1. Right click on the Task bar and select `Taskbar settings`
2. Enable `Replace Command Prompt with Windows Powershell in the menu when I right click the start button`
3. Right click on start button in Windows
4. Click `Windows Powershell (Admin)` to open Powershell as Administrator
5. If prompted for password, enter Administrator password and click `Yes` to continue

## How to open Windows PowerShell in Windows 11

1. Click on start button
2. Type `Windows PowerShell` into search box
3. Right click on `Windows PowerShell` and either run it normally or as Administrator

## How to open Windows PowerShell in target folder

Most likely you want to open Windows PowerShell directly in some folder so that the prompt points to
exactly that directory.

### Windows 10

Example screenshot for Windows 10

![Alternate text](Screenshots/WindowsPowerShell.png)

Here is how:

1. Go to desired directory by using Windows explorer (selecting some directory does the same)
2. Click on `File` in top left explorer window
3. To open PowerShell as standard user click on `Open Windows PowerShell`
4. To open it as Administrator, in step 3 hover your mouse over `Open Windows PowerShell` and then\
   select `Open Windows PowerShell as Administrator`

### Windows 11

Unfortunately there is no default way like in Windows 10, one solution is to follow steps explained
in section\ `Right click "Open Windows Terminal as Administrator" context menu for Windows 11` below

## Right click "Open Windows PowerShell here" context menu in Windows 10

1. To add context menu on right click for "Windows PowerShell" for standard user see:

    [Open PowerShell window here][powershell here]

2. To add context menu on right click for "Windows PowerShell as Administrator" see:

    [Open PowerShell window here as Administrator][powershell here as admin]

[about pseditions]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_editions?view=powershell-7
[powershell here]: https://www.tenforums.com/tutorials/60175-open-powershell-window-here-context-menu-add-windows-10-a.html
[powershell here as admin]: https://www.tenforums.com/tutorials/60177-add-open-powershell-window-here-administrator-windows-10-a.html

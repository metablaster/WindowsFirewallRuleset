
# Scripts\Security directory

This subdirectory contains scripts used to manage Windows security.

These scripts are unrelated to firewall, they are here for you if you wish to go beyond `Windows
Firewall Ruleset` and adjust target system for maximum security possible with PowerShell.

In particular these scripts are used to manage the following:

- Microsoft Defender Antivirus
- Digital signature verification across system and [VirusTotal][virustotal] scan of unsigned files
- Windows privacy options

## List of settings which are not handled either by design or due to lack of importance

Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options

- Interactive logon: Display user information when the session is locked (Do no display user information)
- Interactive logon: Do not require CTRL+ALT+DEL (Disabled)
- Interactive logon: don't display last signed-in (Enabled)
  - BUG: For "don't display last signed-in" to work properly, sign out of all users before shutting down computer

- Interactive logon: don't display username at sign in (Enabled)
- User Account Control: Behavior of the elevation prompt for standard users (Prompt for credentials on the secure desktop)
- User Account Control: Only elevate executable files that are signed and validated (Enabled)

### Computer Configuration\Windows Settings\Security Settings\Account Policies\Password Policy

- Password must meet complexity requirements (Enabled)
- Maximum password age (42)
- Minimum password length (10)

PAUSED:

### Computer Configuration\Administrative Templates\Windows Components\Search

- Allow Cortana (Disabled)
  - NOTE: Cortana will be removed in the future

UNUSED:

### Computer Configuration\Administrative Templates\System\Removable Storage Access

- All removable storage classes: Deny all access (Enabled)
  - NOTE: Mounting ISO or USB problems

### Computer Configuration\Administrative Templates\Windows Components\Bit Locker Drive Encryption\Operating System Drives

- Require additional authentication at startup (Enabled)
  - "Allow BitLocker without a compatible TPM (requires a password or a startup key on a USB flash drive)"
  - NOTE: Only if you don't have TPM

### Computer Configuration\Administrative Templates\Control Panel\Personalization

- Prevent changing lock screen and logon image

### Computer Configuration\Administrative Templates\Windows Components\OneDrive

- Prevent the usage of OneDrive for file storage

### Computer Configuration\Administrative Templates\Windows Components\Microsoft Defender Antivirus

- Turn off Microsoft Defender Antivirus

### Computer Configuration\Administrative Templates\System\Device Guard

- Turn On Virtualization Based Security
  - NOTE: The "Not Configured" setting is the default, and allows configuration of the feature by Administrative users.

### Computer Configuration\Windows Settings\Scripts (Startup/Shutdown)

- User Configuration\Windows Settings\Scripts (Logon/Logoff)

### Computer Configuration\Windows Settings\Security Settings\Application Control Policies

App locker
ex. Block USB execute

UNUSED: Configured in settings

### Computer Configuration\Administrative Templates\Windows Components\Internet Explorer

- Prevent Changing proxy settings (Enabled)

UNUSED: Enterprise

### Computer Configuration\Administrative Templates\Windows Components\Microsoft Defender Application Guard

- Allow camera and microphone access in Microsoft Defender Application Guard (Disabled)
- Allow files to download and save to host operating system (Disabled) enabled if needed

### Computer Configuration\Administrative Templates\Windows Components\Cloud Content

- Turn off Microsoft consumer experiences

ALREADY DEFAULT:

### Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options

- Accounts: Guest Account Status
- Accounts: Administrator Account Status
- Network security: Do not store LAN Manager hash value on next password change
- Network Access: Allow anonymous SID/Name translation

[virustotal]: https://www.virustotal.com/gui/home/upload "Visit VirusTotal site"

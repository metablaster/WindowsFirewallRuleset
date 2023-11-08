
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# Firewall rules exist for programs listed here
# Services and store apps are not part of this enumeration
enum TargetProgram
{
	GooglePlay
	calibre
	ytdlp
	Motrix
	LGHUB
	nmap
	Brave
	Psiphon
	MSI
	EdgeWebView
	SteamCMD
	Audacity
	dotnet
	CMake
	SqlPath
	SqlServer
	SqlManagementStudio
	WindowsDefender
	NuGet
	NETFramework
	vcpkg
	SysInternals
	WindowsKits
	WebPlatform
	OpenSpace
	XTU
	Chocolatey
	ArenaChess
	GoogleDrive
	RivaTuner
	Incredibuild
	ColorMania
	MetaTrader
	RealWorld
	AzureDataStudio
	qBittorrent
	OpenTTD
	EveOnline
	DemiseOfNations
	CounterStrikeGO
	PinballArcade
	JavaUpdate
	JavaRuntime
	AdobeARM
	AdobeReader
	AdobeAcrobat
	LoLGame
	FileZilla
	PathOfExile
	HWMonitor
	CPUZ
	MSIAfterburner
	GPG
	OBSStudio
	PasswordSafe
	Greenshot
	DnsCrypt
	OpenSSH
	PowerShellCore64
	PowerShell64
	PowerShell86
	OneDrive
	HelpViewer
	VSCode
	MicrosoftOffice
	TeamViewer
	EdgeChromium
	Chrome
	Firefox
	Yandex
	Tor
	uTorrent
	Thuderbird
	Steam
	Nvidia64
	Nvidia86
	GeForceExperience
	WarThunder
	PokerStars
	VisualStudio
	VisualStudioInstaller
	MSYS2
	Git
	GitHubDesktop
	EpicGames
	UnrealEngine
	BingWallpaper
}


# https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme
# NOTE: PSGallery ruleset is a duplicate of these
# TODO: Check for new or updated settings
# NOTE: Last checked on 3.12.2022. v1.21.0
# NOTE: Good portion of warnings is surpressed within repository because of false positives

# A Script Analyzer profile file is a text file that contains a hashtable with one or more of the following keys:
# CustomRulePath, ExcludeRules, IncludeDefaultRules, IncludeRules, RecurseCustomRulePath, Rules, Severity

@{
	Severity = @(
		# NOTE: Not configured because of Test\PSScriptAnalyzer.ps1
		# If not specified all severities are severities are handled
		# "Error"
		# "Warning"
		# "Information"
	)

	ExcludeRules = @(
		# Temporary disabled
		"PSAvoidLongLines"
		# Requires generating custom updated settings
		"PSUseCompatibleCmdlets"
		"PSUseCompatibleCommands"
		# Unwanted
		"PSAlignAssignmentStatement"
		"PSAvoidUsingDoubleQuotesForConstantString"
	)

	IncludeRules = @(
		#
		# CmdletDesign
		#
		"PSUseApprovedVerbs"
		"PSReservedCmdletChar"
		"PSReservedParams"
		"PSShouldProcess"
		"PSUseSingularNouns"
		"PSMissingModuleManifestField"
		"PSAvoidDefaultValueSwitchParameter"
		# NOTE: New settings v1.19.1
		"PSAvoidMultipleTypeAttributes"
		#
		# "PSDSC*",
		# Desired State Configuration is a management platform in PowerShell that enables you to
		# manage your IT and development infrastructure with configuration as code
		#
		"PSDSCDscExamplesPresent"
		"PSDSCDscTestsPresent"
		"PSDSCReturnCorrectTypesForDSCFunctions"
		"PSDSCStandardDSCFunctionsInResource"
		"PSDSCUseIdenticalMandatoryParametersForDSC"
		"PSDSCUseIdenticalParametersForDSC"
		"PSDSCUseVerboseMessageInDSCResource"
		#
		# ScriptFunctions
		#
		"PSAvoidUsingCmdletAliases"
		"PSAvoidUsingWMICmdlet"
		"PSAvoidUsingEmptyCatchBlock"
		"PSUseCmdletCorrectly"
		"PSUseShouldProcessForStateChangingFunctions"
		"PSAvoidUsingPositionalParameters"
		"PSAvoidGlobalVars"
		"PSUseDeclaredVarsMoreThanAssignments"
		"PSAvoidUsingInvokeExpression"
		#
		# ScriptingStyle
		#
		"PSProvideCommentHelp"
		"PSAvoidUsingWriteHost"
		# NOTE: New settings v1.19.1
		# "PSAvoidUsingDoubleQuotesForConstantString"
		"PSUseUsingScopeModifierInNewRunspaces"
		"PSAvoidSemicolonsAsLineTerminators"
		#
		# ScriptSecurity
		#
		"PSAvoidUsingPlainTextForPassword"
		"PSAvoidUsingComputerNameHardcoded"
		"PSUsePSCredentialType"
		"PSAvoidUsingConvertToSecureStringWithPlainText"
		"PSAvoidUsingUserNameAndPasswordParams"
		# NOTE: New settings v1.19.1
		"PSAvoidUsingBrokenHashAlgorithms"
		#
		# Rules not includes in samples
		#
		"PSAvoidAssignmentToAutomaticVariable"
		"PSAvoidDefaultValueForMandatoryParameter"
		"PSAvoidGlobalAliases"
		"PSAvoidGlobalFunctions"
		"PSAvoidInvokingEmptyMembers"
		# "PSAvoidLongLines"
		"PSAvoidOverwritingBuiltInCmdlets"
		"PSAvoidNullOrEmptyHelpMessageAttribute"
		"PSAvoidShouldContinueWithoutForce"
		"PSAvoidUsingDeprecatedManifestFields"
		"PSAvoidTrailingWhitespace"
		"PSMisleadingBacktick"
		"PSPossibleIncorrectComparisonWithNull"
		"PSPossibleIncorrectUsageOfAssignmentOperator"
		"PSPossibleIncorrectUsageOfRedirectionOperator"
		"PSReviewUnusedParameter"
		"PSUseLiteralInitializerForHashtable"
		"PSUseOutputTypeCorrectly"
		"PSUseProcessBlockForPipelineCommand"
		"PSUseSupportsShouldProcess"
		"PSUseToExportFieldsInManifest"
		# "PSUseCompatibleCmdlets"
		# "PSUseCompatibleCommands"
		"PSUseCompatibleSyntax"
		"PSUseCompatibleTypes"
		"PSUseUTF8EncodingForHelpFile"
		"PSUseBOMForUnicodeEncodedFile"
		#
		# Code formatting, Allman
		#
		"PSPlaceOpenBrace"
		"PSPlaceCloseBrace"
		"PSUseConsistentWhitespace"
		"PSUseConsistentIndentation"
		# "PSAlignAssignmentStatement"
		"PSUseCorrectCasing"
	)

	# NOTE: powershell.codeFormatting strings are settings for PSScriptAnalyzer which
	# ships with PowerShell VSCode
	# TODO: not all options have defaults mentioned in comments
	Rules = @{
		#
		# Following settings are related to Allman above
		#

		PSPlaceOpenBrace = @{
			# default = $false
			Enable = $true
			# NOTE: Allman style (not on same line)
			# Enforce open brace to be on the same line as that of its preceding keyword.
			# default = true (powershell.codeFormatting.openBraceOnSameLine)
			OnSameLine = $false
			# Enforce a new line character after an open brace.
			# default = false (powershell.codeFormatting.newLineAfterOpenBrace)
			NewLineAfter = $true
			# Indicates if open braces in a one line block should be ignored or not.
			# E.g. $x = if ($true) { "blah" } else { "blah blah" } In the above example,
			# if the property is set to true then the rule will not fire a violation.
			# default = true (powershell.codeFormatting.ignoreOneLineBlock)
			IgnoreOneLineBlock = $true
		}

		PSPlaceCloseBrace = @{
			# default = $false
			Enable = $true
			# Indicates if a new line should follow a close brace.
			# If set to true a close brace should be followed by a new line.
			# default = true (powershell.codeFormatting.newLineAfterCloseBrace)
			NewLineAfter = $true
			# Indicates if close braces in a one line block should be ignored or not.
			# E.g. $x = if ($true) { "blah" } else { "blah blah" } In the above example,
			# if the property is set to true then the rule will not fire a violation
			# default = true (powershell.codeFormatting.ignoreOneLineBlock)
			IgnoreOneLineBlock = $true
			# Create violation if there is an empty line before a close brace.
			# default = false
			NoEmptyLineBefore = $true
		}

		PSUseConsistentWhitespace = @{
			# default = $false
			Enable = $true
			# Checks if there is a space after the opening brace and a space
			# before the closing brace.
			# E.g. if ($true) { foo } instead of if ($true) {bar}
			# default = true (powershell.codeFormatting.WhitespaceInsideBrace)
			CheckInnerBrace = $true
			# Checks if there is a space between a keyword and its corresponding open brace.
			# E.g. foo { } instead of foo{ }
			# default = true (powershell.codeFormatting.whitespaceBeforeOpenBrace)
			CheckOpenBrace = $true
			# Checks if there is space between a keyword and its corresponding open parenthesis.
			#  E.g. if (true) instead of if(true)
			# default = true (powershell.codeFormatting.whitespaceBeforeOpenParen)
			CheckOpenParen = $true
			# Checks if a binary or unary operator is surrounded on both sides by a space.
			# E.g. $x = 1 instead of $x=1
			# default = true (powershell.codeFormatting.whitespaceAroundOperator)
			CheckOperator = $true
			# Checks if a pipe is surrounded on both sides by a space but
			# ignores redundant whitespace.
			# E.g. foo | bar instead of foo|bar
			# default = true (powershell.codeFormatting.addWhitespaceAroundPipe)
			CheckPipe = $true
			# Checks if a comma or a semicolon is followed by a space.
			# E.g. @(1, 2, 3) or @{a = 1; b = 2} instead of @(1,2,3) or @{a = 1;b = 2}
			# default = true (powershell.codeFormatting.whitespaceAfterSeparator)
			CheckSeparator = $true
			# Checks if a pipe is surrounded by redundant whitespace (i.e. more than 1 whitespace).
			# E.g. foo | bar instead of foo  |  bar
			# default = false (powershell.codeFormatting.trimWhitespaceAroundPipe)
			CheckPipeForRedundantWhitespace = $true
			# Checks if there is more than one space between parameters and values.
			# E.g. foo -bar $baz -bat instead of foo  -bar $baz  -bat
			# default = false (powershell.codeFormatting.whitespaceBetweenParameters)
			CheckParameter = $true
		}

		PSUseConsistentIndentation = @{
			# default = $false
			Enable = $true
			# Represents the kind of indentation to be used.
			# Possible values are: space, tab (default = space)
			Kind = "tab" # editor.insertSpaces, editor.detectIndentation
			# Whether to increase indentation after a pipeline for multi-line statements
			# IncreaseIndentationForFirstPipeline (default),
			# IncreaseIndentationAfterEveryPipeline, NoIndentation
			# powershell.codeFormatting.pipelineIndentationStyle
			PipelineIndentation = "NoIndentation"
			# Indentation size in the number of space characters (default = 4)
			IndentationSize = 4 # editor.tabSize
		}

		# Enforce alignment of assignment statements in a hashtable and in a DSC Configuration
		PSAlignAssignmentStatement = @{
			# default = false
			Enable = $false

			# default = false (powershell.codeFormatting.alignPropertyValuePairs)
			CheckHashtable = $false
		}

		PSUseCorrectCasing = @{
			# Use exact casing of the cmdlet and its parameters
			# TODO: default = ? (powershell.codeFormatting.useCorrectCasing)
			Enable = $true
		}

		#
		# Following settings are related to those not included in samples
		#

		PSProvideCommentHelp = @{
			# default = $true
			Enable = $true
			# NOTE: unwanted
			# If enabled, throw violation only on functions/cmdlets that are exported
			# using the 'Export-ModuleMember' cmdlet
			# default = true
			ExportedOnly = $false
			# returns comment help in block comment style, i.e., <#...#>.
			# Otherwise returns comment help in line comment style
			# default = true
			BlockComment = $true
			# If enabled, returns comment help in vscode snippet format.
			# default = false
			# TODO: make use of snippets
			VSCodeSnippetCorrection = $false
			# Represents the position of comment help with respect to the function definition
			# default = before
			Placement = "before"
		}

		PSAvoidUsingCmdletAliases = @{
			# To prevent PSScriptAnalyzer from flagging your preferred aliases,
			# create a whitelist of the aliases
			Allowlist = @()
		}

		# Identifies syntax elements that are incompatible with targeted PowerShell versions
		PSUseCompatibleSyntax = @{
			# default = ?
			Enable = $true

			# PowerShell versions for which to check syntax compatibility
			TargetVersions = @(
				"7.3",
				"5.1"
			)
		}

		# Lines should be no longer than a configured number of characters
		PSAvoidLongLines = @{
			# Default = false
			Enable = $true

			# Default = 120
			MaximumLineLength = 120
		}

		# Lines should not end with a semicolon.
		PSAvoidSemicolonsAsLineTerminators = @{
			# default = $false
			Enable = $true
		}

		# NOTE: unwanted
		# Single quotes should be used when the value of a string is constant.
		PSAvoidUsingDoubleQuotesForConstantString = @{
			# default = $false
			Enable = $true
		}

		#
		# TODO: Following rules needs generating custom updated settings
		#

		# This rule flags cmdlets that are not available in a given Edition/Version of
		# PowerShell on a given Operating System.
		# These strings are of the form, PSEDITION-PSVERSION-OS where:
		# PSEDITION can be either Core or Desktop
		# OS can be either Windows, Linux or MacOS
		# PSVERSION is the PowerShell version.
		# Syntax: <psedition>-<psversion>-<os>
		PSUseCompatibleCmdlets = @{
			# The parameter compatibility is a list that contain any of the following:
			# desktop-2.0-windows
			# desktop-3.0-windows
			# desktop-4.0-windows (taken from Windows Server 2012R2)
			# desktop-5.1.14393.206-windows
			# core-6.1.0-windows (taken from Windows 10 - 1803)
			# core-6.1.0-linux (taken from Ubuntu 18.04)
			# core-6.1.0-linux-arm (taken from Raspbian)
			# core-6.1.0-macos
			# NOTE: You can also create a custom settings file with:
			# https://github.com/PowerShell/PSScriptAnalyzer/blob/development/Utils/New-CommandDataFile.ps1
			compatibility = @(
				"desktop-5.1.14393.206-windows"
				# Windows 10 - 1803
				"core-6.1.0-windows"
			)
		}

		# This rule flags cmdlets that are available in a given edition/version of PowerShell on a
		# given operating system which are overwritten by a function declaration.
		PSAvoidOverwritingBuiltInCmdlets = @{
			# Default = "core-6.1.0-windows" if PS 6+ is installed, and "desktop-5.1.14393.206-windows" if not.
			PowerShellVersion = @(
				"desktop-5.1.14393.206-windows"
				# Windows 10 - 1803
				"core-6.1.0-windows"
			)
		}

		# This rule identifies types that are not available (loaded by default) in targeted PowerShell platforms.
		PSUseCompatibleTypes = @{
			# Activates the rule
			# default = $false
			Enable = $true

			# The location to search for profiles by name and use for union profile generation
			# default = compatibility_profiles directory in PSScriptAnalyzer module
			# ProfileDirPath = @()

			# NOTE: To update platforms see and comments see:
			# https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/usecompatiblecommands
			# and C:\Program Files\WindowsPowerShell\Modules\PSScriptAnalyzer\<VERSION>\compatibility_profiles
			# and https://learn.microsoft.com/en-us/windows/release-health/release-information
			# and https://learn.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
			# NOTE: To build your own list see:
			# https://github.com/PowerShell/PSScriptAnalyzer/tree/development/PSCompatibilityCollector
			# Syntax: <os-name>_<os-arch>_<os-version>_<ps-version>_<ps-arch>_<dotnet-version>_<dotnet-edition>

			# The list of PowerShell profiles to target
			# default = @()
			TargetProfiles = @(
				# Windows 10 (version 1903) (PowerShell 7.0)
				"win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core"
				# Windows 10 (version 1809) (PowerShell 5.1)
				"win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework"
				# Windows Server 2019 (version 1809) (PowerShell 7.0)
				"win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core"
				# Windows Server 2019 (version 1809) (PowerShell 5.1)
				"win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework"
			)

			# string: absolute path to new profile dir
			# defaults to compatibility_profiles directory in PSScriptAnalyzer module
			# ProfileDirPath = ""

			# Full names of types or type accelerators to ignore compatibility of in scripts
			# default = @()
			IgnoreTypes = @(
				# These types are used in Test-Credential function
				"System.DirectoryServices.AccountManagement.ContextType"
				"System.DirectoryServices.AccountManagement.PrincipalContext"
			)
		}

		# This rule identifies commands that are not available on a targeted PowerShell platform.
		PSUseCompatibleCommands = @{
			# default = $false
			Enable = $true

			# The list of PowerShell profiles to target, see PSUseCompatibleTypes
			# default = @()
			TargetProfiles = @(
				# Windows 10 (version 1903) (PowerShell 7.0)
				"win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core"
				# Windows 10 (version 1809) (PowerShell 5.1)
				"win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework"
				# Windows Server 2019 (version 1809) (PowerShell 7.0)
				"win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core"
				# Windows Server 2019 (version 1809) (PowerShell 5.1)
				"win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework"
			)

			# string: absolute path to new profile dir
			# defaults to compatibility_profiles directory in PSScriptAnalyzer module
			# ProfileDirPath = ""

			# Commands to ignore compatibility of in scripts
			# default = @()
			IgnoreCommands = @()
		}
	}
}

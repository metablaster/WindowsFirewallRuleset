
# https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation
# NOTE: PSGalery ruleset is a duplicate of these

@{
	IncludeRules = @(
		#
		# CmdletDesign
		#
		'PSUseApprovedVerbs',
		'PSReservedCmdletChar',
		'PSReservedParams',
		'PSShouldProcess',
		'PSUseSingularNouns',
		'PSMissingModuleManifestField',
		'PSAvoidDefaultValueSwitchParameter',
		#
		# 'PSDSC*',
		# Desired State Configuration is a management platform in PowerShell that enables you to
		# manage your IT and development infrastructure with configuration as code
		#
		'PSDSCDscExamplesPresent'
		'PSDSCDscTestsPresent'
		'PSDSCReturnCorrectTypesForDSCFunctions'
		'PSDSCStandardDSCFunctionsInResource'
		'PSDSCUseIdenticalMandatoryParametersForDSC'
		'PSDSCUseIdenticalParametersForDSC'
		'PSDSCUseVerboseMessageInDSCResource'
		#
		# ScriptFunctions
		#
		'PSAvoidUsingCmdletAliases',
		'PSAvoidUsingWMICmdlet',
		'PSAvoidUsingEmptyCatchBlock',
		'PSUseCmdletCorrectly',
		# TODO: temporary disabled
		# 'PSUseShouldProcessForStateChangingFunctions',
		'PSAvoidUsingPositionalParameters',
		'PSAvoidGlobalVars',
		'PSUseDeclaredVarsMoreThanAssignments',
		'PSAvoidUsingInvokeExpression',
		#
		# ScriptingStyle
		#
		'PSProvideCommentHelp',
		'PSAvoidUsingWriteHost',
		#
		# ScriptSecutiry
		#
		'PSAvoidUsingPlainTextForPassword',
		'PSAvoidUsingComputerNameHardcoded',
		'PSUsePSCredentialType',
		'PSAvoidUsingConvertToSecureStringWithPlainText',
		'PSAvoidUsingUserNameAndPasswordParams',
		#
		# Rules not includes in samples
		#
		'PSAvoidAssignmentToAutomaticVariable'
		'PSAvoidDefaultValueForMandatoryParameter'
		'PSAvoidGlobalAliases'
		'PSAvoidGlobalFunctions'
		'PSAvoidInvokingEmptyMembers'
		'PSAvoidLongLines'
		'PSAvoidOverwritingBuiltInCmdlets'
		'PSAvoidNullOrEmptyHelpMessageAttribute'
		'PSAvoidShouldContinueWithoutForce'
		'PSAvoidUsingDeprecatedManifestFields'
		'PSAvoidTrailingWhitespace'
		'PSMisleadingBacktick'
		'PSPossibleIncorrectComparisonWithNull'
		'PSPossibleIncorrectUsageOfAssignmentOperator'
		'PSPossibleIncorrectUsageOfRedirectionOperator'
		'PSReviewUnusedParameter'
		'PSUseLiteralInitializerForHashtable'
		'PSUseOutputTypeCorrectly'
		'PSUseProcessBlockForPipelineCommand'
		'PSUseSupportsShouldProcess'
		'PSUseToExportFieldsInManifest'
		# 'PSUseCompatibleCmdlets'
		'PSUseCompatibleCommands'
		'PSUseCompatibleSyntax'
		'PSUseCompatibleTypes'
		'PSUseUTF8EncodingForHelpFile'
		'PSUseBOMForUnicodeEncodedFile'
		#
		# Code formatting, Allman
		#
		'PSPlaceOpenBrace',
		'PSPlaceCloseBrace',
		'PSUseConsistentWhitespace',
		'PSUseConsistentIndentation',
		'PSAlignAssignmentStatement',
		'PSUseCorrectCasing'
	)

	Rules = @{
		#
		# Following settings are related to Allman above
		#

		PSPlaceOpenBrace = @{
			Enable = $true
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
			Enable = $true
			# Checks if there is a space after the opening brace and a space before the closing brace.
			# E.g. if ($true) { foo } instead of if ($true) {bar}
			# default = true (powershell.codeFormatting.WhitespaceInsideBrace)
			CheckInnerBrace = $true
			# Checks if there is a space between a keyword and its corresponding open brace.
			# E.g. foo { } instead of foo{ }
			# default = true (powershell.codeFormatting.whitespaceBeforeOpenBrace)
			# TODO: doesn't work as expected
			CheckOpenBrace = $false
			# Checks if there is space between a keyword and its corresponding open parenthesis.
			#  E.g. if (true) instead of if(true)
			# default = true (powershell.codeFormatting.whitespaceBeforeOpenParen)
			CheckOpenParen = $true
			# Checks if a binary or unary operator is surrounded on both sides by a space.
			# E.g. $x = 1 instead of $x=1
			# default = true (powershell.codeFormatting.whitespaceAroundOperator)
			CheckOperator = $true
			# Checks if a pipe is surrounded on both sides by a space but ignores redundant whitespace.
			# E.g. foo | bar instead of foo|bar
			# default = true (powershell.codeFormatting.WhitespaceAroundPipe)
			CheckPipe = $true
			# Checks if a comma or a semicolon is followed by a space.
			# E.g. @(1, 2, 3) or @{a = 1; b = 2} instead of @(1,2,3) or @{a = 1;b = 2}
			# default = true (powershell.codeFormatting.whitespaceAfterSeparator)
			CheckSeparator = $true
			# Checks if a pipe is surrounded by redundant whitespace (i.e. more than 1 whitespace).
			# E.g. foo | bar instead of foo  |  bar
			# default = false
			CheckPipeForRedundantWhitespace = $true
			# Checks if there is more than one space between parameters and values.
			# E.g. foo -bar $baz -bat instead of foo  -bar $baz  -bat
			# default = false
			CheckParameter = $true
		}

		PSUseConsistentIndentation = @{
			# TODO: temporarly disabled
			Enable = $false
			# Represents the kind of indentation to be used. Possible values are: space, tab (default = space)
			Kind = 'tab' # editor.insertSpaces, editor.detectIndentation
			# Whether to increase indentation after a pipeline for multi-line statements
			# IncreaseIndentationForFirstPipeline (default), IncreaseIndentationAfterEveryPipeline, NoIndentation
			PipelineIndentation = 'NoIndentation' # powershell.codeFormatting.pipelineIndentationStyle
			# Indentation size in the number of space characters (default = 4)
			IndentationSize = 4 # editor.tabSize
		}

		PSAlignAssignmentStatement = @{
			# default = false
			Enable = $false
			# Enforce alignment of assignment statements in a hashtable and in a DSC Configuration
			# default = false (powershell.codeFormatting.alignPropertyValuePairs)
			CheckHashtable = $true
		}

		PSUseCorrectCasing = @{
			# Use exact casing of the cmdlet and its parameters
			# default = ? (powershell.codeFormatting.useCorrectCasing)
			Enable = $true
		}

		#
		# Following settings are related to those not included in samples
		#

		PSProvideCommentHelp = @{
			Enable = $true
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
			VSCodeSnippetCorrection = $false
			# Represents the position of comment help with respect to the function definition
			# default = before
			Placement = "before"
		}

		PSAvoidUsingCmdletAliases = @{
			# To prevent PSScriptAnalyzer from flagging your preferred aliases,
			# create a whitelist of the aliases
			Whitelist = @()
		}

		PSUseCompatibleSyntax = @{
			# identifies syntax elements that are incompatible with targeted PowerShell versions
			Enable = $true
			TargetVersions = @(
				"7.0",
				"5.1"
			)
		}

		#
		# TODO: temporarly disabled
		#

		PSUseCompatibleCmdlets = @{
			compatibility = @(
				"core-6.1.0-windows"
				"desktop-5.1.14393.206-windows"
			)
		}

		#
		# TODO: used but settings not configured
		#

		# PSUseCompatibleTypes = @{
		#     Enable = $true
		#     TargetProfiles = @(
		# 		'win-48_x64_10.0.18363.0_5.1.18362.628_x64_4.0.30319.42000_framework'
		# 		'win-48_x64_10.0.18363.0_7.0.0_x64_3.1.1_core'
		#     )

		# 	IgnoreTypes = @(
		#         'System.IO.Compression.ZipFile'
		#     )
		# }
	}
}

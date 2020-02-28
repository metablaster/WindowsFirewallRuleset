
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
		'PSUseShouldProcessForStateChangingFunctions',
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
		# Allman
		#
		'PSPlaceOpenBrace',
		'PSPlaceCloseBrace',
		'PSUseConsistentWhitespace',
		'PSUseConsistentIndentation',
		'PSAlignAssignmentStatement',
		'PSUseCorrectCasing'
	)

	# These are related to Allman above
	Rules = @{
		PSPlaceOpenBrace = @{
			# TODO: disabled for Approve-Execute function
			Enable = $false
			OnSameLine = $true
			NewLineAfter = $true
			IgnoreOneLineBlock = $false
		}

		PSPlaceCloseBrace = @{
			# TODO: disabled for Approve-Execute function
			Enable = $false
			NewLineAfter = $true
			IgnoreOneLineBlock = $false
			NoEmptyLineBefore = $true
		}

		PSUseConsistentWhitespace = @{
			Enable = $true
			# Checks if there is a space after the opening brace and a space before the closing brace.
			# E.g. if ($true) { foo } instead of if ($true) {bar}
			CheckInnerBrace = $true
			# Checks if there is a space between a keyword and its corresponding open brace.
			# E.g. foo { } instead of foo{ }
			# TODO: doesn't work as expected
			CheckOpenBrace = $false
			# Checks if there is space between a keyword and its corresponding open parenthesis.
			#  E.g. if (true) instead of if(true)
			CheckOpenParen = $true
			# Checks if a binary or unary operator is surrounded on both sides by a space.
			# E.g. $x = 1 instead of $x=1
			CheckOperator = $true
			# Checks if a pipe is surrounded on both sides by a space but ignores redundant whitespace.
			# E.g. foo | bar instead of foo|bar
			CheckPipe = $true
			# Checks if a comma or a semicolon is followed by a space.
			# E.g. @(1, 2, 3) or @{a = 1; b = 2} instead of @(1,2,3) or @{a = 1;b = 2}
			CheckSeparator = $true
			# Checks if a pipe is surrounded by redundant whitespace (i.e. more than 1 whitespace).
			# E.g. foo | bar instead of foo  |  bar
			CheckPipeForRedundantWhitespace = $true
			# Checks if there is more than one space between parameters and values.
			# E.g. foo -bar $baz -bat instead of foo  -bar $baz  -bat
			CheckParameter = $true
		}

		PSUseConsistentIndentation = @{
			# TODO: temporarly disabled
			Enable = $false
			Kind = 'tab'
			PipelineIndentation = 'NoIndentation'
			IndentationSize = 4
		}

		PSAlignAssignmentStatement = @{
			Enable = $false
			CheckHashtable = $true
		}

		PSUseCorrectCasing = @{
			Enable = $true
		}

		# These are related to those not included in samples
		# PSAvoidUsingCmdletAliases = @{
		# 	Whitelist = @('cd')
		# }

		PSProvideCommentHelp = @{
			Enable = $true
			ExportedOnly = $false
			BlockComment = $true
			VSCodeSnippetCorrection = $false
			Placement = "before"
		}

		# TODO: temporarly disabled
		PSUseCompatibleCmdlets = @{
			compatibility = @(
				"core-6.1.0-windows"
				"desktop-5.1.14393.206-windows"
			)
		}

		PSUseCompatibleSyntax = @{
			Enable = $true
			TargetVersions = @(
				"7.0",
				"5.1"
			)
		}

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

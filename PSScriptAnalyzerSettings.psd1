
# https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation
# NOTE: PSGalery ruleset is a duplicate of these

@{
	IncludeRules = @(
		# CmdletDesign
		'PSUseApprovedVerbs',
		'PSReservedCmdletChar',
		'PSReservedParams',
		'PSShouldProcess',
		'PSUseSingularNouns',
		'PSMissingModuleManifestField',
		'PSAvoidDefaultValueSwitchParameter',
		# 'PSDSC*',
		'PSDSCDscExamplesPresent'
		'PSDSCDscTestsPresent'
		'PSDSCReturnCorrectTypesForDSCFunctions'
		'PSDSCStandardDSCFunctionsInResource'
		'PSDSCUseIdenticalMandatoryParametersForDSC'
		'PSDSCUseIdenticalParametersForDSC'
		'PSDSCUseVerboseMessageInDSCResource'
		# ScriptFunctions
		'PSAvoidUsingCmdletAliases',
		'PSAvoidUsingWMICmdlet',
		'PSAvoidUsingEmptyCatchBlock',
		'PSUseCmdletCorrectly',
		'PSUseShouldProcessForStateChangingFunctions',
		'PSAvoidUsingPositionalParameters',
		'PSAvoidGlobalVars',
		'PSUseDeclaredVarsMoreThanAssignments',
		'PSAvoidUsingInvokeExpression',
		# ScriptingStyle
		'PSProvideCommentHelp',
		'PSAvoidUsingWriteHost',
		# ScriptSecutiry
		'PSAvoidUsingPlainTextForPassword',
		'PSAvoidUsingComputerNameHardcoded',
		'PSUsePSCredentialType',
		'PSAvoidUsingConvertToSecureStringWithPlainText',
		'PSAvoidUsingUserNameAndPasswordParams',
		# Rules not includes in samples
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
		'PSUseCompatibleCmdlets'
		'PSUseCompatibleCommands'
		'PSUseCompatibleSyntax'
		'PSUseCompatibleTypes'
		'PSUseUTF8EncodingForHelpFile'
		'PSUseBOMForUnicodeEncodedFile'
		# Allman
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
			Enable = $true
			OnSameLine = $false
			NewLineAfter = $true
			IgnoreOneLineBlock = $false
		}

		PSPlaceCloseBrace = @{
			Enable = $true
			NewLineAfter = $true
			IgnoreOneLineBlock = $false
			NoEmptyLineBefore = $true
		}

		PSUseConsistentWhitespace = @{
			Enable = $true
			CheckInnerBrace = $true
			CheckOpenBrace = $true
			CheckOpenParen = $true
			CheckOperator = $true
			CheckPipe = $true
			CheckSeparator = $true
		}

		PSUseConsistentIndentation = @{
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

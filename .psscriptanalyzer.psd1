@{
    # Use the recommended default rules plus extra strictness
    Severity     = @('Error', 'Warning', 'Information')

    Rules        = @{
        # Enforce approved verbs
        PSUseApprovedVerbs                    = @{ Enable = $true }

        # Require comment-based help on all functions
        PSProvideCommentHelp                  = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }

        # Avoid aliases in scripts
        PSAvoidUsingCmdletAliases             = @{ Enable = $true }

        # Prefer -ErrorAction Stop over silent failures
        PSAvoidUsingEmptyCatchBlock           = @{ Enable = $true }

        # Warn about Write-Host (acceptable in our styling functions, but
        # flag it elsewhere so reviewers can confirm the intent)
        PSAvoidUsingWriteHost                 = @{ Enable = $true }

        # Enforce consistent indentation
        PSUseConsistentIndentation            = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        # Prefer single quotes where no interpolation is needed
        PSAvoidUsingDoubleQuotesForConstantString = @{ Enable = $true }

        # Require $null on the left in comparisons
        PSPossibleIncorrectComparisonWithNull = @{ Enable = $true }

        # Warn about uninitialized variables
        PSUseDeclaredVarsMoreThanAssignments  = @{ Enable = $true }
    }

    ExcludeRules = @(
        # UTF-8 BOM is not required; files without BOM are valid UTF-8
        'PSUseBOMForUnicodeEncodedFile'

        # Our Write-* functions intentionally use Write-Host for styled console output
        'PSAvoidUsingWriteHost'

        # Allow $Profile as a parameter name in AWS examples (natural AWS CLI naming)
        'PSAvoidAssignmentToAutomaticVariable'

        # Allow Invoke-Aws as a concise helper name in examples
        'PSUseSingularNouns'
    )

}

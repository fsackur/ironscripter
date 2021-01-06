#requires -Modules @{ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.19.1'}

function New-ClassDefinition
{
    <#
        .Synopsis
        Given an object, create a powershell class definition, outputted as executable PS code.
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$ClassName
    )

    $Def = [Text.StringBuilder]::new()
    [void]$Def.Append("class ").AppendLine($ClassName)
    [void]$Def.AppendLine("{")


    [void]$Def.AppendLine("#region Properties")
    foreach ($Property in $InputObject.PSObject.Properties)
    {
        [void]$Def.Append("[").Append($Property.TypeNameOfValue -replace '^System.').Append("]")
        [void]$Def.Append("$").AppendLine($Property.Name)
    }
    [void]$Def.AppendLine("#endregion Properties")

    [void]$Def.AppendLine("}")


    Invoke-Formatter $Def.ToString() -Settings CodeFormattingAllman
}

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
    $Properties = $InputObject.PSObject.Properties
    foreach ($Property in $Properties)
    {
        $Type = $Property.TypeNameOfValue -replace '^System.'

        if ($Property.Membertype -eq 'Property' -and -not $Property.IsInstance)
        {
            [void]$Def.Append("static ")
        }
        [void]$Def.Append("[").Append($Type).Append("]")
        [void]$Def.Append("$").AppendLine($Property.Name)
    }
    [void]$Def.AppendLine("#endregion Properties")

    [void]$Def.AppendLine("}")


    Invoke-Formatter $Def.ToString() -Settings CodeFormattingAllman
}

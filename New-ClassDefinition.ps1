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
    $Properties = $InputObject.PSObject.Properties | Sort-Object IsInstance, Name
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



    [void]$Def.AppendLine().AppendLine()



    [void]$Def.AppendLine("#region Methods")
    $Methods = $InputObject.PSObject.Methods | Sort-Object IsInstance, Name
    foreach ($Method in $Methods)
    {
        $Type = $Method.Value -replace ' .*' -replace '^System.'
        $Params = $Method.Value -replace '.*\(' -replace '\)' -split ', '
        [void]$Def.Append("[").Append($Type).Append("] ")
        [void]$Def.Append($Method.Name)

        [void]$Def.Append("(")
        if (-not [string]::IsNullOrWhiteSpace($Params))
        {
            foreach ($Param in $Params)
            {
                $PType, $PName = $Param -split ' '
                $PType = $PType -replace '^System\.'
                [void]$Def.Append("[").Append($PType).Append("]")
                [void]$Def.Append("$").Append($PName)
                [void]$Def.Append(", ")
            }
            # Clear the redundant trailing comma
            $Def.Length -= 2
        }
        [void]$Def.AppendLine(")")

        [void]$Def.AppendLine("{")
        [void]$Def.AppendLine("# Replace with your own method definition")
        [void]$Def.Append("return [").Append($Type).AppendLine("]::new()")
        [void]$Def.AppendLine("}")
    }
    [void]$Def.AppendLine("#endregion Methods")



    [void]$Def.AppendLine("}")


    Invoke-Formatter $Def.ToString() -Settings CodeFormattingAllman
}

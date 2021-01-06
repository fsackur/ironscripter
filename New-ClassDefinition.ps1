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

    foreach ($Property in $InputObject.PSObject.Properties)
    {
        [void]$Def.Append("[").Append($Property.TypeNameOfValue -replace '^System.').Append("]")
        [void]$Def.Append("$").AppendLine($Property.Name)
    }

    [void]$Def.AppendLine("}")

    $Def.ToString()
}

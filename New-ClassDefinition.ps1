#requires -Modules @{ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1"}

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
        [string]$ClassName,

        [string[]]$Property = "*",

        [string[]]$ExcludeProperty,

        [string[]]$Method = "*",

        [string[]]$ExcludeMethod
    )

    $Def = [Text.StringBuilder]::new()
    [void]$Def.Append("class ").AppendLine($ClassName)
    [void]$Def.AppendLine("{")


    [void]$Def.AppendLine("#region Constructors")

    $Type = $InputObject.GetType()
    $Ctors = $Type.GetConstructors("Instance, Public")
    foreach ($Ctor in $Ctors)
    {
        [void]$Def.Append($ClassName).Append(" (")

        $Params = $Ctor.GetParameters()
        if ($Params)
        {
            foreach ($Param in $Params)
            {
                $PName = $Param.Name
                $PType = $Param.ParameterType -replace "^System\."
                [void]$Def.Append("[").Append($PType).Append("]")
                [void]$Def.Append("$").Append($PName)
                [void]$Def.Append(", ")
            }
            # Clear the redundant trailing comma
            $Def.Length -= 2
        }
        [void]$Def.AppendLine(")")

        [void]$Def.AppendLine("{")
        [void]$Def.AppendLine("# Replace with your own ctor definition")
        [void]$Def.AppendLine("}")

        [void]$Def.AppendLine()
    }
    if ($Ctors)
    {
        $Def.Length -= [Environment]::NewLine.Length
    }
    [void]$Def.AppendLine("#endregion Constructors")


    [void]$Def.AppendLine().AppendLine()


    [void]$Def.AppendLine("#region Properties")

    $SelectSplat = @{
        Property = $Property
        ExcludeProperty = $ExcludeProperty
    }
    $FilteredObject = $InputObject |
        Select-Object @SelectSplat
    $Properties = $FilteredObject.PSObject.Properties |
        Sort-Object IsInstance, Name
    Remove-Variable Property    # Because I want to re-use the var name without the constraints

    foreach ($Property in $Properties)
    {
        $Type = $Property.TypeNameOfValue -replace "^System."

        if ($Property.Membertype -eq "Property" -and -not $Property.IsInstance)
        {
            [void]$Def.Append("static ")
        }
        [void]$Def.Append("[").Append($Type).Append("]")
        [void]$Def.Append("$").AppendLine($Property.Name)

        [void]$Def.AppendLine()
    }
    if ($Properties)
    {
        $Def.Length -= [Environment]::NewLine.Length
    }
    [void]$Def.AppendLine("#endregion Properties")



    [void]$Def.AppendLine().AppendLine()



    [void]$Def.AppendLine("#region Methods")

    $SelectSplat = @{
        Property = $Method
        ExcludeProperty = $ExcludeMethod
    }
    $Intermediate = [pscustomobject](
        $InputObject.PSObject.Methods |
            Group-Object Name -AsHashTable
    )
    $Intermediate = $Intermediate |
        Select-Object @SelectSplat
    $Methods = $Intermediate.PSObject.Properties.Value |
        Sort-Object IsInstance, Name
    Remove-Variable Method

    foreach ($Method in $Methods)
    {
        $Type = $Method.Value -replace " .*" -replace "^System."
        $Params = $Method.Value -replace ".*\(" -replace "\)" -split ", "
        [void]$Def.Append("[").Append($Type).Append("] ")
        [void]$Def.Append($Method.Name)

        [void]$Def.Append("(")
        if (-not [string]::IsNullOrWhiteSpace($Params))
        {
            foreach ($Param in $Params)
            {
                $PType, $PName = $Param -split " "
                $PType = $PType -replace "^System\."
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
        if ($Type -ne 'void')
        {
            [void]$Def.Append("return [").Append($Type).AppendLine("]::new()")
        }
        [void]$Def.AppendLine("}")

        [void]$Def.AppendLine()
    }
    if ($Methods)
    {
        $Def.Length -= [Environment]::NewLine.Length
    }
    [void]$Def.AppendLine("#endregion Methods")



    [void]$Def.AppendLine("}")


    Invoke-Formatter $Def.ToString() -Settings CodeFormattingAllman
}

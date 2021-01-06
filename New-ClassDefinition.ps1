#requires -Version 4 -Modules @{ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1"}

function New-ClassDefinition
{
    <#
        .Synopsis
        Given an object, create a powershell class definition, outputted as executable PS code.

        .Parameter InputObject
        Provide an object from which a class definition is to be generated.

        .Parameter ClassName
        Provide the name of the generated class.

        .Parameter Property
        Optionally, restrict the properties from the input object to this set. Works like
        Select-Object.

        .Parameter ExcludeProperty
        Optionally, exclude the properties from the input object to ones not in this set. Works like
        Select-Object.

        .Parameter Method
        Optionally, restrict the methods from the input object to this set. Works like
        Select-Object -Property.

        .Parameter ExcludeMethod
        Optionally, exclude the methods from the input object to ones not in this set. Works like
        Select-Object -ExcludeProperty.

        .Parameter ConstructorBody
        If a parameterless constructor exists in the input object, you can supply a body for it with
        this parameter.

        If no parameterless constructor exists, this parameter has no effect.

        .Example
        Get-Process -Id $PID | New-ClassDefinition -ClassName Fauxcess -Property Handle* -Method Wait*, Start*

        class Fauxcess
        {
            #region Constructors
            Fauxcess ()
            {
                # Replace with your own ctor definition
            }
            #endregion Constructors


            #region Properties
            [IntPtr]$Handle

            [Int32]$HandleCount

            [Int32]$Handles
            #endregion Properties


            #region Methods
            [bool] Start()
            {
                # Replace with your own method definition
                return [bool]::new()
            }

            [bool] WaitForExit([int]$milliseconds)
            {
                # Replace with your own method definition
                return [bool]::new()
            }

            [void] WaitForExit()
            {
                # Replace with your own method definition
            }

            [bool] WaitForInputIdle([int]$milliseconds)
            {
                # Replace with your own method definition
                return [bool]::new()
            }

            [bool] WaitForInputIdle()
            {
                # Replace with your own method definition
                return [bool]::new()
            }
            #endregion Methods
        }

        Generates a class definition from a ProcessInfo object. Placeholder methods matching 'Wait*'
        and 'Start*' have been added. Only the properties matching 'Handle*' have been included.
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$ClassName,

        [SupportsWildcards()]
        [string[]]$Property = "*",

        [SupportsWildcards()]
        [string[]]$ExcludeProperty,

        [SupportsWildcards()]
        [string[]]$Method = "*",

        [SupportsWildcards()]
        [string[]]$ExcludeMethod,

        [scriptblock]$ConstructorBody
    )

    # Could put code in process block, but can't think of a use case
    if ($input.Count -gt 1)
    {
        Write-Warning "More than one object was piped to $($MyInvocation.MyCommand.Name); only the last object will be used."
    }


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
        if ($ConstructorBody -and -not $Params)
        {
            [void]$Def.AppendLine($ConstructorBody)
        }
        else
        {
            [void]$Def.AppendLine("# Replace with your own ctor definition")
        }
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
        foreach ($Overload in $Method.OverloadDefinitions)
        {
            $Type = $Overload -replace " .*" -replace "^System."
            $Params = $Overload -replace ".*\(" -replace "\)" -split ", "
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
    }
    if ($Methods)
    {
        $Def.Length -= [Environment]::NewLine.Length
    }
    [void]$Def.AppendLine("#endregion Methods")



    [void]$Def.AppendLine("}")


    Invoke-Formatter $Def.ToString() -Settings CodeFormattingAllman
}

Add-Type -TypeDefinition @"
   public enum IisExpressObjectType
   {
      Site,
      App,
      Vdir,
      AppPool,
      Config,
      Module,
      Trace
   }
"@

Add-Type -TypeDefinition @"
   public enum IisExpressCommand
   {
      List,
      Add,
      Set,
      Delete
   }
"@


function Invoke-IisExpressAppCmd(
    # Identifier of the object
    [Parameter(Position=1)]
    [string]$Identifier,

    # Object type
    [Parameter(Mandatory, Position=2)]
    [IisExpressObjectType]$ObjectType,

    # Command to pass: list, etc.
    [Parameter(Mandatory, Position=3)]
    [string]$Command,

    # General parameters
    [Parameter()]
    $Parameters
)
{
    $paramCmdLineArg = ""
    if($Command -ieq "list") { $paramCmdLineArg = "/text:*"}

    if(($Parameters -ne $null) -or ($Parameters.Count -gt 0)) 
    {
        $paramCmdLineArg = ""
    }

    foreach($key in $Parameters.Keys)
    {
        $paramCmdLineArg = "$paramCmdLineArg/$($key):$($Parameters["$key"]) "
    }

    Push-Location

    # Set current directory of IIS Express (x64 on x64 OS otherwise 32-bit)
    Set-Location "$env:ProgramW6432\IIS Express"

    $identifierParam = if(-not [string]::IsNullOrWhiteSpace($Identifier)) 
    {
         """$Identifier"" "
    }
    else 
    {
        ""    
    }
    # Get result out of appcmd.exe invocation 
    $result = ".\appcmd $($Command.ToLower()) $($objectType.ToString().ToUpper()) $(
            )$identifierParam$($paramCmdLineArg.Trim())" | Invoke-Expression
    
    Pop-Location

    if($result -eq $null) { return $result } else { return $result.Trim() }
}

function Get-IisExpressSiteUrl(
    [Parameter(Mandatory)] $AppName,
    [Parameter()] [switch]$PreferHttps
    )
{
    $bindings = ([string](Invoke-IisExpressAppCmd "$AppName" "SITE" "list" `
        -Parameters @{ text = "bindings"; })).Split(',')

    $firsHttpsBinding = ($bindings `
        | Where-Object { $_.Contains("https") })

    $indexOfFirstHttpsBinding = $bindings.IndexOf($firsHttpsBinding)

    $bindingsParts = 
        if(-not $PreferHttps) { $bindings[0].Split('/') }
        else { $bindings[$indexOfFirstHttpsBinding].Split('/') }

    $bindingParts = $bindingsParts[1].Split(':')
    
    $scheme = $bindingsParts[0]
    $ip = $bindingParts[0]
    $port = $bindingParts[1]
    $hostname = $bindingParts[2]
    $portPart = ""

    # Wildcard "*" listens to all hosts, so localhost should be OK
    if(($hostname -eq "*") -or ($hostname -eq [string]::Empty))
    {
        $hostname = "localhost"
    }

    # Non default ports
    if(($port -ne "80") -and ($port -ne "443"))
    {
        $portPart = ":$port"
    }
    
    $result = "${scheme}://${hostname}${portPart}"
    return $result
}

function Remove-IisExpressObject (
    # Identifier of the object
    [Parameter(Mandatory, Position=1)]
    [string]$Identifier,
    
    # Object type
    [Parameter(Mandatory, Position=2)]
    [IisExpressObjectType]$ObjectType
)
{
    Invoke-IisExpressAppCmd $Identifier $ObjectType delete
}

function New-IisExpressObject (
    # Object type
    [Parameter(Mandatory, Position=1)]
    [IisExpressObjectType]$ObjectType,

    # Additional parameters
    [Parameter(Mandatory, Position=2)]
    $AdditionalParameters
)
{
    Invoke-IisExpressAppCmd $null $ObjectType add -Parameters $AdditionalParameters
}


function Test-IisExpressObject (
    # Identifier of the object
    [Parameter(Mandatory, Position=1)]
    [string]$Identifier,

    # Object type
    [Parameter(Mandatory, Position=2)]
    [IisExpressObjectType]$ObjectType
)
{
    $result = Invoke-IisExpressAppCmd $Identifier $ObjectType list

    return -not ([string]::IsNullOrWhiteSpace($result))
}
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaBase,

        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaHome,

        [parameter(Mandatory = $true)]
        [System.String]
        $JavaHome
    )

    $service_name = Get-TomcatServiceName
    $service = Get-Service -Name $service_name -ErrorAction SilentlyContinue

    if ($service -ne $null) {
        Write-Verbose "exists."
        $ensureResult = "Present"
    } else {
        Write-Verbose "does not exist."
        $ensureResult = "Absent"
    }

    return @{
        CatalinaBase = $CatalinaBase
        Ensure = $ensureResult
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaBase,

        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaHome,

        [parameter(Mandatory = $true)]
        [System.String]
        $JavaHome,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $result = Get-TargetResource -CatalinaBase $CatalinaBase -CatalinaHome $CatalinaHome -JavaHome $JavaHome

    if ($result.Ensure -eq "Present") {
        if ($Ensure -eq "Present") {
            Write-Verbose "do nothing."
        } else {
            Write-Verbose "remove."
            Invoke-TomcatServiceCommand -Option "remove"
        }
    } else {
        if ($Ensure -eq "Present") {
            Write-Verbose "install."
            Invoke-TomcatServiceCommand -Option "install"
        } else {
            Write-Verbose "do nothing."
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaBase,

        [parameter(Mandatory = $true)]
        [System.String]
        $CatalinaHome,

        [parameter(Mandatory = $true)]
        [System.String]
        $JavaHome,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $result = Get-TargetResource -CatalinaBase $CatalinaBase -CatalinaHome $CatalinaHome -JavaHome $JavaHome

    if ($result.Ensure -eq $Ensure) {
        Write-Verbose "existence same as expected."
        return $true
    } else {
        Write-Verbose "existence not as expected."
        return $false
    }
}


function Get-TomcatServiceName {
    $m = Select-String 'SERVICE_NAME=[A-Za-z0-9]+' (Get-TomcatServiceBatch)
    return ($m.Matches[0].Value -split '=')[1]
}


function Invoke-TomcatServiceCommand {
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $Option
    )

    $env:CATALINA_BASE = $CatalinaBase
    $env:CATALINA_HOME = $CatalinaHome
    $env:JAVA_HOME = $JavaHome

    $servicebat = Get-TomcatServiceBatch
    Write-Verbose "$servicebat $Option"
    & $servicebat $Option | Write-Verbose
}


function Get-TomcatServiceBatch {
    return "${CatalinaHome}\bin\service.bat"
}


Export-ModuleMember -Function *-TargetResource

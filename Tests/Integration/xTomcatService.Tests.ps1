$JavaVersion = "1.8.0_92"
$TomcatVersion = "8.0.33"
$global:test_javahome = "C:\jdk${JavaVersion}"
$global:test_catalinahome = "C:\apache-tomcat-${TomcatVersion}"

$resource_name = ($MyInvocation.MyCommand.Name -split '\.')[0]
$resource_path = $PSScriptRoot + "\..\..\DSCResources\${resource_name}"

if (! (Get-Module xDSCResourceDesigner)) {
    Import-Module -Name xDSCResourceDesigner
}

Describe -Tag 'DSCResource' "${resource_name}, the DSC resource" {
    It 'Passes Test-xDscResource' {
        Test-xDscResource $resource_path | Should Be $true
    }

    It 'Passes Test-xDscSchema' {
        Test-xDscSchema "${resource_path}\${resource_name}.schema.mof" | Should Be $true
    }
}

if (Get-Module $resource_name) {
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

Describe -Tag 'Integration' "${resource_name}, Integration Tests" {

    function New-TestService {
        & "${test_catalinahome}\bin\service.bat" "install"
    }

    function Remove-TestService {
        $service_name = InModuleScope $resource_name {
            $CatalinaHome = $global:test_catalinahome
            Get-TomcatServiceName
        }
        $service = Get-Service -Name $service_name -ErrorAction SilentlyContinue
        if ($service -ne $null) {
            & "${test_catalinahome}\bin\service.bat" "remove"
        }
    }

    Context "Service doesn't exist" {
        Remove-TestService

        It 'Detects if change is required' {
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present" | Should Be $false
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent" | Should Be $true
        }

        It 'Installs the service' {
            Set-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present" | Should Be $true
        }
    }

    Context "Service exists" {
        Remove-TestService
        New-TestService

        It 'Detects if change is required' {
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present" | Should Be $true
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent" | Should Be $false
        }

        It 'Removes the service' {
            Set-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent"
            Test-TargetResource -CatalinaBase $test_catalinahome -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent" | Should Be $true
        }
    }

    Remove-TestService
}

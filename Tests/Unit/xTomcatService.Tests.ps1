$resource_name = ($MyInvocation.MyCommand.Name -split '\.')[0]
$resource_path = $PSScriptRoot + "\..\..\DSCResources\${resource_name}"
$global:testcase_path = $PSScriptRoot + "\..\Cases"

if (Get-Module $resource_name) {
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

InModuleScope $resource_name {
    $test_catalinabase = "X:\tomcat base"
    $test_catalinahome = "X:\apache tomcat 12.34.56 windows-x64"
    $test_javahome = "X:\Program Files\jdk1.8.0_92"
    $test_service_name = "Tomcat12"

    $resource_name = $MyInvocation.MyCommand.ScriptBlock.Module.Name

    Describe "${resource_name}, Get-TomcatServiceName" {
        Context 'Called on service.bat from hypothetical Tomcat 12.x' {
            Mock Get-TomcatServiceBatch { return "${global:testcase_path}\service.bat" }

            $returnValue = Get-TomcatServiceName

            It 'Returns Tomcat12' {
                $returnValue | Should BeExactly "Tomcat12"
            }
        }
    }

    Describe "${resource_name}, Get-TargetResource" {
        Mock Get-TomcatServiceName { return $test_service_name }
        Mock Get-Service { $anything = 0; return $anything }

        Get-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome

        It 'Calls Get-Service with expected arguments' {
            Assert-MockCalled Get-Service -ParameterFilter {
                $Name -eq $test_service_name
            }
        }

        Context 'Service exists' {
            $returnValue = Get-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome

            It 'Returns Ensure = Present' {
                $returnValue.Ensure | Should BeExactly "Present"
            }
        }
        Context "Service doesn't exist" {
            Mock Get-Service { return $null }

            $returnValue = Get-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome

            It 'Returns Ensure = Absent' {
                $returnValue.Ensure | Should BeExactly "Absent"
            }
        }
    }
    Describe "${resource_name}, Test-TargetResource" {
        Mock Get-TargetResource {}

        Test-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome

        It 'Calls Get-TargetResource with expected arguments' {
            Assert-MockCalled Get-TargetResource -ParameterFilter {
                ($CatalinaBase -eq $test_catalinabase) `
                -and ($CatalinaHome -eq $test_catalinahome) `
                -and ($JavaHome -eq $test_javahome)
            }
        }

        Context "Service exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            $returnValue = Test-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present"

            It 'Returns true when Ensure = Present' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent"

            It 'Returns false when Ensure = Absent' {
                $returnValue | Should BeExactly $false
            }
        }
        Context "Service doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            $returnValue = Test-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent"

            It 'Returns true when Ensure = Absent' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present"

            It 'Returns false when Ensure = Present' {
                $returnValue | Should BeExactly $false
            }
        }
    }

    Describe "${resource_name}, Set-TargetResource" {
        Mock Invoke-TomcatServiceCommand {}

        Context "Service exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present"

            It 'Does nothing when when Ensure = Present' {
                Assert-MockCalled Invoke-TomcatServiceCommand -Exactly -Times 0
            }
        }
        Context "Service exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent"

            It 'Removes service when Ensure = Absent' {
                Assert-MockCalled Invoke-TomcatServiceCommand -ParameterFilter {
                    $Option -eq "remove"
                }
            }
        }
        Context "Service doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Present"

            It 'Installs service when Ensure = Present' {
                Assert-MockCalled Invoke-TomcatServiceCommand -ParameterFilter {
                    $Option -eq "install"
                }
            }
        }
        Context "Service doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -CatalinaBase $test_catalinabase -CatalinaHome $test_catalinahome -JavaHome $test_javahome -Ensure "Absent"

            It 'Does nothing when Ensure = Absent' {
                Assert-MockCalled Invoke-TomcatServiceCommand -Exactly -Times 0
            }
        }
    }
}

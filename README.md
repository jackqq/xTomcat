# xTomcat

PowerShell DSC Module for installing and configuring Tomcat on Windows.

## xTomcatService

Installs Tomcat as a service by calling $CATALINA_HOME\bin\service.bat.

In addition, an inbound firewall rule and service-running state should be required before the server can fully function. Please use my [xSimpleFirewall](https://github.com/jackqq/xSimpleFirewall) or Microsoft's [xNetworking](https://github.com/PowerShell/xNetworking) for the firewall rule, and xService resource from [xPSDesiredStateConfiguration](https://github.com/PowerShell/xPSDesiredStateConfiguration) for the desired service state configuration.

### Sample

```powershell
$JavaVersion = "1.8.0_92"
$TomcatVersion = "8.0.33"

$JavaPackageVersion = "{0}u{1}" -f $JavaVersion.Substring(2, 1), $JavaVersion.Substring(6)

$JavaHome = "C:\jdk${JavaVersion}"
$CatalinaHome = "C:\apache-tomcat-${TomcatVersion}"
$CatalinaBase = "C:\apache-tomcat-${TomcatVersion}"

Configuration TomcatConfig {
    Import-DscResource -Module xTomcat

    Node TomcatServer {
        Archive ServerJRE {
            Destination = "C:\"
            Path = $InstallSource + "\server-jre-${JavaPackageVersion}-windows-x64.zip"
        }

        Archive Tomcat {
            Destination = "C:\"
            Path = $InstallSource + "\apache-tomcat-${TomcatVersion}-windows-x64.zip"
        }

        xTomcatService TomcatService {
            CatalinaBase = $CatalinaBase
            CatalinaHome = $CatalinaHome
            JavaHome = $JavaHome
            DependsOn = @(
                "[Archive]ServerJRE"
                "[Archive]Tomcat"
            )
        }

<# Additional config
        xFirewallTcpRule TomcatPort {
            Name = "Tomcat" + ($TomcatVersion -split '\.')[0]
            Port = 8080
        }

        xService TomcatService {
            Name = "Tomcat" + ($TomcatVersion -split '\.')[0]
            State = "Running"
            StartupTimeout = 10 * 1000
            DependsOn = @(
                "[xTomcatService]TomcatService"
                "[xFirewallTcpRule]TomcatPort"
            )
        }
#>
    }
}
```

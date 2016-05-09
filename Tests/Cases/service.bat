rem Set default Service name
set SERVICE_NAME=Tomcat12
set DISPLAYNAME=Apache Tomcat 12.0 %SERVICE_NAME%

:checkUser
if "x%1x" == "x/userx" goto runAsUser
if "x%1x" == "x--userx" goto runAsUser
set SERVICE_NAME=%1
set DISPLAYNAME=Apache Tomcat 12.0 %1
shift
if "x%1x" == "xx" goto checkServiceCmd
goto checkUser

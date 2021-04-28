@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

if not "%JAVA_HOME%" == "" goto PROCEED
echo JAVA_HOME is not set.  Please set the JAVA_HOME environment variable to a JDK %MINIMUM_JAVA_VERSION% or higher installation directory path.
exit /B 1

:PROCEED
set JAVA=%JAVA_HOME%\bin\java

set JAVA_VERSION=
"%JAVA_HOME%/bin/java" -version 2>java_version.txt
for /f "tokens=3" %%g in (java_version.txt) do (
	del java_version.txt
	set JAVA_VERSION=%%g
	goto CHECK_JAVA_VERSION 	
)

rem grab first 3 characters of version number (ex: 1.6) and compare against required version
:CHECK_JAVA_VERSION
set JAVA_VERSION8=%JAVA_VERSION:~1,3%
if %JAVA_VERSION8% == 1.8 (
    goto SET_CP
)
set JAVA_VERSION11=%JAVA_VERSION:~1,2%
if %JAVA_VERSION11% == 11 (
    goto SET_CP
)

:WRONG_JAVA_VERSION
echo JDK 8 or 11 is required to run PingFederate but %JAVA_VERSION% was detected. Please set the JAVA_HOME environment variable to a JDK 8 or 11 installation directory path.

:SET_CP
set DIRNAME=.
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0%
set DIRNAME=%DIRNAME%..

set CLASSPATH="%DIRNAME%\lib\*"

"%JAVA%" -Xms128m -Xmx128m -cp %CLASSPATH% -Dupgrade.home.dir="%DIRNAME%" -Dlog.dir="%DIRNAME%/log" -Dlog4j.configurationFile="file:///%DIRNAME%/bin/log4j2.xml" com.pingidentity.pingfederate.migration.UpgradeUtility %*

:END

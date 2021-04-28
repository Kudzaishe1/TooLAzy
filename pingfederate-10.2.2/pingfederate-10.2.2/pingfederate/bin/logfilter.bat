@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0

set PF_HOME=%DIRNAME%..
set SERVER_LIB=../server\default\lib

set CLASSPATH="../bin\pf-consoleutils.jar"


REM Read an optional running configuration file
@if ["%RUN_CONF%"] == [""] (
    set RUN_CONF=%DIRNAME%\conf.bat
)
@if exist "%RUN_CONF%" (
    call "%RUN_CONF%"
)

set CLASSPATH=%CLASSPATH%;%SERVER_LIB%\*

if not exist log mkdir log

if "%JAVA_HOME%" == "" (
	set JAVA=java
	echo JAVA_HOME is not set.  Unexpected results may occur.
	echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
) ELSE (
	set JAVA=%JAVA_HOME%\bin\java
)

"%JAVA%" -cp "%CLASSPATH%" -Dpingfederate.log.dir="%PF_HOME%/log" -Dlog4j.configurationFile="file://%PF_HOME%/bin/logfilter.log4j2.xml" com.pingidentity.console.logfilter.utility.LogFilterUtility %*

goto :eof
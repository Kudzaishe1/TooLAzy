@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

@if "%1" == "" goto SYNTAX
@if "%1" == "-?" goto SYNTAX
@if "%1" == "-help" goto SYNTAX

set CURRENTDIR=%cd%
set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0

cd "%DIRNAME%.."

set PF_HOME=%cd%
set PF_LIB=lib
set SERVER_LIB=server\default\lib
set SERVER_DEPLOY=server\default\deploy
set PF_BIN=bin


REM Read an optional running configuration file
@if ["%RUN_CONF%"] == [""] (
    set RUN_CONF=%DIRNAME%\conf.bat
)
@if exist "%RUN_CONF%" (
    call "%RUN_CONF%"
)

if not "%JAVA_HOME%" == "" goto ADD_TOOLS
set JAVA=java
echo JAVA_HOME is not set.  Unexpected results may occur.
echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
goto SET_CLASSPATH

:ADD_TOOLS

set JAVA=%JAVA_HOME%\bin\java

:SET_CLASSPATH

set CLASSPATH="%PF_HOME%\server\default\conf;%PF_HOME%\%PF_LIB%\*;%PF_HOME%\%SERVER_LIB%\*;%PF_HOME%\%SERVER_DEPLOY%\*;%PF_HOME%\%PF_BIN%\*"

if not exist log mkdir log

cd "%CURRENTDIR%"

"%JAVA%" -cp %CLASSPATH% %* -Dpf.home="%PF_HOME%" -Dpf.server.default.dir="%PF_HOME%\server\default" -Dlog4j.configurationFile="file://%PF_HOME%/bin/configcopy.log4j2.xml" -Dorg.apache.axis.components.net.SecureSocketFactory=org.sourceid.common.soap.soap11.JSSESocketFactory com.pingidentity.console.ConfigCopy

goto :WARNING

:SYNTAX

@echo USAGE:
@echo        configcopy -Dconfigcopy.conf.file=^<properties_file1^>;^<properties_file2^>;...
@echo. 
@echo Refer to the README.txt file in the bin\configcopy_templates
@echo directory for a list of all commands and summary information. See the
@echo template files themselves for parameters associated with each
@echo command (or with use cases), as well as lists of Override Properties
@echo (configuration settings that can be modified in transit), where
@echo applicable.

goto :WARNING

:WARNING

@echo.
@echo WARNING: This tool has been deprecated.

goto :eof
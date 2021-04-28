@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0

set PF_HOME=%DIRNAME%..
cd %PF_HOME%

set LIB=lib
set PF_BIN=bin

set SERVER=server\default
set SERVER_LIB=%SERVER%\lib
set SERVER_DEPLOY=%SERVER%\deploy

set PF_ENDORSED_DIRS=%LIB%\endorsed

set CLASSPATH="%SERVER%\conf";"%SERVER%\data\config-store"

REM Read an optional running configuration file
@if ["%RUN_CONF%"] == [""] (
    set RUN_CONF=%DIRNAME%\conf.bat
)
@if exist "%RUN_CONF%" (
    call "%RUN_CONF%"
)

set CLASSPATH=%CLASSPATH%;%LIB%\*;%SERVER_LIB%\*;%SERVER_DEPLOY%\*

if not exist log mkdir log

if "%JAVA_HOME%" == "" (
	set JAVA=java
	echo JAVA_HOME is not set.  Unexpected results may occur.
	echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
) ELSE (
	set JAVA=%JAVA_HOME%\bin\java
)

set JAVA_VERSION=
"%JAVA%" -version 2>java_version.txt
for /f "tokens=3" %%g in (java_version.txt) do (
	del java_version.txt
	set JAVA_VERSION=%%g
	goto CHECK_JAVA_VERSION
)

:CHECK_JAVA_VERSION
set JAVA_VERSION11=%JAVA_VERSION:~1,2%

set PF_ENDORSED_DIRS_FLAG="-Djava.endorsed.dirs=%PF_ENDORSED_DIRS%"

if %JAVA_VERSION11% == 11 (
	set "PF_ENDORSED_DIRS_FLAG="
)

set RUN_PROPERTIES=""
if exist "%PF_BIN%\run.properties" (
	set RUN_PROPERTIES=%PF_BIN%\run.properties
) ELSE (
	echo Missing %PF_HOME%\bin\run.properties; using defaults.
)

"%JAVA%" -cp "%CLASSPATH%" %PF_ENDORSED_DIRS_FLAG% -Dpf.home="%PF_HOME%" -Dpf.server.default.dir="%SERVER%" -Dlog4j.configurationFile="file://%PF_HOME%/bin/provmgr.log4j2.xml" -Drun.properties="%RUN_PROPERTIES%" com.pingidentity.provisioner.cli.CommandLineTool %*

goto :eof
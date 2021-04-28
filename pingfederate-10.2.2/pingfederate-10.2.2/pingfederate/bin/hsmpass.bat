@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0

set ROOT=%DIRNAME%..
set ROOT_LIB=%DIRNAME%\lib
set SERVER_LIB=%ROOT%\server\default\lib


REM Read an optional running configuration file
@if ["%RUN_CONF%"] == [""] (
    set RUN_CONF=%DIRNAME%\conf.bat
)
@if exist "%RUN_CONF%" (
    call "%RUN_CONF%"
)


set PASSWORD_FILE=%ROOT%\server\default\data\hsmpasswd.txt

set CLASSPATH=%ROOT_LIB%\*;%DIRNAME%\*;%SERVER_LIB%\*

if "%JAVA_HOME%" == "" (
	set JAVA=java
	echo JAVA_HOME is not set.  Unexpected results may occur.
	echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
) ELSE (
	set JAVA=%JAVA_HOME%\bin\java
)

"%JAVA%" -classpath "%CLASSPATH%" -Dpassword.file="%PASSWORD_FILE%" com.pingidentity.console.PasswordChanger HSM %*


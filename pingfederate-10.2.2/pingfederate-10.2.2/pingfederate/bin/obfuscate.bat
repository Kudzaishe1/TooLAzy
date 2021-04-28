@echo off

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT"  setlocal

set /a argCount = 0
for %%a in (%*) do set /a argCount +=1

@if %argCount% EQU 1 (
   if "%~1" == "-l" (
      echo obfuscate.bat -l: missing password
      echo Try 'obfuscate.bat --help' for more information.
      exit /b
   )
)

@if "%~1"=="--help" (
  echo Usage: obfuscate.bat [-l password] [password]
  echo Prompts for a password, obfuscates it, then prints the result.
  echo To avoid prompting, a PASSWORD argument may be specified. However, this is generally less secure.
  echo If PASSWORD contains special characters, it should be enclosed in double quotes.
  echo.
  echo   -l, Obfuscate using the legacy AES algorithm.
  exit /b
)

@if %argCount% GEQ 3 (
   echo Validation Error: Invalid Arguments.
   echo Try 'obfuscate.bat --help' for more information.
   exit /b
)

@if %argCount% EQU 2 (
   if not "%~1" == "-l" (
      echo Validation Error: Invalid Arguments.
      echo Try 'obfuscate.bat --help' for more information.
      exit /b
   )
)

set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0
set DIRNAME=%DIRNAME%..

set DEFAULT_DIR=%DIRNAME%\server\default

set CLASSPATH=%DEFAULT_DIR%\lib\*;.
set CLASSPATH=%CLASSPATH%;%DEFAULT_DIR%\deploy\*
set CLASSPATH=%CLASSPATH%;%DEFAULT_DIR%\conf\"

REM Read an optional running configuration file
@if ["%RUN_CONF%"] == [""] (
    set RUN_CONF=%DIRNAME%\bin\conf.bat
)
@if exist "%RUN_CONF%" (
    call "%RUN_CONF%"
)

@if ["%JAVA_HOME%"] == [""] (
    set JAVA=java
    echo JAVA_HOME is not set.  Unexpected results may occur.
    echo Set JAVA_HOME to the directory of your local JDK to avoid this message.
) ELSE (
    set JAVA=%JAVA_HOME%\bin\java
)

REM If password contains special characters (e.g. '&'), an extra pair of quotes is required.
@if "%~2" == "" (
    set ARGS=^"%1^"
) ELSE (
    set ARGS=%1 ^"%2^"
)

"%JAVA%" -Dlog4j.configurationFile="file:///%DIRNAME%\bin\obfuscate.log4j2.xml" -Dpf.server.default.dir="%DEFAULT_DIR%" -cp "%CLASSPATH%" com.pingidentity.crypto.PasswordEncoder %ARGS%

:END

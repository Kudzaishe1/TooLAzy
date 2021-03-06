@echo off
setlocal enabledelayedexpansion

if not "%OS%" == "Windows_NT" (
  echo Unsupported operating system
  EXIT /B 1
)

if "%PF_HOME%" == "" (
  set "pfBin=%~dp0"
  set "PF_HOME=!pfBin!.."
)

set "runProperties=%PF_HOME%\bin\run.properties"
if not exist "%runProperties%" (
   echo %runProperties% does not exist
   EXIT /B 1
)

REM Determine runtime mode from run.properties
set "pfRuntimeMode="
for /f "usebackq tokens=* eol=!" %%p in ("%runProperties%") do (
	set "line=%%p"
	set "firstChar=!line:~0,1!
	REM skip any # comment lines
	if not "!firstChar!" == "#" (
	  REM remove spaces
	  set "line=!line: =!"
	  REM remove tabs
	  set "line=!line:	=!"
	  REM get first 20 characters, might be "pf.operational.mode="
	  set "maybeModeKey=!line:~0,20!
	  if "!maybeModeKey!" == "pf.operational.mode=" (
	    REM get 25 characters for property value
	    set "pfRuntimeMode=!line:~20,25!"
	    goto :pfRuntimeFound
	  )
    )
)
:pfRuntimeFound

REM set memory and CPU info
for /f "delims== tokens=2" %%c in ('wmic cpu get NumberOfLogicalProcessors /value') do (
  if !errorlevel! NEQ 0 GOTO :ERROR
  set cpuCount=%%c
)
for /f "delims== tokens=2" %%m in ('wmic os get FreePhysicalMemory /value') do (
  if !errorlevel! NEQ 0 GOTO :ERROR
  set availableMem=%%m
)

set "lessthansixcpu=false"
if %availableMem% LSS 6291456 set "lessthansixcpu=true"
if %cpuCount% LSS 6 set "lessthansixcpu=true"

set "maxsetting=false"
if %availableMem% GEQ 6291456 ( if %cpuCount% GEQ 6 set "maxsetting=true" )

REM Heap size should be at most 80% of available memory, in logical steps
REM If system has 6 or more CPU cores, max heap is 6GB, otherwise 2GB
if %availableMem% LSS 819200 (
  REM 0 - 800 MB
  set heap=512
  set newSize=256
) else if %availableMem% LSS 983040 (
  REM 800 - 960 MB
  set heap=640
  set newSize=320
) else if %availableMem% LSS 1146880 (
  REM 960 - 1120 MB
  set heap=768
  set newSize=384
) else if %availableMem% LSS 1310720 (
  REM 1120 - 1280 MB
  set heap=896
  set newSize=448
) else if %availableMem% LSS 1638400 (
  REM 1280 - 1920 MB
  set heap=1024
  set newSize=512
) else if "%pfRuntimeMode%" == "CLUSTERED_CONSOLE" (
  REM Max size for CLUSTERED_CONSOLE mode
  set heap=1024
  set newSize=512
) else if %availableMem% LSS 1966080 (
  REM 1600 - 1920 MB
  set heap=1280
  set newSize=640
) else if %availableMem% LSS 2621440 (
  REM 1920 - 2560 MB
  set heap=1536
  set newSize=768
) else if %cpuCount% LSS 4 (
  REM Max size for less than 4 CPUs
  set heap=2048
  set newSize=1024
) else if %availableMem% LSS 3276800 (
  REM 2560 - 3200 MB
  set heap=2048
  set newSize=1024
) else if %availableMem% LSS 3932160 (
  REM 3200 - 3840 MB
  set heap=2560
  set newSize=1280
) else if %availableMem% LSS 4587520 (
  REM 3840 - 4480 MB
  set heap=3072
  set newSize=1536
) else if %availableMem% LSS 5242880 (
  REM 4480 - 5120 MB
  set heap=3584
  set newSize=1792
) else if "!lessthansixcpu!" == "true" (
  REM 5120+ MB
  set heap=4096
  set newSize=2048
) else if "!maxsetting!" == "true" (
  REM 6144+ MB
  set heap=6144
  set newSize=3072
)

REM get the current time
for /f %%a in ('wmic os get LocalDateTime ^| findstr ^[0-9]') do (
   if !errorlevel! NEQ 0 GOTO :ERROR
   set ts=%%a
)
set Y=%ts:~0,4%
set M=%ts:~4,2%
set D=%ts:~6,2%
set H=%ts:~8,2%
set MN=%ts:~10,2%
set S=%ts:~12,2%
set MIL=%ts:~15,3%
set backupDateTime=%Y%-%M%-%D%_%H%-%MN%-%S%-%MIL%
set "generatedTime=%Y%/%M%/%D% %H%:%MN%:%S%:%MIL%"


REM ********* File Template *********
REM Each line must end with a "^" and be separated by a space
set file=^
# Auto-generated JVM memory options for PingFederate^

#^

# Generated: !generatedTime!^

#^

# Each non-commented and non-empty line will be added as a Java option when PingFederate is started.^

# Comments can be added to this file by starting a line with the # character.^

#^

^

#Minimum heap size^

-Xms!heap!m^

#Maximum heap size^

-Xmx!heap!m^

#Minimum size for the Young Gen space^

-XX:NewSize=!newSize!m^

#Maximum size for the Young Gen space^

-XX:MaxNewSize=!newSize!m^

#Use the parallel garbage collector^

-XX:+UseParallelGC
REM ******* End File Template *******


if %cpuCount% GEQ 2 (
  REM ********* File Template *********
  REM line spacing is important
  set foo=^

#Use parallel garbage collection for full collections^

-XX:-UseParallelOldGC
  REM ******* End File Template *******
  set file=!file!!foo!
)

set "jvmMemoryOpts=%PF_HOME%\bin\jvm-memory.options"
if exist "%jvmMemoryOpts%" (
  REM Make a backup before generating a new file
  copy "%jvmMemoryOpts%" "%PF_HOME%\bin\jvm-memory_%backupDateTime%.options" || GOTO :ERROR
)

echo !file! > "%jvmMemoryOpts%" || GOTO :ERROR
echo.
echo Generated new jvm-memory.options.
EXIT /B 

:ERROR
echo Unable to generate jvm-memory.options. An error occurred.
EXIT /B 1
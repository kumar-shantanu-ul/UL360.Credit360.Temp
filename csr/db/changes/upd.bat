@echo off
setlocal enabledelayedexpansion

set dbname=%1
if "%dbname%" == "" set dbname=aspen

rem I can't seem to inline the pipe in the for loop.  Gragh (quoting it causes the command to be ignored; not quoting it causes an error).
rem for /f "tokens=*" %%i in ('^(echo set head off^& echo select db_version from csr.version;^) ^| sqlplus -L -S upd/upd@%dbname%') do (
set verpath=%~dp0%
set verpath=%verpath:~0,-1%\version
for /f "tokens=*" %%i in ('"%verpath%" %dbname%') do (
	set version=%%i
)
if "%version%" == "" echo Database version not found && exit /b
echo %dbname%: current DB version %version%
set /a version=!version!+1
if not exist latest%version%.sql echo Database is up to date && exit /b

for /l %%i in (%version%,1,99999) do (
	if not exist latest%%i.sql goto :done
	echo %dbname%: applying latest%%i.sql
	sqlplus upd/upd@%dbname% @latest%%i.sql 1 1
	if !errorlevel! neq 0 exit /b !errorlevel!
)

:done
sqlplus upd/upd@%dbname% @upd_batch_end
exit /b 0

@echo off
setlocal 
if "%~1"=="" goto :syntax
if "%~2"=="" goto :syntax
set site=%~1
set db=%~2
for /f "tokens=1,2,3 delims=/" %%a in ("%date%") do set ts=%%c-%%b-%%a
set csv=LogOnMethodReport_%ts%.csv
sqlplus csr/csr@%db% @LogOnMethodReport.sql "%site%" "%csv%"
echo.
echo Report written to "%csv%".
goto :eof
:syntax
echo Generate a report of when users last logged on directly and when they last logged on via SSO.
echo %0 ^<site^> ^<tnsname^>
echo.
echo e.g. %0 heineken.credit360.com live
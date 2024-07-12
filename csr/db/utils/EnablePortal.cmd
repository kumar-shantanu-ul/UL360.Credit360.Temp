@echo off
setlocal
if [%1]==[] goto :syntax
set site=%1
set db=%2
if [%db%]==[] set db=aspen
echo exit | sqlplus -S -L csr/csr@%db% @EnablePortal %site%
goto :eof
:syntax
echo Enable the portal on the provided CSR application.
echo.
echo Syntax:
echo.
echo   %0 ^<site^> [^<db^>]
echo.
echo DB defaults to ASPEN in your tnsnames.ora.
echo.
echo e.g. %0 m.credit360.com
echo      %0 maersk.credit360.com live

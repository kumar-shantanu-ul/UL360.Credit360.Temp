@echo off
setlocal
if [%1]==[] goto :syntax
set site=%1
set db=%2
if [%db%]==[] set db=aspen
echo exit | sqlplus -S -L csr/csr@%db% @EnableSSO %site%
goto :eof
:syntax
echo Enable single sign on [SSO].
echo.
echo Syntax:
echo.
echo   %0 ^<site^> [^<db^>]
echo.
echo DB defaults to ASPEN in your tnsnames.ora.
echo.
echo e.g. %0 example.credit360.com

@echo off
setlocal
set db=%1
if "%db%"=="" goto error
set host=%2
if "%host%"=="" goto error

sqlplus -L -S csr/csr@%db% @checkMetering %host%
if errorlevel 255 echo exit | sqlplus -L -S csr/csr@%db% @../enableMetering %host%

sqlplus -L -S csr/csr@%db% @checkIssues %host%
if errorlevel 255 echo exit | sqlplus -L -S csr/csr@%db% @../enableIssues2 %host%

sqlplus -L -S csr/csr@%db% @checkRealTimeMetering %host%
if errorlevel 255 echo exit | sqlplus -L -S csr/csr@%db% @../enableRealTimeMetering %host%

echo exit | sqlplus -L -S csr/csr@%db% @salesEnergyMonitoringMenus %host%

goto end
:error
echo "USAGE: setup <connection> <host>"
:end

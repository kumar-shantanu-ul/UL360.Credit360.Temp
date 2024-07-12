@echo off
setlocal
set db=%1
if "%db%"=="" set db=aspen
echo exit | sqlplus -L -S actions/actions@%db% @build.sql
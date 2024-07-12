@echo off
setlocal
set db=%1
if "%db%"=="" set db=aspen
echo exit | sqlplus -L -S chain/chain@%db% @build.sql
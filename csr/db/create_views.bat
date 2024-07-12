@echo off
setlocal
set db=%1
if "%db%"=="" set db=aspen
echo exit | sqlplus -L -S csr/csr@%db% @create_views.sql

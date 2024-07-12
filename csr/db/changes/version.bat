@echo off
set dbname=%1
if "%dbname%" == "" set dbname=aspen
set schema=%2
if "%schema%" == "" set schema=csr
@(echo set timing off& echo set head off& echo select db_version from %schema%.version;) |  sqlplus -L -S upd/upd@%dbname%

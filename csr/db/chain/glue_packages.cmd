@echo off
setlocal
if "%1"=="" goto err
if exist "%1.sql" del /f "%1.sql">nul
for %%i in (*_pkg.sql) do cat %%i >> %1.sql && echo.>>%1.sql
for %%i in (*_body.sql) do cat %%i >> %1.sql && echo.>>%1.sql
goto end
:err
echo Syntax: glue_packages output-name
echo Glues all packages together into a single SQL file.
echo Appends a ".SQL" extension unconditionally.
:end

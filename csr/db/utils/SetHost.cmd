@echo off
setlocal
set host=
set sql=
if /i "%computername%"=="lychee" goto :lychee
goto :done

:lychee
if /i "%1-%2"=="bat-dev" set host=batdev.credit360.com&& goto :done
if /i "%1-%2"=="britishland-dev" set host=britishlanddev.credit360.com&& goto :done
if /i "%1-%2"=="maersk-dev" set host=m.credit360.com&& goto :done
if /i "%1-%2"=="rfa-dev" set host=ra.credit360.com&& goto :done
if /i "%2"=="live" goto :live
goto :done

:live
if /i "%1"=="bat" set host=bat.credit360.com&& goto :done
if /i "%1"=="britishland" set host=britishland.credit360.com&& goto :done
if /i "%1"=="maersk" set host=maersk.credit360.com&& goto :done
if /i "%1"=="rfa" set host=rainforestalliance.credit360.com&& goto :done

:done
if not "%host%"=="" set sql=define host=%host%
echo.%sql%> SetHost.sql
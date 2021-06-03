@echo off
echo "<<< Vortex OpenSplice >>>"
set OSPL_HOME=%~dp0
if "%OSPL_URI%"=="" set OSPL_URI=file://%OSPL_HOME%\ospl.xml
@echo off
cd /d "%~dp0"
dart run ./lib/build.dart %*
pause
@echo off
setlocal

set "port=8383"
if not "%~1"=="" set "port=%~1"
cd /d "%~dp0"
echo Open: http://localhost:%port%/index.html
ldc2 -i -I=server -run server/app.d --listen "localhost:%port%"

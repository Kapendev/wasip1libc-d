@echo off
cd /d "%~dp0"
ldc2 -i -I=server -run server/app.d --listen %1

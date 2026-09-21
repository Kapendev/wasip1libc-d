@echo off
setlocal
cd /d "%~dp0"

set "betterC=F"
if "%~1"=="-betterC" set "betterC=T"

if "%betterC%"=="T" (
    ldc2 --mtriple=wasm32-wasip1 -betterC -i -c wasip1libc.d
    ldc2 --mtriple=wasm32-wasip1 -betterC -i -link-internally index.d wasip1libc.o
) else (
    ldc2 --mtriple=wasm32-wasip1 -c wasip1libc.d
    ldc2 --mtriple=wasm32-wasip1 -link-internally index.d wasip1libc.o
)

del /q *.o 2>nul

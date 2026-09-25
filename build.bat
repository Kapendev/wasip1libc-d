@echo off
setlocal

set betterc=F
set libc=F


cd /d "%~dp0"
for %%A in (%*) do (
  if /I "%%A"=="-betterc" set betterc=T
  if /I "%%A"=="-libc" set libc=T
  if /I not "%%A"=="-betterc" if /I not "%%A"=="-libc" (
    echo # --- Available Flags
    echo betterc=F
    echo libc=F
    exit /b 1
  )
)

set "dflags=-i --d-version=WASI_EMULATED_MMAN"
if "%betterc%"=="T" set dflags=%dflags% -betterC

if "%libc%"=="T" (
  ldc2 --mtriple=wasm32-wasip1 %dflags% index.d
) else (
  ldc2 --mtriple=wasm32-wasip1 %dflags% -c wasip1libc.d
  ldc2 --mtriple=wasm32-wasip1 %dflags% -link-internally index.d wasip1libc.o
)

del /q *.o 2>nul

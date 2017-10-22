@rem Script to build for Windows using Visual Studio.

@echo OFF
@setlocal enabledelayedexpansion

if not defined TOOLCHAIN (
  echo Using latest Visual Studio install... 1>&2
  call %~dp0\scripts\vc.bat latest windows x86_64
) else (
  call %~dp0\scripts\vc.bat %TOOLCHAIN% windows x86_64
)

if not "%ERRORLEVEL%"=="0" (
  echo Could not setup environment to compile for Windows.
  exit /B 1
)

set LJDLLNAME=luajit_release_windows_64.dll
set LJLIBNAME=luajit_release_windows_64.lib
set LJPDBNAME=luajit_release_windows_64.pdb
set LJEXENAME=luajit_release_windows_64.exe

pushd %~dp0\..\src
call msvcbuild.bat debug amalg
popd

if not %ERRORLEVEL%==0 (
  exit /B %ERRORLEVEL%
)

echo Moving build artifacts to align with our expectations...

mkdir _build 2>NUL
mkdir _build\obj 2>NUL
mkdir _build\bin 2>NUL
mkdir _build\lib 2>NUL

move /Y src\%LJDLLNAME% _build\bin\%LJDLLNAME% 1>NUL 2>&1
move /Y src\%LJLIBNAME% _build\lib\%LJLIBNAME% 1>NUL 2>&1
move /Y src\%LJPDBNAME% _build\bin\%LJPDBNAME% 1>NUL 2>&1
move /Y src\luajit.exe _build\bin\%LJEXENAME% 1>NUL 2>&1

echo Removing intermediates...

del src\lj_bcdef.h 1>NUL 2>&1
del src\host\buildvm_arch.h 1>NUL 2>&1
del /S src\*.o 1>NUL 2>&1
del /S src\*.obj 1>NUL 2>&1
del /S src\*.ilk 1>NUL 2>&1
del /S src\*.pdb 1>NUL 2>&1
del /S src\*.exe 1>NUL 2>&1
del /S src\*.lib 1>NUL 2>&1
del /S src\*.dll 1>NUL 2>&1
del /S src\*.exp 1>NUL 2>&1

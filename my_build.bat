@echo off
REM Purpose: Launch build and tests under Windows (MSVC)
setlocal EnableDelayedExpansion
set nopause=0
set fresh=0
set debug=0
set test=0
:loop
if "%1" == "--nopause" ( set nopause=1 && shift && goto loop )
if "%1" == "--fresh" ( set fresh=1 && shift && goto loop )
if "%1" == "--debug" ( set debug=1 && shift && goto loop )
if "%1" == "--test" ( set test=1 && shift && goto loop )
if not "%1" == "" ( echo Unknown option "%1" && exit /B 1 )

if not defined VisualStudioVersion (
    title Compiling using MSVC - Initializing environment
    for /F "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -property installationPath -latest`) do call "%%i\VC\Auxiliary\Build\vcvars64.bat"
    if !errorlevel! NEQ 0 (
        echo No MS Visual C++ installation found!
        if %nopause% EQU 0 pause
        exit /B %!errorlevel!
    )
)

set BUILD_DIR=build\VS%VisualStudioVersion%

if not exist %BUILD_DIR%\ set fresh=1
if %fresh% EQU 1 (
    title Compiling using MSVC - preparing build directory
    cmake -S . -B %BUILD_DIR%
    if !errorlevel! NEQ 0 goto end
)
 
REM Choose Debug / Release / MinSizeRel / RelWithDebInfo
if %debug% EQU 1 ( set CONFIG=Debug) else ( set CONFIG=Release)
title Compiling using MSVC - Building in %CONFIG% mode
cmake --build %BUILD_DIR% --config %CONFIG% --parallel -- /p:CL_MPcount=%NUMBER_OF_PROCESSORS%
if !errorlevel! NEQ 0 goto end

if %test% EQU 1 (
    title Running tests
    set ts=%DATE%_%TIME%
    set xml=Testing\junit_output_%CONFIG%_!ts:~6,4!-!ts:~3,2!-!ts:~0,2!_!ts:~11,2!-!ts:~14,2!-!ts:~17,2!.xml
    ctest --test-dir %BUILD_DIR% -C %CONFIG% -j %NUMBER_OF_PROCESSORS% --output-junit !xml! --test-output-size-passed 1048576 --output-on-failure --test-output-size-failed 1048576 --timeout 5
    echo ctest status = !errorlevel! ; Wrote test output to !xml!
)

:end
if %nopause% EQU 0 pause

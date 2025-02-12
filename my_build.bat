@echo off
REM Purpose: Launch build and tests under Windows (MSVC)
setlocal EnableDelayedExpansion
set nopause=0
set fresh=0
set configlist=Release
set test=0
set ninja=0
:loop
if "%1" == "--nopause" ( set nopause=1 && shift && goto loop )
if "%1" == "--fresh" ( set fresh=1 && shift && goto loop )
if "%1" == "--debug" ( set configlist=Debug && shift && goto loop )
REM Choose config from: Debug / Release / MinSizeRel / RelWithDebInfo
if "%1" == "--all" ( set configlist=Release,Debug && shift && goto loop )
if "%1" == "--test" ( set test=1 && shift && goto loop )
if "%1" == "--ninja" ( set ninja=1 && shift && goto loop )
if not "%1" == "" ( echo Unknown option "%1" && exit /B 1 )

if not defined VisualStudioVersion (
    title Compiling using MSVC - Initializing environment
    set requested_version=-latest
    REM Uncomment one of the following lines to use an older Visual Studio version among multiple installed ones (respectively: 2017, 2019, 2022):
    REM set requested_version=-version [15,16)
    set requested_version=-version [16,17)
    REM set requested_version=-version [17,18)
    REM For details, see https://github.com/microsoft/vswhere/wiki/Versions
    for /F "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -property installationPath !requested_version!`) do call "%%i\VC\Auxiliary\Build\vcvars64.bat"
    if not defined VisualStudioVersion set errorlevel=255
    if !errorlevel! NEQ 0 (
        echo No MS Visual C++ installation found!
        if %nopause% EQU 0 pause
        exit /B %!errorlevel!
    )
)

if %ninja% EQU 1 (
    set build_dir=build\VS%VisualStudioVersion%_ninja
    set cmake_generator=-G "Ninja Multi-Config"
) else (
    set build_dir=build\VS%VisualStudioVersion%
    set cmake_build_extra=-- /p:CL_MPcount=%NUMBER_OF_PROCESSORS%
)
if not exist %build_dir%\CMakeFiles\ set fresh=1
if %fresh% EQU 1 (
    title Compiling using MSVC - preparing build directory
    cmake -S . -B %build_dir% %cmake_generator%
    if !errorlevel! NEQ 0 goto end
)
 
for %%c in (%configlist%) do (
    title Compiling using MSVC - Building in config %%c
    cmake --build %build_dir% --config %%c --parallel %cmake_build_extra%
    if !errorlevel! NEQ 0 goto end
    if %test% EQU 1 (
        title Running tests in config %%c
        set ts=!DATE: =0!_!TIME: =0!
        set xml=Testing\junit_output_%%c_!ts:~6,4!-!ts:~3,2!-!ts:~0,2!_!ts:~11,2!-!ts:~14,2!-!ts:~17,2!.xml
        ctest --test-dir %build_dir% -C %%c -j %NUMBER_OF_PROCESSORS% --output-junit !xml! --test-output-size-passed 1048576 --output-on-failure --test-output-size-failed 1048576 --timeout 5
        echo ctest status = !errorlevel! ; Wrote test output to !xml!
    )
)
:end
title Command Prompt
if %nopause% EQU 0 pause

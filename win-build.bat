@echo off

rem Build script for Windows or Wine. We prefer LDC here because LDC builds
rem the fastest-running Lix binaries, but you can use any D compiler.

echo Looking for an installed LDC ...
where.exe ldc2
if %errorlevel%==0 (
    echo Building Lix with LDC ...
    dub build --build=release --arch=x86_64 --compiler=ldc2
) else (
    echo Building Lix with any one compiler ...
    dub build --build=release --arch=x86_64
)

if %errorlevel%==0 (
    echo Look in the folder "bin" for the Lix executable.
)

pause

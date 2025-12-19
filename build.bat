@echo off
cd /d "%~dp0"

echo ========================================
echo Building Context Menu Tool (Windows 11)
echo ========================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Administrator privileges required!
    echo Please right-click this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Step 1: Cleaning old build artifacts...
echo.

REM Remove dist directory
if exist "dist" (
    echo   Removing dist\
    rmdir /s /q "dist"
)

REM Remove target directories
if exist "com_handler\target" (
    echo   Removing com_handler\target\
    rmdir /s /q "com_handler\target"
)

REM Remove temporary files in sparse_package
if exist "sparse_package\contextmenu.exe" (
    del /q "sparse_package\contextmenu.exe" 2>nul
)

if exist "sparse_package\ContextMenuHandler.dll" (
    del /q "sparse_package\ContextMenuHandler.dll" 2>nul
)

echo   [OK] Cleanup complete
echo.

echo Step 2: Checking certificate...
echo.

if exist "ContextMenuDev.pfx" (
    echo   [OK] Certificate already exists
) else (
    echo   Certificate not found, creating...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0create_cert.ps1"

    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo   [FAILED] Certificate creation failed
        pause
        exit /b 1
    )
)
echo.

echo Step 3: Finding MSBuild...
echo.

REM Find MSBuild using vswhere first
set "MSBUILD="

REM Try to use vswhere.exe (recommended method)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
        set "MSBUILD=%%i"
        goto :found_msbuild
    )
)

REM Fallback: Search common paths
echo Searching for MSBuild in common paths...
for %%y in (2024 2022 2019 2017) do (
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\MSBuild\Current\Bin\MSBuild.exe" (
            set "MSBUILD=C:\Program Files\Microsoft Visual Studio\%%y\%%e\MSBuild\Current\Bin\MSBuild.exe"
            goto :found_msbuild
        )
    )
)

REM Try Program Files (x86) as well
for %%y in (2024 2022 2019 2017) do (
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\MSBuild\Current\Bin\MSBuild.exe" (
            set "MSBUILD=C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\MSBuild\Current\Bin\MSBuild.exe"
            goto :found_msbuild
        )
    )
)

echo.
echo ERROR: MSBuild not found!
echo.
echo Please install Visual Studio 2017 or later with:
echo - Desktop development with C++ workload
echo - Or install Build Tools for Visual Studio
echo.
echo Download from: https://visualstudio.microsoft.com/downloads/
echo.
pause
exit /b 1

:found_msbuild
echo Found MSBuild: %MSBUILD%
echo.

REM Check if ATL is available
echo Checking for ATL (Active Template Library)...
set "ATL_FOUND=0"

REM Try to find atlbase.h by checking actual MSVC version directories
for %%y in (2024 2022 2019 2017) do (
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" (
            for /f "delims=" %%v in ('dir /b /ad "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" 2^>nul') do (
                if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC\%%v\atlmfc\include\atlbase.h" (
                    set "ATL_FOUND=1"
                    echo   [OK] ATL found in: %%y\%%e\VC\Tools\MSVC\%%v
                    goto :atl_check_done
                )
            )
        )
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" (
            for /f "delims=" %%v in ('dir /b /ad "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" 2^>nul') do (
                if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC\%%v\atlmfc\include\atlbase.h" (
                    set "ATL_FOUND=1"
                    echo   [OK] ATL found in: %%y\%%e\VC\Tools\MSVC\%%v
                    goto :atl_check_done
                )
            )
        )
    )
)

:atl_check_done
if "%ATL_FOUND%"=="0" (
    echo.
    echo ========================================
    echo ERROR: ATL not found!
    echo ========================================
    echo.
    echo ATL ^(Active Template Library^) is required to build COM components.
    echo.
    echo To install ATL:
    echo 1. Open Visual Studio Installer
    echo 2. Click "Modify" on your Visual Studio installation
    echo 3. Go to "Individual components" tab
    echo 4. Search for "ATL"
    echo 5. Check these components:
    echo    - C++ ATL for latest v143 build tools ^(x64/x86^)
    echo    - C++ ATL for latest v143 build tools with Spectre Mitigations ^(x64/x86^)
    echo 6. Click "Modify" to install
    echo.
    echo After installation, run this script again.
    echo.
    pause
    exit /b 1
)
echo.

REM Detect platform toolset version based on MSVC version
echo Detecting platform toolset version...
set "TOOLSET="
set "MSVC_PATH="

REM Find the actual MSVC installation path
for %%y in (2024 2022 2019 2017) do (
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" (
            set "MSVC_PATH=C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC"
            goto :check_msvc_version
        )
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC" (
            set "MSVC_PATH=C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Tools\MSVC"
            goto :check_msvc_version
        )
    )
)

:check_msvc_version
if "%MSVC_PATH%"=="" (
    echo   WARNING: Could not find MSVC installation
    set "TOOLSET=v143"
    goto :toolset_found
)

REM Get the first (usually latest) MSVC version directory
for /f "delims=" %%d in ('dir /b /ad /o-n "%MSVC_PATH%" 2^>nul') do (
    set "MSVC_VERSION=%%d"
    goto :determine_toolset
)

:determine_toolset
echo   Found MSVC version: %MSVC_VERSION%

REM Determine toolset based on MSVC version number
if "%MSVC_VERSION:~0,4%"=="14.3" (
    set "TOOLSET=v143"
    echo   Using v143 toolset ^(Visual Studio 2022^)
) else if "%MSVC_VERSION:~0,4%"=="14.2" (
    set "TOOLSET=v142"
    echo   Using v142 toolset ^(Visual Studio 2019^)
) else if "%MSVC_VERSION:~0,4%"=="14.1" (
    set "TOOLSET=v141"
    echo   Using v141 toolset ^(Visual Studio 2017^)
) else if "%MSVC_VERSION:~0,4%"=="14.0" (
    set "TOOLSET=v140"
    echo   Using v140 toolset ^(Visual Studio 2015^)
) else (
    echo   WARNING: Unknown MSVC version, using v143
    set "TOOLSET=v143"
)

:toolset_found
echo.

echo Step 4: Building COM DLL...
echo.

"%MSBUILD%" com_handler\ContextMenuHandler.vcxproj /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=%TOOLSET%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo C++ DLL build failed!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo Step 5: Building stub application...
echo.

"%MSBUILD%" com_handler\StubApp.vcxproj /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=%TOOLSET%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo Stub app build failed!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.

echo Step 6: Running PowerShell packaging script...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0create_package.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo Packaging failed!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo All steps completed successfully!
echo ========================================
echo.
pause

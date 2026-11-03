@echo off
setlocal enabledelayedexpansion

title OneSpend by AR1 — Production Release Builder
color 0A

echo ===============================================================================
echo                      [ 1S ] ONESPEND BY AR1
echo            Modern Offline Expense Tracker by AR1studios
echo                  Production Release Automation Pipeline
echo ===============================================================================
echo.

:: 1. Check for Flutter in PATH
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter SDK executable was not found on your system PATH!
    echo.
    echo Please make sure Flutter is installed and its 'bin' directory is added to
    echo your Windows Environment Variables under 'Path'.
    echo Example: C:\src\flutter\bin
    echo.
    pause
    exit /b 1
)

echo [✓] Flutter CLI detected.
for /f "tokens=*" %%v in ('flutter --version 2^>nul') do (
    echo [i] %%v
    goto :version_done
)
:version_done
echo.

:: 2. Clean Project
echo -------------------------------------------------------------------------------
echo [1/4] Cleaning build artifacts and temporary cache...
echo -------------------------------------------------------------------------------
call flutter clean
if %ERRORLEVEL% neq 0 (
    echo [!] 'flutter clean' failed. Continuing anyway...
)
echo.

:: 3. Fetch Dependencies
echo -------------------------------------------------------------------------------
echo [2/4] Resolving and fetching project dependencies...
echo -------------------------------------------------------------------------------
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'flutter pub get' failed! Check your internet connection or pubspec.yaml.
    pause
    exit /b %ERRORLEVEL%
)
echo.

:: 4. Build Windows Desktop Release (.exe)
echo -------------------------------------------------------------------------------
echo [3/4] Building Windows Desktop Release (x64 Release Executable)...
echo -------------------------------------------------------------------------------
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo [WARN] Windows build encountered errors or Visual Studio C++ toolchain is missing.
) else (
    echo [✓] Windows Release build successful!
)
echo.

:: 5. Build Android Release APK (.apk)
echo -------------------------------------------------------------------------------
echo [4/4] Building Android Production APK (Release)...
echo -------------------------------------------------------------------------------
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo [WARN] Android APK build encountered errors or Android SDK is missing.
) else (
    echo [✓] Android APK Release build successful!
)
echo.

:: 6. Build Summary & Artifact Paths
echo ===============================================================================
echo                       RELEASE COMPILATION SUMMARY
echo ===============================================================================
echo.
echo [1] Windows Desktop Application (.exe):
set "WIN_EXE=%~dp0build\windows\x64\runner\Release\onespend.exe"
if exist "!WIN_EXE!" (
    echo     Status: READY
    echo     Path:   !WIN_EXE!
) else (
    echo     Path:   %~dp0build\windows\x64\runner\Release\onespend.exe
    echo     Note:   Run 'flutter build windows --release' once Visual Studio C++ is ready.
)
echo.

echo [2] Android Application Package (.apk):
set "ANDROID_APK=%~dp0build\app\outputs\flutter-apk\app-release.apk"
if exist "!ANDROID_APK!" (
    echo     Status: READY
    echo     Path:   !ANDROID_APK!
) else (
    echo     Path:   %~dp0build\app\outputs\flutter-apk\app-release.apk
    echo     Note:   Run 'flutter build apk --release' once Android SDK is configured.
)
echo.
echo ===============================================================================
echo  OneSpend by AR1 is ready for production distribution.
echo ===============================================================================
echo.

pause
exit /b 0

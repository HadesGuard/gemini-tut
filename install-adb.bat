@echo off
echo ==========================================
echo   ADB Installer for Windows
echo ==========================================
echo.

:: Check if ADB already installed
where adb >nul 2>&1
if not errorlevel 1 (
    echo [OK] ADB da duoc cai roi
    adb version
    pause
    exit /b 0
)

echo [INFO] Dang tai ADB Platform Tools...
echo.

:: Download ADB
curl -L -o "%TEMP%\platform-tools.zip" https://dl.google.com/android/repository/platform-tools-latest-windows.zip
if errorlevel 1 (
    echo [LOI] Khong tai duoc ADB
    echo Kiem tra ket noi mang
    pause
    exit /b 1
)

echo.
echo [INFO] Dang giai nen...

:: Extract to C:\adb
powershell -command "Expand-Archive -Path '%TEMP%\platform-tools.zip' -DestinationPath 'C:\' -Force"
if errorlevel 1 (
    echo [LOI] Khong giai nen duoc
    pause
    exit /b 1
)

:: Rename folder
if exist "C:\adb" rmdir /s /q "C:\adb"
rename "C:\platform-tools" "adb"

echo.
echo [INFO] Them vao PATH...

:: Add to PATH permanently
setx PATH "%PATH%;C:\adb" >nul 2>&1

:: Add to current session
set "PATH=%PATH%;C:\adb"

:: Clean up
del "%TEMP%\platform-tools.zip" 2>nul

echo.
echo [OK] Cai dat thanh cong
echo.
C:\adb\adb.exe version
echo.
echo Duong dan: C:\adb
echo Da them vao PATH - mo CMD moi de su dung
echo.
echo ==========================================
echo   HOAN TAT - Thu chay: adb devices
echo ==========================================
pause

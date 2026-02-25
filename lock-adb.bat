@echo off
echo ==========================================
echo   ADB Keys Lock Tool - TWRP Recovery
echo ==========================================
echo.

where adb >nul 2>&1
if errorlevel 1 (
    echo [LOI] Khong tim thay ADB
    pause
    exit /b 1
)

if not exist "%USERPROFILE%\.android\adbkey" (
    echo [LOI] Khong tim thay adbkey
    echo Copy file adbkey va adbkey.pub vao %USERPROFILE%\.android\
    pause
    exit /b 1
)

if not exist "%USERPROFILE%\.android\adbkey.pub" (
    echo [LOI] Khong tim thay adbkey.pub
    echo Copy file adbkey va adbkey.pub vao %USERPROFILE%\.android\
    pause
    exit /b 1
)

echo [OK] Tim thay key
echo.
echo [INFO] Thiet bi dang ket noi:
adb devices
echo.

echo [1/7] Reboot may "device" vao TWRP...
for /f "tokens=1" %%s in ('adb devices ^| findstr "device" ^| findstr /v "List"') do (
    echo   Reboot: %%s
    adb -s %%s reboot recovery 2>nul
)

echo.
echo Kiem tra may "unauthorized"...
for /f "tokens=1" %%s in ('adb devices ^| findstr "unauthorized"') do (
    echo   [CANH BAO] %%s dang unauthorized - can boot TWRP bang tay
    echo   Tat may, giu Nguon + Tang am luong + Bixby
)

echo.
echo Kiem tra may da o "recovery"...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    echo   %%s - da o recovery, bo qua reboot
)

echo.
echo Doi 40 giay cho cac may vao TWRP...
timeout /t 40

echo.
echo [2/7] Kiem tra trang thai...
adb devices
echo.

echo [3/7] Push key cho may bi mat...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell "test -f /data/misc/adb/adb_keys"
    if errorlevel 1 (
        echo   %%s - KHONG CO KEY, dang push...
        adb -s %%s push "%USERPROFILE%\.android\adbkey.pub" /data/misc/adb/adb_keys
    ) else (
        echo   %%s - Da co key
    )
)

echo.
echo [4/7] Bo khoa cu...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell chattr -i /data/misc/adb/adb_keys 2>nul
)
echo   Done.

echo.
echo [5/7] Sua quyen file...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell chmod 640 /data/misc/adb/adb_keys
    adb -s %%s shell chown system:shell /data/misc/adb/adb_keys
    echo   %%s - OK
)

echo.
echo [6/7] Khoa file chattr +i...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell chattr +i /data/misc/adb/adb_keys
    echo   %%s - Da khoa
)

echo.
echo ========== KET QUA ==========
echo.
echo --- KHOA ---
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    echo   %%s:
    adb -s %%s shell lsattr /data/misc/adb/adb_keys
)
echo.
echo --- QUYEN ---
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    echo   %%s:
    adb -s %%s shell ls -la /data/misc/adb/adb_keys
)

echo.
echo [7/7] Reboot tat ca...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s reboot
    echo   %%s - Da reboot
)

echo.
echo ==========================================
echo   HOAN TAT
echo   Doi 1 phut roi chay: adb devices
echo   Tat ca may phai hien device
echo ==========================================
pause

@echo off
:: ==========================================
::   ADB Keys Lock Tool v1.1
::   Auto lock adb_keys on devices
::   Supports: single device (UDID) or all
:: ==========================================

echo ==========================================
echo   ADB Keys Lock Tool - TWRP Recovery
echo ==========================================
echo.

:: Check ADB
where adb >nul 2>&1
if errorlevel 1 (
    echo [LOI] Khong tim thay ADB!
    echo Download: https://developer.android.com/studio/releases/platform-tools
    pause
    exit /b 1
)

:: Check key files
if not exist "%USERPROFILE%\.android\adbkey" (
    echo [LOI] Khong tim thay adbkey (private key)!
    echo Copy file adbkey va adbkey.pub vao %USERPROFILE%\.android\
    pause
    exit /b 1
)
if not exist "%USERPROFILE%\.android\adbkey.pub" (
    echo [LOI] Khong tim thay adbkey.pub (public key)!
    echo Copy file adbkey va adbkey.pub vao %USERPROFILE%\.android\
    pause
    exit /b 1
)
echo [OK] Tim thay key: %USERPROFILE%\.android\adbkey.pub

:: Show connected devices
echo [INFO] Thiet bi dang ket noi:
echo.
adb devices
echo.

:: Ask user
echo ==========================================
echo   Chon che do:
echo   1. Chay tren TAT CA thiet bi
echo   2. Nhap UDID cu the
echo ==========================================
echo.
set /p mode="Nhap 1 hoac 2: "

if "%mode%"=="1" goto ALL_DEVICES
if "%mode%"=="2" goto SINGLE_DEVICE

echo [LOI] Lua chon khong hop le!
pause
exit /b 1

:: ==========================================
:: MODE 1: ALL DEVICES
:: ==========================================
:ALL_DEVICES
echo.
echo [MODE] Chay tren TAT CA thiet bi...
echo.

set count=0
for /f "tokens=1" %%s in ('adb devices ^| findstr "device" ^| findstr /v "List"') do set /a count+=1
echo Tim thay %count% thiet bi.

if %count%==0 (
    echo [LOI] Khong co thiet bi nao!
    pause
    exit /b 1
)

echo.
echo [1/7] Reboot tat ca vao TWRP...
for /f "tokens=1" %%s in ('adb devices ^| findstr "device" ^| findstr /v "List"') do (
    echo   Reboot: %%s
    adb -s %%s reboot recovery 2>nul
)
echo.
echo Doi 40 giay...
timeout /t 40

echo.
echo [2/7] Kiem tra trang thai...
adb devices
echo.

set rcount=0
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do set /a rcount+=1
echo %rcount% thiet bi da vao recovery.

if %rcount%==0 (
    echo [LOI] Khong co thiet bi nao vao recovery!
    pause
    exit /b 1
)

echo.
echo [3/7] Kiem tra va push key...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell "test -f /data/misc/adb/adb_keys" 2>nul
    if errorlevel 1 (
        echo   %%s - KHONG CO KEY, dang push...
        adb -s %%s push "%USERPROFILE%\.android\adbkey.pub" /data/misc/adb/adb_keys
    ) else (
        echo   %%s - Da co key
    )
)

echo.
echo [4/7] Bo khoa cu (neu co)...
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
echo [6/7] Khoa file (chattr +i)...
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    adb -s %%s shell chattr +i /data/misc/adb/adb_keys
    echo   %%s - Da khoa
)

echo.
echo ========== KET QUA ==========
echo.
echo --- KHOA (phai co chu i) ---
for /f "tokens=1" %%s in ('adb devices ^| findstr "recovery"') do (
    echo   %%s:
    adb -s %%s shell lsattr /data/misc/adb/adb_keys
)
echo.
echo --- QUYEN (phai la: -rw-r----- system shell) ---
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

goto DONE

:: ==========================================
:: MODE 2: SINGLE DEVICE
:: ==========================================
:SINGLE_DEVICE
echo.
set /p udid="Nhap UDID (vd: 21119d0721057ece): "

if "%udid%"=="" (
    echo [LOI] UDID khong duoc de trong!
    pause
    exit /b 1
)

echo.
echo [MODE] Chay tren thiet bi: %udid%
echo.

echo [1/7] Reboot vao TWRP...
adb -s %udid% reboot recovery 2>nul
if errorlevel 1 (
    echo [CANH BAO] Khong reboot duoc, co the may dang unauthorized.
    echo Thu boot bang tay: Nguon + Tang am luong + Bixby
    echo.
    echo Bam phim bat ky khi da vao TWRP...
    pause
) else (
    echo Doi 40 giay...
    timeout /t 40
)

echo.
echo [2/7] Kiem tra trang thai...
adb devices | findstr "%udid%"
echo.

echo [3/7] Kiem tra va push key...
adb -s %udid% shell "test -f /data/misc/adb/adb_keys" 2>nul
if errorlevel 1 (
    echo   KHONG CO KEY, dang push...
    adb -s %udid% push "%USERPROFILE%\.android\adbkey.pub" /data/misc/adb/adb_keys
) else (
    echo   Da co key
)

echo.
echo [4/7] Bo khoa cu (neu co)...
adb -s %udid% shell chattr -i /data/misc/adb/adb_keys 2>nul
echo   Done.

echo.
echo [5/7] Sua quyen file...
adb -s %udid% shell chmod 640 /data/misc/adb/adb_keys
adb -s %udid% shell chown system:shell /data/misc/adb/adb_keys
echo   OK

echo.
echo [6/7] Khoa file (chattr +i)...
adb -s %udid% shell chattr +i /data/misc/adb/adb_keys
echo   Da khoa

echo.
echo ========== KET QUA ==========
echo.
echo --- KHOA ---
adb -s %udid% shell lsattr /data/misc/adb/adb_keys
echo.
echo --- QUYEN ---
adb -s %udid% shell ls -la /data/misc/adb/adb_keys

echo.
echo [7/7] Reboot...
adb -s %udid% reboot
echo   Da reboot

goto DONE

:: ==========================================
:: DONE
:: ==========================================
:DONE
echo.
echo ==========================================
echo   HOAN TAT!
echo   Doi 1 phut roi chay: adb devices
echo   Tat ca may phai hien "device"
echo ==========================================
pause

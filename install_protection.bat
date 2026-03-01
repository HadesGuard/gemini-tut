@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Install vendor/build.prop Protection

echo ============================================
echo  Auto-repair protection for vendor/build.prop
echo  Protects against MiChanger Pro corruption
echo ============================================
echo.

set RCFILE=%~dp0data\rom\fix_vendor_prop.rc
set SHFILE=%~dp0data\rom\fix_vendor_prop.sh
set BAKFILE=C:\Users\X99\Downloads\vendor_buildprop_good.bin

if not exist "%RCFILE%" ( echo ERROR: %RCFILE% not found & pause & exit /b 1 )
if not exist "%SHFILE%" ( echo ERROR: %SHFILE% not found & pause & exit /b 1 )

set SUCCESS=0
set FAIL=0
set SKIP=0

REM --- Nếu có argument, dùng serial đó luôn ---
if not "%~1"=="" (
    set TARGET=%~1
    echo Dung serial tu argument: !TARGET!
    echo.
    goto :detect_and_run
)

REM --- Scan danh sach device ---
adb devices > "%TEMP%\adb_devs.txt" 2>nul

REM Dem so luong device
set DEVCOUNT=0
for /f "tokens=1,2" %%a in ('findstr /r "device$ recovery$" "%TEMP%\adb_devs.txt"') do (
    set /a DEVCOUNT+=1
)

if %DEVCOUNT%==0 (
    echo Khong tim thay device nao! Kiem tra ADB va USB debugging.
    del "%TEMP%\adb_devs.txt" 2>nul
    pause & exit /b 1
)

if %DEVCOUNT%==1 (
    REM Chi co 1 device, dung luon
    for /f "tokens=1,2" %%a in ('findstr /r "device$ recovery$" "%TEMP%\adb_devs.txt"') do (
        set TARGET=%%a
        set TARGET_MODE=%%b
    )
    echo Tim thay 1 device: !TARGET! [!TARGET_MODE!]
    echo.
    goto :run_target
)

REM Co nhieu device - hien menu chon
echo Danh sach device dang ket noi:
echo.
set IDX=0
for /f "tokens=1,2" %%a in ('findstr /r "device$ recovery$" "%TEMP%\adb_devs.txt"') do (
    set /a IDX+=1
    echo   [!IDX!] %%a  [%%b]
    set DEV_!IDX!=%%a
    set MODE_!IDX!=%%b
)
del "%TEMP%\adb_devs.txt" 2>nul
echo.
set /p CHOICE=Chon device (1-%IDX%):

if "!CHOICE!"=="" ( echo Khong chon device. & pause & exit /b 1 )
if !CHOICE! LSS 1 ( echo Lua chon khong hop le. & pause & exit /b 1 )
if !CHOICE! GTR %IDX% ( echo Lua chon khong hop le. & pause & exit /b 1 )

set TARGET=!DEV_%CHOICE%!
set TARGET_MODE=!MODE_%CHOICE%!
echo.
echo Da chon: !TARGET! [!TARGET_MODE!]
echo.
goto :run_target

:detect_and_run
REM Detect mode khi dung argument
adb devices > "%TEMP%\adb_devs.txt" 2>nul
set TARGET_MODE=
for /f "tokens=1,2" %%a in ('findstr /r "device$ recovery$" "%TEMP%\adb_devs.txt"') do (
    if "%%a"=="!TARGET!" set TARGET_MODE=%%b
)
del "%TEMP%\adb_devs.txt" 2>nul
if "!TARGET_MODE!"=="" (
    echo ERROR: Khong tim thay device !TARGET!
    pause & exit /b 1
)

:run_target
echo --- !TARGET! [!TARGET_MODE!] ---
if "!TARGET_MODE!"=="recovery" (
    call :recovery !TARGET!
) else (
    call :device !TARGET!
)
echo.

echo ============================================
echo  Success: %SUCCESS%  Fail: %FAIL%  Skip: %SKIP%
echo ============================================
pause
exit /b 0

:recovery
REM Find system path
adb -s %1 shell "[ -d /tmp/system/system/etc/init ]" >nul 2>&1
if not errorlevel 1 ( set SP=/tmp/system/system ) else (
    adb -s %1 shell "[ -d /system/system/etc/init ]" >nul 2>&1
    if not errorlevel 1 ( set SP=/system/system ) else (
        echo   SKIP: system not mounted
        set /a SKIP+=1 & goto :eof
    )
)
adb -s %1 shell "[ -f !SP!/etc/init/fix_vendor_prop.rc ]" >nul 2>&1
if not errorlevel 1 ( echo   SKIP: already installed & set /a SKIP+=1 & goto :eof )

adb -s %1 shell "mount -o rw,remount /tmp/system 2>/dev/null; mount -o rw,remount /system 2>/dev/null" >nul 2>&1

REM Push files via /data/local/tmp (avoid path issues)
adb -s %1 push "%RCFILE%" /data/local/tmp/fix_vendor_prop.rc >nul 2>&1
adb -s %1 push "%SHFILE%" /data/local/tmp/fix_vendor_prop.sh >nul 2>&1
adb -s %1 shell "cp /data/local/tmp/fix_vendor_prop.rc !SP!/etc/init/fix_vendor_prop.rc; cp /data/local/tmp/fix_vendor_prop.sh !SP!/etc/fix_vendor_prop.sh; chmod 644 !SP!/etc/init/fix_vendor_prop.rc; chmod 755 !SP!/etc/fix_vendor_prop.sh; rm /data/local/tmp/fix_vendor_prop.*" 2>nul

REM Backup vendor/build.prop
adb -s %1 shell "[ -f /data/vendor_build.prop.bak ]" >nul 2>&1
if errorlevel 1 (
    set VP=
    adb -s %1 shell "[ -f /tmp/vendor/build.prop ]" >nul 2>&1 && set VP=/tmp/vendor
    if "!VP!"=="" ( adb -s %1 shell "[ -f /vendor/build.prop ]" >nul 2>&1 && set VP=/vendor )
    if not "!VP!"=="" (
        for /f %%z in ('adb -s %1 shell "wc -c < !VP!/build.prop 2>/dev/null"') do set VSIZE=%%z
        if !VSIZE! GTR 2000 (
            adb -s %1 shell "cp !VP!/build.prop /data/vendor_build.prop.bak; chmod 600 /data/vendor_build.prop.bak" 2>nul
        ) else if exist "%BAKFILE%" (
            adb -s %1 push "%BAKFILE%" /data/local/tmp/vbp.bak >nul 2>&1
            adb -s %1 shell "cp /data/local/tmp/vbp.bak /data/vendor_build.prop.bak; chmod 600 /data/vendor_build.prop.bak; rm /data/local/tmp/vbp.bak" 2>nul
        )
    )
)
adb -s %1 shell "sync" 2>nul

adb -s %1 shell "[ -f !SP!/etc/init/fix_vendor_prop.rc ]" >nul 2>&1
if errorlevel 1 ( echo   FAIL & set /a FAIL+=1 ) else ( echo   OK [recovery] & set /a SUCCESS+=1 )
goto :eof

:device
adb -s %1 shell "[ -f /system/etc/init/fix_vendor_prop.rc ]" >nul 2>&1
if not errorlevel 1 ( echo   SKIP: already installed & set /a SKIP+=1 & goto :eof )

adb -s %1 shell "su -c id" >nul 2>&1
if errorlevel 1 ( echo   SKIP: no su & set /a SKIP+=1 & goto :eof )

adb -s %1 shell "su -c 'mount -o rw,remount /'" >nul 2>&1
adb -s %1 shell "su -c 'mount -o rw,remount /system'" >nul 2>&1

REM Push to /data/local/tmp then copy with su
adb -s %1 push "%RCFILE%" /data/local/tmp/fix_vendor_prop.rc >nul 2>&1
adb -s %1 push "%SHFILE%" /data/local/tmp/fix_vendor_prop.sh >nul 2>&1
adb -s %1 shell "su -c 'cp /data/local/tmp/fix_vendor_prop.rc /system/etc/init/fix_vendor_prop.rc; cp /data/local/tmp/fix_vendor_prop.sh /system/etc/fix_vendor_prop.sh; chmod 644 /system/etc/init/fix_vendor_prop.rc; chmod 755 /system/etc/fix_vendor_prop.sh; rm /data/local/tmp/fix_vendor_prop.*'" 2>nul

REM Backup
adb -s %1 shell "su -c '[ -f /data/vendor_build.prop.bak ]'" >nul 2>&1
if errorlevel 1 (
    adb -s %1 shell "su -c 'cp /vendor/build.prop /data/vendor_build.prop.bak; chmod 600 /data/vendor_build.prop.bak'" 2>nul
)

adb -s %1 shell "su -c 'mount -o ro,remount /system; sync'" >nul 2>&1

adb -s %1 shell "[ -f /system/etc/init/fix_vendor_prop.rc ]" >nul 2>&1
if errorlevel 1 ( echo   FAIL & set /a FAIL+=1 ) else ( echo   OK [device] & set /a SUCCESS+=1 )
goto :eof

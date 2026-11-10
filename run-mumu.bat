@echo off
echo ========================================
echo   Flutter Run - MuMu Player
echo ========================================

echo [1/3] Pastikan MuMu Player sudah terbuka...
timeout /t 2 /nobreak >nul

echo [2/3] Menghubungkan ADB ke MuMu Player...
C:\Users\Nitro\AppData\Local\Android\Sdk\platform-tools\adb.exe connect 127.0.0.1:7555

echo [3/3] Menjalankan Flutter ke MuMu Player...
cd /d D:\darts5\ProjectUTS-PAPB\mobile
D:\flutter\bin\flutter.bat run -d 127.0.0.1:7555

pause

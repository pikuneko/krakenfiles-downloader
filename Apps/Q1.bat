@echo off
chcp 65001 >nul
title Chromeバージョン自動修復スクリプト

echo ====================================================
echo ⚙️ Google Chrome のバージョンを確認しています...
echo ====================================================

:: 1. レジストリから現在の実物Chromeのバージョン文字列を取得
set "CHROME_VER="
for /f "tokens=2*" %%A in ('reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version 2^>nul') do set "CHROME_VER=%%B"

if "%CHROME_VER%"=="" (
    for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" /v version 2^>nul') do set "CHROME_VER=%%B"
)

if "%CHROME_VER%"=="" (
    echo ❌ エラー: Google Chrome のバージョンをレジストリから取得できませんでした。
    pause
    exit /b
)

:: 2. 主要バージョン（最初の3桁、例: 148）を切り出す
for /f "tokens=1 delims=." %%A in ("%CHROME_VER%") do set "MAIN_VER=%%A"
echo 💻 現在の Chrome 主要バージョン: %MAIN_VER%

:: 3. 1つ上の階層（133dl.meScript直下）にある main.py の version_main=XXX を自動書き換え
echo 🔧 main.py のバージョン指定を自動修復中...
powershell -NoProfile -ExecutionPolicy Bypass -Command "^
    $path = '../main.py'; ^
    if (Test-Path $path) { ^
        $content = Get-Content $path -Raw -Encoding UTF8; ^
        $updated = $content -replace 'version_main=\d+', 'version_main=%MAIN_VER%'; ^
        Set-Content $path $updated -Encoding UTF8; ^
        Write-Host '✅ main.py の自動修正に成功しました！' -ForegroundColor Green; ^
    } else { ^
        Write-Host '❌ エラー: 1つ上のフォルダに main.py が見つかりません。' -ForegroundColor Red; ^
    } ^
"

echo ====================================================
echo 修正が完了しました。この画面を閉じます。
echo ====================================================
timeout /t 3 >nul

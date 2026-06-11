@echo off
chcp 65001 >nul
title KrakenFiles 自動修復付きランチャー

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
    echo 通常通り main.py を直接実行するか、Chromeのインストール状態を確認してください。
    pause
    exit /b
)

:: 2. 主要バージョン（最初の3桁、例: 148）を切り出す
for /f "tokens=1 delims=." %%A in ("%CHROME_VER%") do set "MAIN_VER=%%A"
echo 💻 現在の Chrome 主要バージョン: %MAIN_VER%

:: 3. PowerShellを使って main.py 内の version_main=XXX を自動書き換え
echo 🔧 main.py のバージョン指定を自動修復中...
powershell -NoProfile -ExecutionPolicy Bypass -Command "^
    $path = './main.py'; ^
    if (Test-Path $path) { ^
        $content = Get-Content $path -Raw -Encoding UTF8; ^
        $updated = $content -replace 'version_main=\d+', 'version_main=%MAIN_VER%'; ^
        Set-Content $path $updated -Encoding UTF8; ^
        Write-Host '✅ main.py の自動書き換えに成功しました。' -ForegroundColor Green; ^
    } else { ^
        Write-Host '❌ エラー: main.py が見つかりません。' -ForegroundColor Red; ^
    } ^
"

echo.
echo ====================================================
echo 🚀 スクレイピングプログラムを起動します...
echo ====================================================
echo.

:: 4. メインプログラムを起動
python main.py

pause

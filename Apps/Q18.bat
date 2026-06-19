@echo off
chcp 65001 >nul
title Google Chrome 自動インストールスクリプト

echo ====================================================
echo 🌐 Google Chrome 自動ダウンロード＆インストール（Q18）
echo ====================================================
echo.

:: 1. 管理者権限のチェック
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 管理者権限への自動昇格を試みています...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

echo 📥 Google Chrome（最新・64bit安定版）のインストーラーを取得中...
:: PowerShellを使用して公式のスタンドアロンインストーラー（ChromeEnterprise用）を安全にダウンロード
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://google.com' -OutFile 'chrome_installer.exe'"

if not exist "chrome_installer.exe" (
    echo ❌ エラー: インストーラーのダウンロードに失敗しました。インターネット接続を確認してください。
    pause
    exit /b
)

echo ⚙️ Google Chrome をバックグラウンドでサイレントインストール中...
echo    (数分かかります。画面が消えるまでそのままお待ちください...)
:: サイレントインストールスイッチを実行
start /wait chrome_installer.exe /silent /install
del chrome_installer.exe

echo.
echo ====================================================
echo ✅ Google Chrome のインストール処理が完了しました！
echo ====================================================
timeout /t 3 >nul

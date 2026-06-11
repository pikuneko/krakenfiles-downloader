@echo off
:: 🟢 1. ターミナルの文字コードをUTF-8（コードページ65001）に強制変更
chcp 65001 >nul
title KrakenFiles自動化 環境構築スクリプト

:: 🟢 2. 【自動管理者昇格ロジック】
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 管理者権限への自動昇格を試みています...
    echo 画面に警告（UAC）が出たら「はい」を選択してください。
    
    :: PowerShellをUTF-8モードで起動し、自身を管理者として実行
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::InputEncoding = [System.Text.Encoding]::UTF8; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 🟢 3. 管理者として開き直された後のカレントディレクトリの補正
cd /d "%~dp0"

echo ====================================================
echo 🚀 KrakenFiles 自動ダウンロード環境構築を開始します
echo ====================================================
echo.

:: 1. Pythonの存在確認
echo 🔍 Pythonの環境を確認しています...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ エラー: Pythonがシステムにインストールされていないか、PATHが通っていません。
    echo Pythonをインストールしてから再度実行してください。
    echo.
    pause
    exit /b
)
echo ✅ Pythonが検出されました。
echo.

:: 2. 必要なPythonライブラリの一括インストール
echo 📦 必要なPythonライブラリをインストール中...
python -m pip install --upgrade pip
python -m pip install undetected-chromedriver beautifulsoup4 requests
if %errorlevel% neq 0 (
    echo ⚠️ ライブラリのインストール中にエラーが発生しました。インターネット接続を確認してください。
    pause
    exit /b
)
echo ✅ Pythonライブラリのインストールが完了しました。
echo.

:: 3. 7-Zipのインストール状態の確認と自動導入
echo 🔍 7-Zipのインストール状態を確認中...
if exist "C:\Program Files\7-Zip\7z.exe" (
    echo ✅ 7-Zipは既にインストールされています。
) else (
    echo 📥 7-Zipが見つかりません。公式から最新版をダウンロードしてインストールします...
    
    :: PowerShellを使って公式から64bit版のインストーラーをダウンロード
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://7-zip.org' -OutFile '7z_installer.exe'"
    
    if exist "7z_installer.exe" (
        echo ⚙️ 7-Zipをバックグラウンドでサイレントインストール中...
        start /wait 7z_installer.exe /S
        del 7z_installer.exe
        
        if exist "C:\Program Files\7-Zip\7z.exe" (
            echo ✅ 7-Zipのインストールに成功しました！
        ) else (
            echo ❌ 7-Zipの自動インストールに失敗しました。手動でインストールしてください。
        )
    ) else (
        echo ❌ 7-Zipインストーラーのダウンロードに失敗しました。
    )
)
echo.

echo ====================================================
echo 🎉 すべての前提環境の構築が完了しました！
echo main.py を実行して自動ダウンロードをお試しください。
echo ====================================================
echo.
pause

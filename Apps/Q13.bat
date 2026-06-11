@echo off
chcp 65001 >nul
title タイムアウト値（Q13）自動変更スクリプト

echo ====================================================
echo 🕒 ダウンロード待機タイムアウト時間の変更（Q13）
echo ====================================================
echo.
echo 現在の main.py に設定されているタイムアウト時間を変更します。
echo 何分間ダウンロードを待つか、数字（分）で入力してください。
echo.
echo [目安]: 5分=300 / 10分=600 / 20分=1200 / 30分=1800
echo ----------------------------------------------------

:INPUT_LOOP
set /p "INPUT_MIN=⏳ 何分に設定しますか？ (数字のみ入力): "

:: 入力値が数字かどうかをチェック
echo %INPUT_MIN%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo ❌ エラー: 半角数字のみを入力してください。
    echo.
    goto INPUT_LOOP
)

:: 分を秒に変換 (PowerShellで計算)
for /f %%A in ('powershell -NoProfile -Command "%INPUT_MIN% * 60"') do set "SEC_VAL=%%A"

echo.
echo 💻 設定値: %INPUT_MIN% 分 （%SEC_VAL% 秒）に書き換えます。

:: バッチファイルの場所を基準に、1つ上のフォルダにある main.py の絶対パスを割り出す
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..") do set "PARENT_DIR=%%~fI"
set "TARGET_MAIN_PY=%PARENT_DIR%\main.py"

if not exist "%TARGET_MAIN_PY%" (
    echo ❌ エラー: main.py が見つかりませんでした。パスを確認してください。
    pause
    exit /b
)

:: 🟢 【修正ポイント】PowerShellのコードを改行（^）せずに1行に集約
echo 🔧 main.py のタイムアウト指定を自動修復中...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = '%TARGET_MAIN_PY%'.Replace('\', '/'); if (Test-Path $path) { $content = Get-Content $path -Raw -Encoding UTF8; if ($content -match 'timeout=\d+') { $updated = $content -replace 'timeout=\d+', 'timeout=%SEC_VAL%'; Set-Content $path $updated -Encoding UTF8; Write-Host '✅ main.py のタイムアウト時間を変更しました！' -ForegroundColor Green; } else { Write-Host '❌ 警告: main.py 内に timeout= の記述が見つかりませんでした。' -ForegroundColor Yellow; } } else { Write-Host '❌ エラー: main.py が見つかりません。' -ForegroundColor Red; }"

echo ====================================================
echo 変更が完了しました。3秒後に画面を閉じます。
echo ====================================================
timeout /t 3 >nul

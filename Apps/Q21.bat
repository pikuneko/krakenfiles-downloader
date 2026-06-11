@echo off
chcp 65001 >nul
title ZIP解凍形式切り替え設定（Q21）

echo ====================================================
echo 📂 自動解凍対象にZIPを追加する設定（Q21）
echo ====================================================
echo.
echo 自動解凍システムがスキャンするファイル形式を切り替えます。
echo.

:INPUT_LOOP
set /p "CHOICE=❓ ZIPファイルも自動解凍の対象に含めますか？ (Y/N): "

if /i "%CHOICE%"=="Y" (
    set "REPLACE_LINE=    target_files = [f for f in os.listdir(download_dir) if f.lower().endswith(('.rar', '.zip'))]"
    echo ⚙️ 「RAR と ZIP の両方を解凍する」に設定します...
    goto PROCESS
)
if /i "%CHOICE%"=="N" (
    set "REPLACE_LINE=    target_files = [f for f in os.listdir(download_dir) if f.lower().endswith('.rar')]"
    echo ⚙️ 「RAR のみ解凍する」に設定します...
    goto PROCESS
)

echo ❌ エラー: Y または N の文字を入力してください。
echo.
goto INPUT_LOOP

:PROCESS
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..") do set "PARENT_DIR=%%~fI"
set "TARGET_MAIN_PY=%PARENT_DIR%\main.py"

if not exist "%TARGET_MAIN_PY%" (
    echo ❌ エラー: main.py が見つかりませんでした。パスを確認してください。
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = '%TARGET_MAIN_PY%'.Replace('\', '/'); $content = Get-Content $path -Raw -Encoding UTF8; if ($content -match '(?m)^\s*target_files\s*=\s*\[f\s+for.+endswith.+\]') { $updated = $content -replace '(?m)^\s*target_files\s*=\s*\[f\s+for.+endswith.+\]', '%REPLACE_LINE%'; Set-Content $path $updated -Encoding UTF8; Write-Host '✅ main.py の解凍対象設定を変更しました！' -ForegroundColor Green; } else { Write-Host '❌ エラー: main.py 内に対象のコード記述が見つかりませんでした。' -ForegroundColor Red; }"

echo ====================================================
echo 設定が完了しました。3秒後に画面を閉じます。
echo ====================================================
timeout /t 3 >nul

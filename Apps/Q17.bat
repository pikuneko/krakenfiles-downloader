@echo off
chcp 65001 >nul
title RARファイル自動削除設定（Q17）

echo ====================================================
echo 🗑️ 解凍成功後の元のRARファイル自動削除設定（Q17）
echo ====================================================
echo.
echo 解凍が正常に成功したあと、元の「.rar」ファイルを
echo 自動で削除（消去）する設定を切り替えます。
echo.

:INPUT_LOOP
set /p "CHOICE=❓ 解凍後に元のRARファイルを自動削除しますか？ (Y/N): "

if /i "%CHOICE%"=="Y" (
    set "REPLACE_LINE=            os.remove(rar_path)"
    echo ⚙️ 「自動削除する」に設定を変更します...
    goto PROCESS
)
if /i "%CHOICE%"=="N" (
    set "REPLACE_LINE=            # os.remove(rar_path)"
    echo ⚙️ 「自動削除しない（ファイルを残す）」に設定を変更します...
    goto PROCESS
)

echo ❌ エラー: Y または N の文字を入力してください。
echo.
goto INPUT_LOOP

:PROCESS
:: バッチファイルの場所を基準に、1つ上のフォルダにある main.py の絶対パスを割り出す
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..") do set "PARENT_DIR=%%~fI"
set "TARGET_MAIN_PY=%PARENT_DIR%\main.py"

if not exist "%TARGET_MAIN_PY%" (
    echo ❌ エラー: main.py が見つかりませんでした。パスを確認してください。
    pause
    exit /b
)

:: PowerShellを使って main.py 内の os.remove 行を安全に置換
powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = '%TARGET_MAIN_PY%'.Replace('\', '/'); $content = Get-Content $path -Raw -Encoding UTF8; if ($content -match '(?m)^\s*#?\s*os\.remove\(rar_path\)') { $updated = $content -replace '(?m)^\s*#?\s*os\.remove\(rar_path\)', '%REPLACE_LINE%'; Set-Content $path $updated -Encoding UTF8; Write-Host '✅ main.py の自動削除設定を変更しました！' -ForegroundColor Green; } else { Write-Host '❌ エラー: main.py 内に対象のコード記述が見つかりませんでした。' -ForegroundColor Red; }"

echo ====================================================
echo 設定が完了しました。3秒後に画面を閉じます。
echo ====================================================
timeout /t 3 >nul

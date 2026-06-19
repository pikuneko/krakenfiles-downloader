@chartype BOM-UTF8
@echo off
chcp 65001 >nul
cls

echo ======================================================
echo 🟢 Q22. ゾンビシステム（広告引き戻し）試行回数変更バッチ
echo ======================================================
echo.
echo 現在の main.py 内のゾンビシステム最大試行回数を変更します。
echo ※標準値は 8 回です。広告の突破が厳しい場合は回数を増やしてください。
echo.

set /p RETRY_NUM="新しい最大試行回数を数字で入力してください (例: 5〜15): "

:: 入力値の簡易数値チェック
echo %RETRY_NUM%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo [エラー] 有効な数値を入力してください。処理を中止します。
    pause
    exit /b
)

echo.
echo 設定を適用中... main.py の ZOMBIE_RETRY_LIMIT を %RETRY_NUM% に書き換えます。

:: プロジェクトのメインルートへ移動してPowerShellパッチを実行
cd /d "%~dp0.."
powershell -Command "(Get-Content -Raw main.py) -replace 'ZOMBIE_RETRY_LIMIT\s*=\s*\d+', 'ZOMBIE_RETRY_LIMIT = %RETRY_NUM%' | Set-Content -Encoding UTF8 main.py"

echo.
echo [完了] main.py の書き換えが正常に完了しました！
echo.
pause

@chartype BOM-UTF8
@echo off
chcp 65001 >nul
cls

echo ======================================================
echo 🟢 Q23. 開発環境・前提ライブラリ一括診断バッチ
echo ======================================================
echo.
echo このスクリプトは、Windows 11環境に必要なPython、Google Chrome、
echo および main.py の実行に必要な外部ライブラリが揃っているか自動判定します。
echo.
echo 1. 診断を開始する
echo 2. 中止する
echo.
set /p CHOICE="番号を入力してエンターを押してください (1-2): "

if "%CHOICE%"=="2" exit /b
if not "%CHOICE%"=="1" (
    echo [エラー] 1か2を選択してください。
    pause
    exit /b
)

cls
echo ======================================================
echo 診断実行中...（しばらくお待ちください）
echo ======================================================
echo.

:: 1. Python環境チェック
echo [1/4] Python本体の確認中...
where python >nul 2>&1
if errorlevel 1 (
    echo ❌ [致命的] Pythonがインストールされていないか、環境変数PATHに通っていません。
    goto ERROR_END
)
for /f "tokens=2" %%I in ('python --version 2^>^&1') do set PY_VER=%%I
echo 🟢 Pythonが見つかりました (バージョン: %PY_VER%)
echo.

:: 2. Google Chrome本体チェック
echo [2/4] Google Chromeの確認中...
reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version >nul 2>&1
if errorlevel 1 (
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" /v version >nul 2>&1
    if errorlevel 1 (
        echo ❌ [致命的] Google Chrome本体がシステムに見つかりません。Q18.batを実行してください。
        goto ERROR_END
    )
)
echo 🟢 Google Chromeがインストールされています。
echo.

:: 3. 必須Pythonライブラリチェック
echo [3/4] 外部ライブラリ（pipパッケージ）の確認中...
python -c "import undetected_chromedriver" >nul 2>&1
if errorlevel 1 (
    echo ❌ [未完了] undetected-chromedriver が不足しています。
    goto REQUIRE_SETUP
)
python -c "import selenium" >nul 2>&1
if errorlevel 1 (
    echo ❌ [未完了] selenium が不足しています。
    goto REQUIRE_SETUP
)
echo 🟢 すべての必須Pythonライブラリがインストールされています。
echo.

:: 4. プロジェクトルート階層の整合性チェック
echo [4/4] フォルダ構造の確認中...
cd /d "%~dp0.."
if not exist main.py (
    echo ❌ [エラー] 実行ルートに main.py が見つかりません。配置場所が不正です。
    goto ERROR_END
)
echo 🟢 プロジェクト構造は正常です (実行元: %CD%)
echo.
echo ======================================================
echo 🎉 【診断結果】すべての開発環境が100%%正常に整っています！
echo ======================================================
echo そのまま main.py を実行して自動化を開始できます。
echo.
pause
exit /b

:REQUIRE_SETUP
echo.
echo ⚠️  [対策] ライブラリの一部が不足しています。
echo フォルダのメインルートにある「setup.bat」を実行して一括インストールしてください。
echo.
pause
exit /b

:ERROR_END
echo.
echo ❌ 開発環境の構築が不完全です。上記のエラーメッセージを確認してください。
echo.
pause
exit /b

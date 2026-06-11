import os
import time
import subprocess
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def extract_rar_files():
    """ダウンロードフォルダ内のすべてのRARファイルを自動解凍する関数"""
    print("\n📦 [解凍工程] ダウンロードフォルダ内のRARファイルを解凍します...")
    
    download_dir = os.path.join(os.path.expanduser("~"), "Downloads")
    if not os.path.exists(download_dir):
        print("❌ ダウンロードフォルダが見つかりませんでした。")
        return

    exe_7zip = r"C:\Program Files\7-Zip\7z.exe"
    exe_winrar = r"C:\Program Files\WinRAR\WinRAR.exe"
    
    extractor_path = None
    extractor_type = None

    if os.path.exists(exe_7zip):
        extractor_path = exe_7zip
        extractor_type = "7zip"
    elif os.path.exists(exe_winrar):
        extractor_path = exe_winrar
        extractor_type = "winrar"
    else:
        print("⚠️ 警告: 「7-Zip」または「WinRAR」が見つからないため、自動解凍をスキップします。")
        return

    rar_files = [f for f in os.listdir(download_dir) if f.lower().endswith('.rar')]
    
    if not rar_files:
        print("📂 解凍待ちのRARファイルは見つかりませんでした。")
        return

    print(f"解凍ツールを検出しました: {extractor_type.upper()}")
    print(f"対象のRARファイル: {len(rar_files)}件")

    for rar in rar_files:
        rar_path = os.path.join(download_dir, rar)
        # 拡張子を除いたフォルダ名を作成
        folder_name = os.path.splitext(rar)[0]
        output_dir = os.path.join(download_dir, folder_name)
        
        print(f"🎬 解凍中: {rar} -> フォルダ: {folder_name}")
        
        try:
            if extractor_type == "7zip":
                cmd = [extractor_path, "x", rar_path, f"-o{output_dir}", "-y"]
            else:
                cmd = [extractor_path, "x", "-y", rar_path, output_dir + "\\"]

            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"✨ 解凍完了: {rar}")
            
        except Exception as e:
            print(f"❌ エラー: {rar} の解凍に失敗しました。")

def wait_for_download_complete(driver, timeout=300):
    """Chromeのダウンロード状態をJavaScriptで監視し、完全に終了するまで待機する"""
    print("⏳ ファイルのダウンロード完了シグナルを待機中...")
    start_time = time.time()
    
    # 新しいタブでダウンロード管理ページを開く
    driver.execute_script("window.open('chrome://downloads/', '_blank');")
    time.sleep(2)
    driver.switch_to.window(driver.window_handles[-1])
    
    try:
        while True:
            if time.time() - start_time > timeout:
                print("⚠️ 警告: タイムアウト（5分超過）したため、強制的に次に進みます。")
                break
                
            # 🟢 【修正ポイント】Chromeの内部シャドウドメインから進行中の状態を確実に配列で取得
            download_states = driver.execute_script("""
                const manager = document.querySelector('downloads-manager');
                if (manager && manager.items_) {
                    return manager.items_.map(item => item.state);
                }
                return [];
            """)
            
            # 配列の中に 'IN_PROGRESS' (ダウンロード中) が1つも無ければ完了とみなす
            if not download_states or 'IN_PROGRESS' not in download_states:
                # 拡張子 '.crdownload' (一時ファイル) がフォルダ内に残っていないかも最終確認
                download_dir = os.path.join(os.path.expanduser("~"), "Downloads")
                if os.path.exists(download_dir):
                    crdownloads = [f for f in os.listdir(download_dir) if f.endswith('.crdownload')]
                    if not crdownloads:
                        print("🎉 全ファイルのダウンロード完了シグナルを検知しました！")
                        break
                else:
                    print("🎉 ダウンロード完了シグナルを検知しました！")
                    break
                
            time.sleep(3) # 3秒ごとに進捗ループチェック
    finally:
        # ダウンロード確認タブを閉じ、元のダウンロードページに制御を戻す
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
        time.sleep(1)

def main():
    print("【全自動・完了検知＆RAR自動解凍付き】KrakenFiles 自動ダウンロード")
    print("URLを1行ずつ入力してください。終了する場合はEnterを押します。\n")
    
    kraken_urls = []
    counter = 1
    while True:
        url = input(f"url{counter}: ").strip()
        if not url:
            break
        if "krakenfiles.com" in url:
            kraken_urls.append(url)
            counter += 1

    if not kraken_urls:
        print("URLが入力されませんでした。処理を終了します。")
        return

    print(f"\n[1/2] ポップアップ・複数ダウンロード解除設定を適用して起動中...")
    
    options = uc.ChromeOptions()
    prefs = {
        "profile.default_content_setting_values.popups": 1,
        "profile.default_content_setting_values.automatic_downloads": 1
    }
    options.add_experimental_option("prefs", prefs)
    
    try:
        driver = uc.Chrome(options=options, version_main=148)
    except Exception as e:
        print(f"\n❌ ブラウザの起動に失敗しました。エラー詳細: {e}")
        return
        
    try:
        print("\n[2/2] 各リンクのダウンロード処理を開始します...")
        for i, url in enumerate(kraken_urls, 1):
            print(f"\n--- [{i}/{len(kraken_urls)}] 対象URLへ移動: {url} ---")
            driver.get(url)
            
            print("Cloudflare認証の通過を待機中...")
            time.sleep(12) 
            
            main_window = driver.current_window_handle
            success = False
            attempt = 1
            max_attempts = 8
            
            while attempt <= max_attempts and not success:
                print(f"🔄 ボタン攻略試行 [{attempt}/{max_attempts}] 回目...")
                
                try:
                    driver.execute_script("""
                        const btn = document.querySelector("button[class*='btn-primary']");
                        if (btn) {
                            btn.removeAttribute('onclick');
                            btn.removeAttribute('target');
                        }
                        const overlays = document.querySelectorAll('div, iframe, ins');
                        overlays.forEach(el => {
                            const style = window.getComputedStyle(el);
                            if ((parseInt(style.zIndex) > 10 || style.position === 'fixed' || style.position === 'absolute') 
                                && !el.contains(document.querySelector('.btn-primary'))) {
                                el.remove();
                            }
                        });
                    """)
                except:
                    pass
                
                try:
                    wait = WebDriverWait(driver, 10)
                    download_btn = wait.until(
                        EC.presence_of_element_located((By.XPATH, "//button[contains(@class, 'btn-primary')]//span[contains(@class, 'btn-text') and contains(text(), 'Download')]/ancestor::button"))
                    )
                    
                    print("➡️ ダウンロードボタンをクリックします。")
                    driver.execute_script("arguments[0].dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true, view: window}));", download_btn)
                    time.sleep(4)
                    
                    current_url = driver.current_url
                    all_windows = driver.window_handles
                    
                    if len(all_windows) > 1:
                        print("⚠️ 広告の別タブが開いたため、タブをすべて閉じます。")
                        for window in all_windows:
                            if window != main_window:
                                driver.switch_to.window(window)
                                driver.close()
                        driver.switch_to.window(main_window)
                        time.sleep(2)
                        attempt += 1
                        continue
                    
                    elif "krakenfiles.com" not in current_url:
                        print("⚠️ 元のタブが広告ページに書き換えられました。1ページ戻ります。")
                        driver.back()
                        time.sleep(5)
                        attempt += 1
                        continue
                        
                    else:
                        print("🎉 広告の妨害をすり抜け、クリックの送信に成功しました。")
                        success = True
                        
                        # 🟢 今回修正した、確実なシグナル監視システムを発火
                        wait_for_download_complete(driver)
                        
                except Exception as e:
                    print("❌ ボタンが見つからないか、エラーが発生しました。再試行します。")
                    attempt += 1
                    time.sleep(2)
                    
            if not success:
                print(f"❌ 警告: {max_attempts}回連打しましたが、ダウンロードを開始できませんでした。")
                
        print("\nすべてのURLのダウンロード工程が終了しました。")
        
        # ダウンロード完了後にRARファイルをすべて自動解凍
        extract_rar_files()
        
    finally:
        print("\n全工程が終了しました。")
        input("Enterキーを押すとブラウザを閉じます...")
        try:
            driver.quit()
        except OSError:
            pass

if __name__ == "__main__":
    main()

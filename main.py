import os
import time
import subprocess
import pyperclip  # 📋 クリップボード監視用
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def extract_downloaded_files():
    """ダウンロードフォルダ内のすべてのRARおよびZIPファイルを自動解凍する関数"""
    print("\n📦 [解凍工程] ダウンロードフォルダ内の圧縮ファイルを解凍します...")
    
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

    # 🌟 .lower() を入れて大文字の .ZIP や .RAR も確実にヒットするように修正
    target_files = [f for f in os.listdir(download_dir) if f.lower().endswith(('.rar', '.zip'))]
    
    if not target_files:
        print("📂 解凍待ちのRAR/ZIPファイルは見つかりませんでした。")
        return

    print(f"解凍ツールを検出しました: {extractor_type.upper()}")
    print(f"対象の圧縮ファイル: {len(target_files)}件")

    for file_name in target_files:
        file_path = os.path.join(download_dir, file_name)
        base_name, _ = os.path.splitext(file_name)
        output_dir = os.path.join(download_dir, base_name)
        
        print(f"🎬 解凍中: {file_name} -> フォルダ: {base_name}")
        
        try:
            # 🌟 確実にフォルダを作ってから解凍するように変更
            if not os.path.exists(output_dir):
                os.makedirs(output_dir, exist_ok=True)

            if extractor_type == "7zip":
                cmd = [extractor_path, "x", file_path, f"-o{output_dir}", "-y"]
            else:
                # WinRARのパス指定をより確実に修正
                cmd = [extractor_path, "x", "-y", file_path, output_dir]

            # エラーが出たときに原因がわかるように stdout/stderr の非表示を解除
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            print(f"✨ 解凍完了: {file_name}")
            
        except Exception as e:
            print(f"❌ エラー: {file_name} の解凍に失敗しました。")
            if hasattr(e, 'stderr') and e.stderr:
                print(f"詳細情報: {e.stderr}")

def wait_for_download_complete(driver, timeout=300):
    """Chromeのダウンロード状態をJavaScriptで監視し、完全に終了するまで待機する"""
    print("⏳ ファイルのダウンロード完了シグナルを待機中...")
    start_time = time.time()
    
    driver.execute_script("window.open('chrome://downloads/', '_blank');")
    time.sleep(2)
    driver.switch_to.window(driver.window_handles[-1])
    
    try:
        while True:
            if time.time() - start_time > timeout:
                print("⚠️ 警告: タイムアウト（5分超過）したため、強制的に次に進みます。")
                break
                
            download_states = driver.execute_script("""
                const manager = document.querySelector('downloads-manager');
                if (manager && manager.items_) {
                    return manager.items_.map(item => item.state);
                }
                return [];
            """)
            
            if not download_states or 'IN_PROGRESS' not in download_states:
                download_dir = os.path.join(os.path.expanduser("~"), "Downloads")
                if os.path.exists(download_dir):
                    crdownloads = [f for f in os.listdir(download_dir) if f.endswith('.crdownload')]
                    if not crdownloads:
                        print("🎉 全ファイルのダウンロード完了シグナルを検知しました！")
                        break
                else:
                    print("🎉 ダウンロード完了シグナルを検知しました！")
                    break
                
            time.sleep(3)
    finally:
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
        time.sleep(1)

def get_urls_from_clipboard():
    """📋 クリップボードを監視してURLを自動収集する関数"""
    print("\n📋 クリップボード監視モード起動！")
    print("KrakenFilesのリンクを「コピー」すると自動でリストに入ります。")
    print("終了してダウンロードを始めるには、テキストで「done」とコピーしてね。\n")
    
    collected_urls = []
    last_clipboard = ""
    
    try:
        while True:
            current_clipboard = pyperclip.paste().strip()
            
            if current_clipboard and current_clipboard != last_clipboard:
                if "krakenfiles.com" in current_clipboard:
                    if current_clipboard not in collected_urls:
                        print(f"✅ 追加: {current_clipboard}")
                        collected_urls.append(current_clipboard)
                elif current_clipboard.lower() == "done":
                    print("🛑 監視終了！ダウンロード処理へGO！")
                    break
                
                last_clipboard = current_clipboard
            
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 監視中断！ダウンロード処理へGO！")
        
    return collected_urls

def main():
    print("【全自動・完了検知＆RAR/ZIP自動解凍付き】KrakenFiles 自動ダウンロード")
    
    kraken_urls = get_urls_from_clipboard()

    if not kraken_urls:
        print("URLが一つも追加されなかったため終了します👋")
        return

    print(f"\n[1/2] ポップアップ・危険ファイル警告解除設定を適用して起動中...")
    
    options = uc.ChromeOptions()
    
    prefs = {
        "profile.default_content_setting_values.popups": 1,
        "profile.default_content_setting_values.automatic_downloads": 1,
        "safebrowsing.enabled": True,
        "safebrowsing.protection_level": 0,
        "download.directory_upgrade": True,
        "download.prompt_for_download": False
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
                        wait_for_download_complete(driver)
                        
                except Exception as e:
                    print("❌ ボタンが見つからないか、エラーが発生しました。再試行します。")
                    attempt += 1
                    time.sleep(2)
                    
            if not success:
                print(f"❌ 警告: {max_attempts}回連打しましたが、ダウンロードを開始できませんでした。")
                
        print("\nすべてのURLのダウンロード工程が終了しました。")
        extract_downloaded_files()
        
    finally:
        print("\n全工程が終了しました。")
        input("Enterキーを押すとブラウザを閉じます...")
        try:
            driver.quit()
        except OSError:
            pass

        os._exit(0)

if __name__ == "__main__":
    main()

- 透過 AWS Systems Manager (SSM) 進入機器，
    1. 進入 AWS Console
    2. 前往 AWS Systems Manager > Session Manager
    3. 選擇該 EC2 並啟動 Session
    4. 成功進入後，檢查系統日誌查找問題原因

- 透過 EC2 Serial Console 進入，若 SSM 無法存取，可以使用 EC2 Serial Console (類似雲端上的 KVM)：
    1. AWS Console > EC2 > 選擇該機器
    2. 點擊 Actions > Monitor and troubleshoot > Serial console
    3. 嘗試登入 root，檢查系統日誌查找問題原因

- 建立 Recovery 機器，掛載 Volume 進行修復
    1. 建立新的 EC2
    2. 停止原 EC2，分離 (Detach) 它的 Volume
    3. 將 Volume 附加 (Attach) 到新的 EC2
    4. 掛載 Volume 並檢查系統日誌找出可能發生問題的原因
    5. 修復後卸載 Volume，重新附加回原 EC2，並啟動

#### 問題發生可能原因
- SSH 設定異常
- 磁碟空間用完
- CPU / 記憶體資源耗盡
- 系統更新導致異常
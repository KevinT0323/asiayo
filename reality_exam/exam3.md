- 透過 Session Manager 進入機器，
    1. 進入 AWS Console > EC2 > 選擇該機器 > 點擊 Connect
    2. 點擊 Session Manager
    3. 成功進入後，檢查系統日誌查找問題原因

- 若 SSM 無法存取，可以使用 EC2 Serial Console (類似雲端上的 KVM)：
    1. AWS Console > EC2 > 選擇該機器 > 點擊 Connect
    2. 點擊 EC2 serial console
    3. 嘗試登入 root，檢查系統日誌查找問題原因

- 建立 Recovery 機器，掛載 Volume 進行修復
    1. 建立新的 EC2 (使用全新Volume)
    2. 停止原 EC2，分離它的 Volume
    3. 將 Volume 附加到新的 EC2
    4. 掛載 Volume 並檢查系統日誌找出可能發生問題的原因
        - 查看磁碟分區: `lsblk`
        - 掛載故障磁碟: `sudo mount /dev/sdb1 /mnt && sudo mount --bind /dev /mnt/dev && sudo mount --bind /proc /mnt/proc && sudo mount --bind /sys /mnt/sys`
        - 切換到舊 VM 的環境: `sudo chroot /mnt`
        - 排查問題
        - 離開 chroot，並卸載磁碟: `exit && sudo umount /mnt/dev /mnt/proc /mnt/sys && sudo umount /mnt`
    5. 重新附加回原 EC2 並啟動

#### 問題發生可能原因
- SSH 設定異常
- 磁碟空間用完
- CPU/記憶體資源耗盡
- 系統更新導致異常
# App Review Notes

## Reviewer Notes

國樂團練習室是一款離線國樂教育 App。App 內容、樂器插圖與樂器聲音樣本皆為本專案原創生成，不包含第三方授權圖片或第三方音訊。

App 不需要登入，不收集個人資料，不使用廣告 SDK，不使用第三方分析 SDK。學習進度、收藏與測驗紀錄僅透過 UserDefaults 儲存在使用者裝置本機。

Pro 付費功能使用 Apple StoreKit：

- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Type: Non-Consumable
- Unlock name: 國樂團練習室 Pro

若審查環境尚未載入商品，App 會顯示「尚未連到 App Store Connect 商品」並保留恢復購買入口，不會閃退或阻擋免費內容。

## Demo Flow

1. 開啟 App 後進入「總覽」。
2. 點選「樂器」查看 23 件樂器原創插圖。
3. 任選樂器，點選「試聽離線聲音」。
4. 回到「練功」，查看課程、測驗與 Pro 進階訓練預覽。
5. 前往「Pro」頁查看 StoreKit 解鎖入口與恢復購買。

## Contact

- Team: Yu Shiung Jiang
- Contact: Yu Shiung Jiang
- Email: jushiung@gmail.com
- Phone: +886952413678

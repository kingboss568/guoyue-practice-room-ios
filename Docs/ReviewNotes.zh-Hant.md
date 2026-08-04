# App Review Notes

## Reviewer Notes

國樂團練習室是一款離線國樂教育與練習 App。新版只顯示具可稽核來源與商用授權的真實樂器照片及實器錄音；未完成的項目會明確停用，不以 AI、合成音或相近樂器替代。

App 不需要登入，不收集個人資料，不使用廣告 SDK，不使用第三方分析 SDK。學習進度、收藏與測驗紀錄僅透過 UserDefaults 儲存在使用者裝置本機。

Pro 付費功能使用 Apple StoreKit：

- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Type: Non-Consumable
- Unlock name: 國樂團練習室 Pro

若審查環境尚未載入商品，App 會顯示「尚未連到 App Store Connect 商品」並保留恢復購買入口，不會閃退或阻擋免費內容。

App Store Connect 已確認 `com.yuhsiangjiang.GuoYueZhiPu.pro` 為非消耗性項目且已有價格排程。正確繁中 localization、付款頁審查截圖與 IAP 已和 App `1.1 (2)` 一起加入 submission `e206011f-7c63-4729-9070-a112a91178f2`，目前兩項均為 `WAITING_FOR_REVIEW`。

## Demo Flow

1. 開啟 App 後進入「總覽」。
2. 點選「樂器」查看 23 件樂器圖鑑。
3. 任選已核准音源的樂器，點選「試聽已授權實器片段」；未核准樂器會顯示「實器錄音待取得授權」。
4. 回到「練功」，實際完成樂器 5 題、基礎 20 題與實器聽辨 5 題免費試用。
5. 前往「Pro」頁查看 StoreKit 解鎖入口與恢復購買。

## Contact

- Team: Yu Shiung Jiang
- Contact: Yu Shiung Jiang
- Email: jushiung@gmail.com
- Phone: +886952413678

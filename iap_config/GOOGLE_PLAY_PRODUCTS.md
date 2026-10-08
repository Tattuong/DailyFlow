# Google Play IAP — DailyFlow

Package: `com.DailyFlowMNG.DailyFlow`

Remote config: `https://api2.blwsmartware.net/N304.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `df_pack_1` | 50 |
| `df_pack_2` | 100 |
| `df_pack_3` | 200 |
| `df_pack_4` | 350 |
| `df_pack_5` | 500 |
| `df_pack_6` | 750 |
| `df_pack_7` | 1000 |
| `df_pack_8` | 1500 |
| `df_pack_9` | 2200 |
| `df_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `df_remove_ads` | Hide the banner |
| `df_pro` | More than 8 custom routines |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.

# Progression, persistence and monetization

Preserve XP, shards, cores, form IDs0–3, path IDs vanguard/strider/arcanist, clear IDs verdant_warden/ember_warden/astral_warden, ownership and legacy balances. Same datastore name/key. Schema3 adds Loadout, Customization, Settings and RewardHistory with validated defaults and bounded values. Schema1/2 decode additively; unknown future schemas still refuse writable load. No balance reset or conversion to purchasable power.

Relic blade is guaranteed via the default loadout, never a random/paid unlock. The introductory unlock presentation is still pending. Existing upgrade/evolution/path operations are reused server-side; paths remain freely changeable once earned. Current signature UI exposes only a subset of forge operations, not a full inventory/shop.

RewardLedger mutates grant and recent encounter IDs together in the profile snapshot (max64). It prevents retries within retained history, not arbitrary historical exactly-once guarantees. GUID-prefixed encounter IDs prevent different servers reusing enc_1. DataService still owns leases, load refusal, save retry and shutdown serialization. Save-pending feedback does not claim durable success; live service fault tests remain required.

Monetization boundary: permanent cosmetic passes only. No shards sold because shards buy combat upgrades. No paid resets, premium currency, combat power or consumable developer products. Existing purchases stay disabled. Before enabling cosmetics, implement actual pass ownership states, preview/equip/confirmation/cancel/failure feedback, service receipt/ownership checks appropriate to passes, and private-universe tests. No purchase or pricing has been published.

Christian reading is entirely optional, free, unrewarded, untracked and independent of completion. It is local text, not a request/action, achievement or profile field. Content classification/theological review from existing launch requirements remains unresolved.

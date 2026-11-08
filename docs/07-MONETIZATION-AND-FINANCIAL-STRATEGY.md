# Ethical commercial strategy

## Verified platform facts and boundaries
Reviewed November 7, 2026. [Official DevEx guidance](https://create.roblox.com/docs/production/monetization/developer-exchange) lists a standard rate of USD 0.0038 per eligible Earned Robux, a 30,000 Earned Robux minimum, age 13+, verified email, DevEx portal, applicable tax forms and good standing. Roblox decides eligibility; account country, payout support, taxes and legal eligibility must be checked for the owner. Certain qualifying U.S. age-checked adult spending has a higher rate of 0.0054; this model uses only the standard rate. Purchased Robux are not equivalent to eligible Earned Robux. Gross Robux sales are not USD revenue.

[Official earning guidance](https://create.roblox.com/docs/get-started/monetization) describes a typical 70% in-experience Robux creator share; verify actual transaction treatment, refunds and pending earnings in the dashboard. Different products/channels can differ. [Creator Rewards](https://create.roblox.com/docs/creator-rewards) is a separate program; forecast zero until actual eligibility and earnings are verified. Do not rely on legacy Premium payout assumptions.

## Offer design
Earned colors are available to everyone. A future permanent Harbor Supporter cosmetic pass adds an ocean-blue lantern trim, with no reward multiplier, capacity increase, rank, religious access or gameplay restriction. Price hypothesis: 99–149 Robux, subject to actual value testing. The native Roblox purchase prompt supplies the live regional price; do not claim a fixed price in custom UI. In code the pass ID is zero, so purchases are disabled. Optional cosmetic packs may follow after art quality and repeat demand are established.

No paid random items, paid revives, currency sales, consumables, advertisements, subscriptions or private-server charges are implemented. Recurring subscriptions do not yet offer enough recurring value. Developer products would add receipt/retry obligations without serving the current game. Religious material is always free and unrewarded. No scarcity claims, spending nudges after failure, child-directed pressure or auto-prompt purchases.

## Transparent monthly scenarios (assumptions, not forecasts)
MAU counts distinct monthly active players; payer conversion is distinct monthly payers / MAU. ARPPU is gross Robux spent per monthly payer. Net Earned Robux assumption = MAU × conversion × gross ARPPU × 0.70. USD equivalent = eligible net Earned Robux × 0.0038, before taxes, adjustments and payout restrictions.

| Scenario | MAU | Conversion | Gross ARPPU | Gross Robux | Net Robux | USD equivalent | Operating cost | Operating result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Conservative | 5,000 | 0.5% | 100 | 2,500 | 1,750 | $6.65 | $600 | -$593.35 |
| Base | 50,000 | 1.5% | 150 | 112,500 | 78,750 | $299.25 | $1,200 | -$900.75 |
| Optimistic | 250,000 | 3% | 250 | 1,875,000 | 1,312,500 | $4,987.50 | $3,000 | $1,987.50 |

Conservative monthly earnings are below the DevEx minimum and not immediately cashable; qualifying balances may accumulate. These scenarios do not demonstrate a viable business. At base conversion/ARPPU, USD per MAU = $0.005985. $1,200 monthly break-even requires about 200,502 MAU, excluding startup recovery and tax. Reducing costs or increasing fair cosmetic value matters as much as acquisition. A permanent single pass cannot sustain repeated ARPPU indefinitely: the table is a portfolio-level hypothesis contingent on later cosmetic content; it overstates mature revenue if no further offers are built.

Startup cash assumptions: 160–320 engineering hours × $40–$75 = $6,400–$24,000 opportunity/labor cost; $1,000–$4,000 commissioned art/audio; $300–$1,000 QA/accessibility; $200–$1,000 exploratory promotion. Total $7,900–$30,000. No money is spent or committed by this document. Cloud tools may create additional subscription costs, not measured here.

Monthly assumptions include 15–40 maintenance/content hours, modest art/audio replacements and limited promotion; Roblox hosts game servers/storage within its platform arrangements, while creator labor remains a real expense. Base cost allocation: $900 labor + $150 art/audio + $150 research/promotion. Optimistic cost includes expanded content/support. Owner unpaid time is still cost. At optimistic operating margin, recouping $15,000 takes roughly 7.6 months if all assumptions hold; base case never recoups it.

Acquisition: prioritize qualified organic testers. Paid CAC is unknown; at base monthly revenue per MAU, a $0.10 paid acquisition cost needs many active player-months to recover. Budget zero paid scaling until cohort LTV exceeds measured CAC with margin. Risk: discovery volatility, ratings narrowing audience, content treadmill, refunds, FX, low cosmetic conversion and one-time-pass saturation.

## Measurements and decision rules
Use Creator Dashboard DAU/MAU, D1/D7/D30 cohorts, session duration, acquisition channel, conversion and ARPPU. Custom server events: first contribution, repair completed; no religion-related instrumentation. Analyze event counts alongside independent user/session denominators, avoid counting repeated repairs as unique users. Track save failures and engine performance during controlled tests. Define retention by distinct cohort users returning on the specified day; report sample sizes and channel mix. Stated purchase intent is not a sale. Do not use player-level religious segmentation or export minors’ personal information.

No profitability guarantee. Continue only as audience evidence and measured economics justify investment.

# MapAnytime — Promotions, Discounts, Vouchers, Points Rewards & Merchant Ads
## Stakeholder Technical Overview · September 2026

---

## 1. Executive Summary

MapAnytime implements five interconnected buyer-engagement features across two codebases:

| Feature | Where Implemented | Status |
|---|---|---|
| **Merchant Ads / Promos** | API `merchantAds` module + Flutter `worldMap` | Live |
| **Discounts** | API `orders/pricing.util` + `merchantAds` | Live |
| **Vouchers** | API `rewards` module + Flutter `rewards` feature | Live |
| **Points Rewards (MapPoints)** | API `rewards` module + Flutter `rewards` feature | Live |
| **Pricing Engine** | API `pricing` module | Live |

All five features are connected at the order checkout transaction — a single database transaction that applies item discounts from active ads, validates and spends any MapPoints voucher, calculates the final price, and awards points on completion.

---

## 2. Merchant Ads

### 2.1 What They Are

Merchant Ads are seller-created promotions that appear on the MapAnytime map and in the discovery feed. A seller can run three types of ads (`MERCHANTADKIND`):

| Kind | Purpose |
|---|---|
| `PROMO` | Product discount or deal (BOGO, % off, fixed ₱ off) |
| `JOB` | Job listing attached to a store |
| `EVENT` | Time-limited event with a linked product |

### 2.2 Ad Schema (Key Fields)

```
MerchantAds
├── kind            PROMO | JOB | EVENT
├── title / description / imageUrl
├── badgeLabel      e.g. "Flash Sale", "Hot Deal" (from PromotionBadges presets or custom)
├── ctaLabel        Call-to-action button label
├── discountType    BOGO | PERCENTAGE | FIXED_AMOUNT
├── discountValue   numeric — % or ₱ depending on type
├── buyQuantity     for BOGO: "buy N..."
├── freeQuantity    for BOGO: "...get M free"
├── startAt / expiresAt   half-open schedule window [start, end)
├── isActive        pause/resume toggle
├── goal            STORE_VISITS | IMPRESSIONS | PURCHASES
├── format          MAP_FLOATING_CARD | PROMOTED_PIN | DISCOVERY_CAROUSEL | SPONSORED_SEARCH
├── radiusKm        geographic targeting radius
├── dailyBudget / totalBudget   ad spend budget (future billing)
└── products[]      specific products/variants the ad applies to
```

### 2.3 Ad Lifecycle (Window States)

Ad liveness is **derived at read time** — never stored as a status flag. This means it is always accurate to the millisecond and cannot become stale.

```
          isActive=false and startAt in future
                    │
           [SCHEDULED] ──────────────────────────┐
                    │  startAt reached            │ toggled off
                    ▼                             ▼
              [LIVE] ──────── toggled off ──── [PAUSED]
                    │                             │
                    │ expiresAt reached            │ expiresAt reached
                    ▼                             ▼
                 [ENDED] ◄────────────────────────┘
```

The `deriveAdState()` function in `adWindow.ts` implements this. It is mirrored exactly in the Prisma `liveWindowFilter()` query filter so the in-memory and SQL evaluations always agree.

### 2.4 Conflict Prevention

Two PROMO-type ads with a `discountType` that target the same product cannot have overlapping time windows. The API enforces this at create and update time via `assertNoWindowConflict()`. This prevents two competing prices from being applied to the same product at the same instant.

### 2.5 Buyer-Facing Discovery

```
GET /merchant-ads/nearby?north=&south=&east=&west=
```

Returns live ads from stores within the map viewport, enriched with store name, distance, discount details, and product image. No authentication required — this is the public discovery feed.

### 2.6 Analytics & Performance Tracking

Each ad tracks three event types: `IMPRESSION`, `CLICK`, `CONVERSION`. A conversion event reads attributed revenue from the actual completed order (not from the request payload) to prevent manipulation. Aggregated counters — impressions, clicks, conversions, ROAS (return on ad spend), CTR — are available to the seller at `GET /merchant-ads/:id/analytics`.

### 2.7 Promotion Badges

Sellers can attach a badge to an ad (e.g. "Flash Sale", "Hot Deal", "Sale Now") from an admin-curated preset list (`PromotionBadges`), or enter a custom label. The badge label is denormalized onto the ad row at selection time so buyer-facing reads never need a join.

### 2.8 Transition Notifications

A background worker runs `processWindowTransitions()` periodically. When an ad moves from `SCHEDULED → LIVE` or `LIVE → ENDED`, it publishes a `ad.window.transitioned` event via RabbitMQ. The API process consumes this and pushes a real-time Socket.IO notification to the seller and a map-refresh signal to connected buyers.

---

## 3. Discounts

### 3.1 Item-Level Discounts (Merchant Ad Discounts)

Discounts are applied **per order item** at checkout, not to the order total. The function `computeItemDiscount()` in `orders/pricing.util.ts` looks up live PROMO ads linked to each product in the order and picks the **best discount** for the buyer.

Three discount modes are supported:

| `discountType` | How It Works | Example |
|---|---|---|
| `PERCENTAGE` | `itemTotal × discountValue%` | 20% off ₱500 item = ₱100 off |
| `FIXED_AMOUNT` | `discountValue × quantity`, capped at item total | ₱50 off, qty 3 = ₱150 off |
| `BOGO` | `floor(qty / (buyQty + freeQty)) × freeQty × unitPrice` | Buy 2 Get 1 Free: 3 items → 1 free |

The winning ad's ID is stored on the `OrderItems.appliedAdId` column, creating a permanent audit trail linking every discounted item to the specific promotion that caused it.

### 3.2 Discount vs. Voucher — A Critical Distinction

The system deliberately separates two kinds of buyer savings:

| | Merchant Ad Discount | MapPoints Voucher |
|---|---|---|
| **Who funds it** | Seller | Platform (MapAnytime absorbs it) |
| **Applied to** | `Orders.discountAmount` | `Orders.voucherAmount` (separate column) |
| **Affects seller commission?** | Yes — commission is charged on `subtotal - discount` | No — seller is paid in full regardless |
| **Order charge type** | `DISCOUNT` (payer: SELLER) | `PLATFORM_SUBSIDY` (payer: PLATFORM) |

This separation means a MapPoints redemption never reduces the seller's net payout.

### 3.3 Seller Commission on Discounts

Commission is charged on the **discounted subtotal** (`subtotal - discountAmount`), not the gross. A seller running a 20% promotion pays commission only on the money they actually received, not on the portion they gave away. This was corrected in FLAGS.md F4 (2026-08-20).

---

## 4. Vouchers (MapPoints Vouchers)

### 4.1 Overview

Vouchers are discount instruments that buyers purchase from the **Voucher Catalog** using MapPoints. They are not free — they represent a conversion of loyalty points into redeemable cart discounts.

### 4.2 Voucher Catalog (Admin-Curated)

Admins create and manage vouchers via:
```
POST   /rewards/admin/vouchers    — create a voucher
PATCH  /rewards/admin/vouchers/:id — update (toggle active, change value, etc.)
GET    /rewards/admin/vouchers    — list all (including inactive/sold-out)
```

Each `RewardVoucher` has:

```
RewardVouchers
├── title / description
├── pointCost         how many MapPoints to claim it
├── discountType      FIXED | PERCENTAGE
├── discountValue     ₱ off (FIXED) or % off (PERCENTAGE)
├── minOrderAmount    minimum cart subtotal to apply it
├── maxDiscountAmount cap on a PERCENTAGE voucher's peso value
├── validityDays      days from claim to expiry (default: 30)
└── totalStock        null = unlimited; otherwise a hard claim cap
```

### 4.3 Claiming a Voucher

Buyers claim vouchers from the catalog at `POST /rewards/vouchers/:id/claim`.

The claim is atomic and race-safe:
1. The wallet decrement uses a conditional `UPDATE WHERE balance >= pointCost` — two concurrent claims against a wallet that can only afford one will result in exactly one winner; the other receives "Insufficient MapPoints balance."
2. Stock enforcement uses an optimistic increment — sufficient for typical catalog volumes.
3. A `UserVouchers` row is created with `status = ACTIVE` and an `expiresAt` date (`claimedAt + validityDays`).
4. A `RewardTransactions` row of type `SPEND` records the point deduction.

### 4.4 Redeeming a Voucher at Checkout

A buyer passes their `userVoucherId` when placing an order. The order creation flow:

1. **Validates** the voucher (`validateVoucherForOrder`): checks ownership, `ACTIVE` status, expiry, and minimum order amount.
2. **Calculates** the discount amount based on `discountType` and `discountValue`.
3. **Marks** the voucher `USED` inside the same database transaction as order creation (`markVoucherUsed`). This is a conditional `updateMany WHERE status = ACTIVE`, so two simultaneous checkout attempts with the same voucher result in a 409 for the second.
4. The discount reduces `buyerTotalAmount` but **not** `sellerNetAmount`.

### 4.5 Voucher States

```
ACTIVE   → USED     (applied at checkout)
ACTIVE   → EXPIRED  (expiresAt passed; swept by scheduler)
```

### 4.6 Flutter UI

The `RewardsPage` in the Flutter app (`lib/features/rewards/presentation/pages/rewards_page.dart`) presents three tabs:

| Tab | Content |
|---|---|
| **Catalog** | Active, in-stock vouchers — shows point cost, discount value, claim button (disabled if balance insufficient) |
| **My Vouchers** | All claimed vouchers with their status (ACTIVE, USED, EXPIRED) |
| **History** | Full MapPoints ledger (EARN, SPEND, EXPIRED, BONUS, etc.) |

The wallet balance header displays current points and their estimated peso value (`balance × ₱0.10`).

---

## 5. Points Rewards (MapPoints)

### 5.1 The Loyalty Wallet

Every buyer has a `RewardWallet` with:
- `balance` — current spendable points
- `lifetimeEarned` — all-time total earned
- `lifetimeSpent` — all-time total spent on vouchers

The wallet is created automatically on first access (lazy initialization).

### 5.2 Earning Points

Points are awarded **automatically** when an order is completed (payment confirmed). The earn call is inside the same database transaction as order completion — a phantom credit from a payment that later fails is impossible.

**Formula:**
```
eligibleBase  = max(0, subtotalAmount - discountAmount)
pointsValuePhp = eligibleBase × earnPercentage   (default: 0.1% = 0.001)
points         = round(pointsValuePhp / pointValueInPhp)   (default: ₱0.10/pt)
```

At the defaults: spending ₱1,000 earns 10 points worth ₱1.00. The earn is proportional (no minimum-spend cliff) and idempotent per order — a retried completion cannot double-credit.

**What is excluded from the earn base:**
- Buyer transaction fees (payment gateway charges)
- Platform fees
- Voucher discounts (a MapPoints redemption does not reduce future earning)
- Merchant ad discounts are subtracted (`subtotal - discountAmount`)

### 5.3 Earn Rate Configuration

The earn rate is admin-editable at runtime via:
```
PATCH /rewards/admin/config
  { earnPercentage, pointValueInPhp, expirationMonths, isEarningActive }
```

Configurations are versioned (`RewardConfigurations` table). Each new config creates a new row and archives the previous one. The currently active config is the one with the highest version and `isActive = true`. If no config row exists, the engine falls back to built-in defaults (0.1% earn, ₱0.10/point, 12-month expiry) and logs a warning.

### 5.4 Point Expiration

Each `EARN` transaction carries an `expiresAt` timestamp (`claimedAt + expirationMonths`). A scheduled job runs `expireOldPoints()`:
- Finds all EARN rows past their `expiresAt` without a corresponding `EXPIRED` offset row
- Decrements the wallet balance by the lesser of the lot size and the current balance
- Creates an `EXPIRED` transaction row (idempotent — skips lots already offset)

A separate job runs `expireStaleVouchers()` to flip `ACTIVE` vouchers with a past `expiresAt` to `EXPIRED`.

### 5.5 Transaction Types

| Type | Meaning |
|---|---|
| `EARN` | Points credited from a completed order |
| `SPEND` | Points debited when a voucher is claimed |
| `EXPIRED` | Points removed by the expiry job |
| `BONUS` | Admin-granted bonus points |
| `REFUND` | Points returned on order refund |
| `REVERSAL` | Correction of a prior transaction |
| `ADJUSTMENT` | Manual admin correction |

### 5.6 Public Config Endpoint

A display-safe subset of the earn rate is exposed to the Flutter app at `GET /rewards/config` (buyer-authenticated, no admin fields). This allows the checkout screen to show "You'll earn ~N points on this order" as a live estimate.

---

## 6. Pricing Engine

### 6.1 Role in the System

The Pricing Engine (`pricing-engine.service.ts`) is the single source of truth for all order financial calculations. It is called once per order at checkout and produces the complete financial breakdown.

### 6.2 What It Calculates

```
Inputs:
  subtotalAmount      — sum of item prices × quantities
  discountAmount      — sum of item-level merchant ad discounts
  voucherAmount       — MapPoints voucher redemption (kept separate!)
  paymentMethod       — determines gateway fee rate
  storeId/sellerId    — determines commission rate

Outputs:
  orderAmount         = subtotal - discount - voucher
  paymentProcessingCost  gateway fee (varies by provider/method)
  buyerPlatformFee    currently ₱0 by policy decision
  buyerTransactionFee = gateway fee share based on payer policy
  buyerTotalAmount    = orderAmount + buyerTransactionFee
  sellerMarketplaceCommission  2% of (subtotal - discount)
  sellerNetAmount     = subtotal - discount - commission [- gateway if SELLER policy]
  platformGrossRevenue / platformNetRevenue
```

### 6.3 Payment Fee Payer Policies

Who pays the gateway fee is configurable:

| Policy | Buyer Pays | Seller Pays | Platform Pays |
|---|---|---|---|
| `BUYER` | 100% | — | — |
| `SELLER` | — | 100% | — |
| `PLATFORM` | — | — | 100% |
| `SHARED` | 50% | 50% | — |

### 6.4 Configuration

Pricing configurations are versioned (`PricingConfigurations` table) with component rows for each fee type. A configuration must be **validated** before it can be activated — the validation catches negative rates, implausible values (e.g. `2` instead of `0.02`), missing gateway components, and expired windows.

---

## 7. How the Features Connect at Checkout

The following happens in a **single atomic database transaction** when a buyer places an order:

```
1. For each cart item:
   └─ computeItemDiscount()
      └─ Find live PROMO ads for this product in this store
      └─ Pick the best discount (highest ₱ off)
      └─ Store appliedAdId on the OrderItem

2. Sum discounts → totalDiscount

3. If userVoucherId provided:
   └─ validateVoucherForOrder()
      ├─ Check ownership, ACTIVE status, expiry, minimum order
      └─ Calculate voucherAmount (FIXED or PERCENTAGE)

4. PricingEngine.calculateOrderPricing()
   ├─ orderAmount = subtotal - discount - voucher
   ├─ Gateway fee (provider-specific rate)
   ├─ Commission = 2% × (subtotal - discount)   ← voucher does NOT reduce this
   └─ buyerTotalAmount, sellerNetAmount, platform revenue

5. Create Order row with all amounts snapshotted

6. markVoucherUsed()   ← conditional, race-safe

7. [On payment completion, separate call:]
   └─ awardPointsForCompletedOrder()
      └─ earn base = subtotal - discount   ← voucher does NOT reduce earn base
```

---

## 8. Admin Controls Summary

| Capability | Endpoint | Who |
|---|---|---|
| Create/update vouchers | `POST/PATCH /rewards/admin/vouchers` | Admin |
| Set earn rate & expiry | `PATCH /rewards/admin/config` | Admin |
| Toggle earning on/off | `PATCH /rewards/admin/config { isEarningActive }` | Admin |
| Create/update/delete ads | `POST/PUT/DELETE /merchant-ads/` | Seller (own stores only) |
| Pause/resume an ad | `PATCH /merchant-ads/:id` | Seller |
| View ad analytics | `GET /merchant-ads/:id/analytics` | Seller |
| Activate pricing config | `POST /pricing/:id/activate` (validates first) | Admin |
| List/manage promotion badges | seeded in DB, surfaced via `GET /merchant-ads/badges` | Admin (DB) |

---

## 9. Current Limitations & Known Gaps

| Area | Limitation | Notes |
|---|---|---|
| **Voucher stock** | Optimistic increment, not a hard SQL constraint | Acceptable for typical catalog volumes; noted in code (OPEN-FLAGS F49) |
| **Point expiry** | Whole-lot expiry, not FIFO partial | Spec-intentional at 0.1% earn rate; cap is "effectively unreachable" in practice |
| **Ad budget billing** | `dailyBudget`/`totalBudget` fields stored, not yet enforced | Billing deduction against `spentAmount` is a planned next step |
| **Ad formats** | `MAP_FLOATING_CARD`, `PROMOTED_PIN`, etc. are stored but not yet differentiated in rendering | Schema is ready; display logic is pending |
| **Seller campaign incentives** | Spec describes a `SellerCampaign` ledger (F63) | Not yet implemented; only buyer rewards are live |
| **Agent commissions** | Described in architecture spec | Not yet implemented |
| **MapPoints 20% redemption cap** | In spec but not enforced in current `validateVoucherForOrder` | At 0.1% earn rate this is practically unreachable; cap is a future safety rail |

---

## 10. Data Flow Diagram

```
Buyer Places Order
        │
        ├─► computeItemDiscount() ──► reads live MerchantAds
        │        │
        │        └─► itemDiscount + appliedAdId per item
        │
        ├─► validateVoucherForOrder() [optional]
        │        │
        │        └─► voucherAmount (funded by Platform)
        │
        ├─► PricingEngine.calculateOrderPricing()
        │        │
        │        └─► buyerTotalAmount / sellerNetAmount / commission
        │
        ├─► Orders row created (all amounts snapshotted)
        │
        ├─► markVoucherUsed() [if voucher used]
        │
        └─► [On completion] awardPointsForCompletedOrder()
                 │
                 └─► RewardWallet.balance += points
                     RewardTransactions EARN row created
```

---

*Document generated from source code review of `mapanytime-api` and `mapanytime-market-app` as of September 2, 2026.*

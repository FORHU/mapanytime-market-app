# 📋 Pick up here — Flutter app

_Written end of session, 2026-08-22. Continue from here._

## 🔍 Review session, 2026-08-23 — pre-commit sweep, all three repos

Ran independent code review across the full uncommitted diff in all three
repos before committing. Cross-checked against the findings already listed
below — most were already known and are just confirmed here. **New** items
not previously flagged, in commit-relevance order:

**Fixed during this pass:**

- **`mapanytime-api/src/modules/wishlists/wishlist.service.ts:74`** — the
  `item.product.productImages` unguarded access wasn't just a theoretical
  FIXME, it was an **actively failing test**
  (`tests/unit/wishlist.service.test.ts`, "counts the saved items"). Fixed
  with `item.product?.productImages ?? []`; suite is green again (9/9).
- **`mapanytime-api/src/modules/orders/order.service.ts` `cancelOrder`
  (~line 494–640)** — the S3 refund fix moved a live PayMongo
  `refundPayment()` call in between the status read/validate step and the
  final `prisma.$transaction` status write, with no re-validation on that
  final write. A seller completing the order while a buyer's refund was in
  flight could force it back to `CANCELLED`/`REFUNDED` after it was already
  `COMPLETED` and settled. Fixed: the final transaction now re-fetches the
  order and re-runs `validateOrderTransition` against the *current* status
  before writing; if the order moved to a terminal state in the meantime it
  aborts with a clear "reconcile manually" error instead of silently
  overwriting. Note this doesn't auto-reverse a refund that already
  succeeded at the provider in that narrow window — that still needs manual
  reconciliation, same as the existing "no provider reference" case just
  above it. `tsc` clean, full unit suite green (336/336).
- **`mapanytime-market-web` finance page** (`src/app/seller/finance/page.tsx` →
  `useSellerEarnings.ts` → `finance.client.ts`) — was calling admin-only
  `/settlements/seller/:id` and `/payouts/seller/:id`, 403ing for every real
  seller and silently rendering as an empty account. Switched to the
  seller-scoped `/settlements/me` and `/payouts/me` endpoints (no id needed,
  server resolves it from the auth token), and added an `isError` state so a
  failed fetch now shows "Couldn't load your earnings" instead of "No
  settlements yet." `tsc --noEmit` clean.

**New findings, flagged only (not fixed):**
- **`lib/features/wishlist/domain/entities/wishlist_item.dart:20`** —
  `WishlistItem.fromJson` maps the nested `product` through
  `StoreProduct.fromJson`, but the wishlist API only selects
  id/name/price/brand/isActive/ratingAverage/ratingCount/storeId/productImages
  — no `category`, `store`/storeName, or `description`. Every card on the
  Saved page silently shows category "Other", store "Store", and an empty
  description regardless of the product's real values.
- **`notification_feed_controller.dart:126,134`** — `markAllRead()` lost
  its `unreadCount == 0` early return on the network call (only skips the
  local state write now), so it fires a `PATCH /notifications/read-all` on
  *every* feed-screen open, not just when there's something to clear. Minor
  waste, compounds the already-known race noted below in "Other findings."
- **`app_notification.dart:40`** — new `isUnread` getter (backed by the new
  `readAt` field) is never read anywhere in the feed UI — tiles render
  identically regardless of read state. Either wire it in or hold off
  claiming the read/unread feature is done.
- No unit tests were added for the new wishlist controller/datasource or
  the notification history-backfill merge logic — regressions in optimistic
  add/remove rollback or the socket/history merge would only surface
  manually.
- **`lib/features/home/presentation/pages/home_page.dart:298`** — the
  `StoreProduct` built for the wishlist `add()` call duplicates the one
  built for `onTap` navigation, and the two have already diverged:
  `p.storeId ?? ''` here vs. `p.storeId!` in `onTap` (self-flagged with an
  inline `TODO` in the diff). Worth extracting into one shared helper
  before the two silently disagree about which products are store-less.

**mapanytime-market-web — new findings** (this repo has no equivalent
pickup doc right now; logging here since it's the cross-repo convention):

- **`src/features/store-profile/components/StoreProfileSettings.tsx:6`** —
  `X` and `Plus` imported from `lucide-react` are now unused after the
  hardcoded "Subcategories" chip block was deleted (file even has its own
  `// FIXME` about it). Will fail `eslint`'s `no-unused-vars` — drop the two
  identifiers.
- **`src/features/seller-catalog/components/CategoryFilterSelect.tsx:466-502`**
  — two smaller items: the `groups` memo is defeated whenever the caller
  passes a fresh `categoryTree ?? []` literal during the loading window
  (cheap today, easy to copy somewhere costlier); `flattenDescendants` has
  no depth/cycle guard against a malformed recursive API response.
- **`src/features/finance/api/finance.client.ts` + `useSellerEarnings.ts`**
  — `getSellerSettlements` has no page/limit param, fetches a seller's
  *entire* settlement history, then does three full-array passes client-side
  just to show 10 rows and three totals. Fine for a new seller, real cost
  for an established one; worth server-side pagination/aggregation later.
- **`src/app/seller/products/page.tsx:41-50`** — switching stores can fire
  up to 3 sequential product-list fetches (one with the new store but stale
  category, discarded, then the category-reset effect, then a possible
  page-reset effect) instead of one. Not incorrect, just wasteful.
- **`src/shared/lib/analytics.ts:130-147`** — `trackEvent` deliberately
  hand-rolls `fetch` instead of the shared `fetcher`, to avoid `http.ts`'s
  unconditional 401 → refresh → redirect-to-login behavior on a best-effort
  analytics call. Reasonable given `fetcher` has no "silent" mode, but it
  also means analytics loses `fetcher`'s auto-refresh-and-retry — a future
  background caller needing the same thing will likely copy-paste this
  rather than getting a real `fetcher(url, opts, { silent: true })` option.
  Not a bug, just noting the tradeoff since it wasn't written down anywhere.
- **Confirmed clean** — a dedicated removed-behavior audit traced every
  deletion in this diff (dashboard/posts/products feature removal, Sidebar
  nav swap from `onClick` to `<Link>`, AWS env var removal from the deploy
  workflow) against current call sites and found no regressions.
- **Still open, carried over from below**: what to do about
  `docs/TODO-NEXT.md` and `docs/production-readiness.md` showing as
  deleted in the working tree. Content check shows `TODO-NEXT.md` refers to
  stale branch state (`feat/merchant-revamp`, commits that no longer match
  `feat/buyer-checkout-admin-wiring`) — reads like a superseded doc rather
  than a live P0 tracker, but flagging for a decision rather than assuming.

## ✅ Follow-up session, 2026-08-22 (later same day)

Worked the checkout-blocking and financial bugs from the S-list below, plus a
couple of things found along the way. Full lint/format/test pass run across
all three repos before stopping — see verification status at the bottom.

**Fixed:**

- **S1 — checkout was fully broken, now isn't.** `payment_remote_datasource.dart`
  unwrapped `response['data']` expecting a bare `List`; the real envelope is
  `{ data: { providers: [...] } }`. Fixed to read `data.providers`, and fixed
  the unit test fixture that was encoding the wrong shape as correct. Verified
  both tests pass.
- **S3 — cancelling a paid order didn't refund, now it does.**
  `mapanytime-api/order.service.ts#cancelOrder` used to mark any cancelled
  order's payment `FAILED` regardless of whether money had actually been
  captured. Now it checks the payment status first: still-`PENDING` just
  releases the reservation as before; a captured (`COMPLETED`, non-cash)
  payment goes through the same provider `refundPayment()` flow
  `ReturnService.executeRefund` already uses, and the cancellation aborts if
  the provider rejects the refund.
- **Low-stock seller notifications added** (new ask, not from the original
  S-list). `completeOrder` now detects when a product's `quantityOnHand`
  crosses at/below the existing dashboard threshold (10) and sends the seller
  a real persisted notification — fires once on the crossing, not on every
  subsequent order.
- **`mapanytime-market-web/src/shared/lib/analytics.ts`** — two bugs: it used
  a raw `fetch()` instead of the shared authenticated client, so logged-in
  users' events never carried `userId`; and `getSessionId()` ran outside the
  `try/catch`, so a storage error could throw past the "must never break
  navigation" guarantee the file itself documents. Both fixed.
- **Backend roles/permissions constants consolidated**
  (`mapanytime-api/src/constants/roles.constant.ts` /
  `permissions.constant.ts`, `prisma/seeders/roles.seeder.ts`) — the seeder
  used to carry its own separate hardcoded role list and permission if/else
  chain that could drift from `SYSTEM_ROLES`. Now it iterates `SYSTEM_ROLES`
  directly against a `Record<SystemRole, string>` description map (a missing
  entry is a compile error, not a silently-unseeded role) and a
  `NON_ADMIN_ROLE_PERMISSIONS` lookup. This broke
  `tests/unit/permission.gates.test.ts` (it regex-scraped the seeder's old
  inline array) — fixed to read the new constant instead of source text.
- Several other findings from an earlier pass this session were left as
  inline `FIXME`/`TODO` comments only (not fixed) — see the S-list and
  "Other findings, flagged not fixed" below.

**Verification status (all three repos):**

- `mapanytime-api` — `tsc` clean, `eslint` clean, `npx jest --runInBand`:
  336/336 unit tests pass. A handful of integration suites
  (`health.test.ts`, `analytics.test.ts`, others importing
  `infrastructure/rabbitmq/publisher.ts`) fail to even load — pre-existing
  `uuid` package ESM/CJS mismatch under `ts-jest`, unrelated to anything this
  session touched, not fixed.
- `mapanytime-market-web` — `tsc --noEmit` clean, `vitest run`: 30/30 pass.
  `eslint` has **3 pre-existing errors**, unrelated to this session:
  `src/app/seller/finance/page.tsx:105,105,177` — unescaped `'` characters
  (`react/no-unescaped-entities`). Not fixed.
- `mapanytime-market-app` — `flutter analyze`: clean, 0 issues. Full
  `flutter test` / `flutter build` were **not** run (time) — worth doing
  before this branch ships.
- Formatting: `prettier`/`dart format` applied only to files this session
  touched. Pre-existing, unrelated formatting drift exists repo-wide in
  `mapanytime-market-web` (124 files) and in two untouched Flutter files
  (`lib/core/constants/api_endpoints.dart`,
  `lib/features/wishlist/presentation/pages/saved_page.dart` — both already
  had uncommitted changes from earlier work, not this session's). Left alone
  rather than mass-reformatted.

**Still open for next session, in priority order:**

1. Decide what to do about `mapanytime-market-web/docs/TODO-NEXT.md` and
   `docs/production-readiness.md` showing as **deleted** in the uncommitted
   working tree — they document live P0s (B1 staging/production collision,
   B2 no real payment gateway) that shouldn't just disappear untracked.
2. **S4** — inventory can go negative (completion/cancellation/webhook-failure
   paths decrement `quantityReserved` without checking whether the
   reservation-expiry sweeper already released it).
3. **S5** — orders stuck `PENDING` forever if a webhook never arrives (no
   reconciliation job; scheduler stubs are empty).
4. S6–S18 (see full list further down this file) — not re-triaged this
   session, same order as before.
5. Fix the 3 pre-existing `finance/page.tsx` eslint errors in
   `mapanytime-market-web` (quick, unescaped-entity fixes).
6. Run `flutter test` and a real `flutter build` for this branch — skipped
   this session for time.

**Other findings, flagged with inline comments only (not fixed) — grep for
`FIXME`/`TODO` at these files for the full reasoning:**

- `mapanytime-market-web/src/app/seller/manage-stores/page.tsx` — access
  guard blocks legacy stores with `approvalStatus` undefined + `isActive:true`.
- `mapanytime-api/src/modules/wishlists/wishlist.service.ts` — unguarded
  `item.product` access (breaks a unit test), `resolveImageUrl` duplicated a
  4th time, CDN trailing-slash not stripped.
- `mapanytime-api/prisma/seeders/bulk_map_stores.seeder.ts` — `hashPassword`
  re-duplicated right after its only other copy was removed.
- `mapanytime-market-app` notification controller — `Future.wait` fail-fast
  discards good data on partial failure; unread-count fetch can race a
  socket push; `markAllRead` now fires a redundant PATCH on every feed open.
- `mapanytime-market-app/lib/features/wishlist/domain/entities/wishlist_item.dart` —
  deleted-product wishlist rows collide on empty id.
- `mapanytime-market-app/lib/features/profile/presentation/pages/profile_page.dart` —
  "Saved" subtitle still promises stores, only products are wired up.
- `mapanytime-market-web/src/features/auth/utils/resolveHomeRoute.ts` —
  `ADMIN_ROLES` still duplicated on the web side (3-4 copies); the backend
  consolidation this session did **not** touch this — still a manual
  cross-repo sync point.

---

## 🟠 Profile section — partially fixed, three real stubs remain

Originally found mostly fabricated/stubbed; **Saved, Notifications, and the
stats row are now real** (see "Done this session"). What's still open:

- **Still stubs — tap shows a "coming soon" toast, no page, no API:**
  Addresses, Payment methods, Help & Support, About
  (`profile_page.dart`, `_soon(context)`).
- **No edit-profile flow exists at all.** `GET /users/me` exists
  (`mapanytime-api/src/modules/users/*.route.ts:13`) but there is **no
  self-service update endpoint** — the only `PUT` on that router is
  `/users/:userId/roles` (admin-only role assignment), not a general
  profile editor. Needs new backend work first, not just Flutter wiring.
- **Addresses has no API at all.** `BuyerAddresses` exists as a Prisma
  model (referenced by seed data) but has zero route/controller anywhere in
  `mapanytime-api/src/modules`. Needs a whole new backend module before
  Flutter can do anything here.
- **"Payment methods"** — `GET /payments/methods` is real, but it's the
  platform's list of available channels (GCash/Maya/Card/COD), not
  per-buyer saved cards, and it's amount-dependent (fees/bounds change per
  order total). Skipped deliberately — showing it meaningfully outside a
  checkout context needs a design decision, not just a fetch call.
- **Points / loyalty concept doesn't exist anywhere in the API.** Not
  "missing an endpoint" — the feature itself was never designed. The
  hardcoded stat and "Gold member" badge were removed rather than faked
  further (see "Done this session").

## 🔴🔴 MOST URGENT — checkout is fully broken right now

Full order-flow trace (Flutter buyer app + `mapanytime-api`) done end of
session, 2026-08-22. Every claim below is evidence-based — traced actual
code, not inferred from naming.

### S1 — no buyer can place an order (fix this first)

`GET /payments/methods` returns `{data: {providers: [...]}}`
(`mapanytime-api/src/modules/payments/payment.controller.ts:17-21`).
Flutter's `payment_remote_datasource.dart:39-46` does
`final resData = response['data']; if (resData is List) rawList = resData;`
— but `data` is a **Map**, not a List, so `rawList` stays empty forever.
Zero payment methods ever load → `checkout_page.dart:75-92` never sets
`_selectedMethod` → `canPlaceOrder` (`:94-99`) is permanently `false` →
**"Place order" never becomes tappable**. The unit test
(`test/features/payments/data/datasources/payment_remote_datasource_test.dart:24`)
encodes the wrong (flat-list) shape as correct, so this passes CI while
being completely broken in the real app.

**Fix:** unwrap `response['data']['providers']` (or whatever the correct
nested path is) in `payment_remote_datasource.dart`, and correct the test
fixture to match the real API envelope shape.

### Other confirmed bugs (traced, not guessed)

- **S2** — `paymentMethodId` is Joi-validated and sent by the client, but
  the order-creation payload only carries `paymentMethod` (code); the
  method is re-resolved by code + priority order, so it can silently differ
  from what the buyer was quoted (`order.controller.ts:36,80-87`,
  `payment.service.ts:106-151`).
- **S3 — financially dangerous.** Cancelling a `PROCESSING` (already-paid)
  order marks the payment row `FAILED` and refunds nothing
  (`order.service.ts:455-500`, `order.repository.ts:46-54`). Captured
  money, cancelled order, no refund, no settlement.
- **S4** — Inventory can go negative: completion, cancellation, and
  webhook-failure paths all decrement `quantityReserved` without checking
  whether the reservation-expiry sweeper already released it first
  (`order.service.ts:416-422,481-486`, `payment.service.ts:639-642`,
  `inventoryReservation.repository.ts:182-196`). Reachable in normal use —
  any late pickup past `pickupAt + 2h` trips it.
- **S5** — Orders stuck in `PENDING` forever if a webhook never arrives.
  Nothing reconciles against the gateway; the scheduler's relevant jobs are
  empty stubs (`infrastructure/scheduler/index.ts:46-63`). Shown to the
  buyer as "confirmed" the whole time (`order_remote_datasource.dart:94-96`
  maps `PENDING → OrderStatus.confirmed`).
- **S6** — `CartNotifier.clear()` calls `DELETE /cart`
  (`cart_remote_datasource.dart:39-41`), but the server only registers
  `DELETE /cart/clear` (`cart.route.ts:10`) — 404, silently swallowed.
  Harmless today only because checkout clears the cart another way.
- **S7** — In mock-payment mode (current state, no real PayMongo keys), the
  mock `checkoutUrl` is relative (`/mock-checkout?...`,
  `mock.provider.ts:12`); the second `launchUrl` call in
  `checkout_page.dart:297-304` throws outside its catch block, so the
  confirmation screen is never reached even though the order *was* created.

### High-confidence risks (traced, not empirically fired)

- **S8** — The PayMongo HTTP call happens **inside** the Prisma
  `$transaction` that creates the order (`order.service.ts:285`), with no
  configured transaction timeout override (defaults to 5s). A slow gateway
  response ⇒ rollback after the live checkout session already exists at
  PayMongo ⇒ if paid, webhook 404s on a nonexistent order
  (`payment.service.ts:579-581`) ⇒ captured money, no order.
- **S9** — No row locking / conditional update on the stock check
  (`order.service.ts:113,143-148`); the `Inventory.version` optimistic-lock
  column exists in schema but is never read/written anywhere in `src/`.
  Classic oversell race under concurrent checkout for the last unit.
- **S10** — Redis-backed `Idempotency-Key` support exists server-side
  (`order.controller.ts:13-29`) but no Flutter code ever sends that header
  — zero grep hits in `lib/`/`test/`. `dio_smart_retry` retries timeouts,
  so a slow-but-successful `POST /orders` can duplicate an order.
- **S11** — Redis is a single point of failure for order creation; cart is
  Redis-only with a 7-day TTL (`cart.service.ts:20,108`).
- **S12** — Webhook `orderId` extraction path
  (`payment.service.ts:512-515`) wasn't verifiable against a live PayMongo
  payload for `checkout_session.payment.paid` — if PayMongo doesn't
  propagate the session's `reference_number`/`metadata` onto the nested
  payment object, every real webhook silently no-ops
  (`ignored_no_order_id`).
- **S13** — `GET /payments/methods` enforces min/max order amount per
  method; actual order creation (`payment.service.ts:106-151`) does not — a
  direct API caller can bypass the gate.
- **S14** — With no `ACTIVE PricingConfigurations` row, every order silently
  prices off a 2% fallback gateway rate vs. real PayMongo rates of
  1.79–3.125%+₱13.39 (`pricing-engine.service.ts:117-123,461`). Worth
  confirming the seed actually creates that row.

### Minor

- **S15** — Dead "Simulate Mock Payment" button ships in buyer UI
  (`pickup_pass_page.dart:119-145`); harmless since the route is unmounted
  in prod, but visible/confusing.
- **S16** — `getMyOrders` and order `create` both lazily create a `buyers`
  row on read — a GET with a write side effect, duplicated in two places.
- **S17** — `PaymentMethod.fromJson` does `json['id'] as String` unguarded
  — null id throws instead of degrading gracefully.
- **S18** — `reservation_remote_datasource.dart` /
  `reservationControllerProvider` are defined but referenced nowhere else —
  dead code implying a flow that was never built.

### What's actually solid (don't re-litigate this)

Server-side order creation is one Prisma transaction covering stock
reservation + order + charges ledger + payment row. Webhook handling has
real signature verification (HMAC, provider-specific) and genuine
event-level idempotency (`PaymentWebhookEvents` table +
`COMPLETED`-is-terminal guard). Mock provider fails closed in production at
two independent layers. State machine exists and is respected. Pricing
engine's gross-up math is correct. This is a well-built system with real
seams broken, not a fundamentally broken design.

---

## 🔴 Open decision — map marker clustering

Was mid-discussion when the session ended. The ask: markers already grow on
zoom (see below), but **stores near each other need to "consolidate"**
instead of just hiding.

**Current behavior** (`lib/features/worldMap/presentation/pages/components/mapbox_style_manager.dart`):
Not true clustering. It's Mapbox's native collision engine — when photo
cards would overlap, the losing ones get hidden and fall back to a small
colored dot underneath (`_dotLayerId`). No count, no grouping, just
winner/loser per frame. This is what you were seeing as scattered black dots
on the map screenshot.

**Two options, never decided:**
1. **Real clustering** — nearby stores merge into one marker showing a
   count (e.g. "12"), splits apart as you zoom/tap in. The
   Google-Maps-style pattern. Bigger change: needs a new Mapbox
   `cluster: true` GeoJSON source config + cluster-count circle/text layers
   alongside the existing custom photo-card layer. Clustered points can't
   show individual store photos — only unclustered ones can.
2. **Tune the existing dot fallback** — keep today's system, just make it
   read better (bigger/more visible dots, smarter win/lose rule).

⚠️ Before touching this file: it has an explicit comment —
_"Tuned through several rounds of on-device feedback; keep these values if
this file is ever touched again."_ — meaning this was already iterated on
once. Don't just rewrite blind.

**Zoom-based sizing already works, no action needed:** `iconSizeExpression`
interpolates 0.5x at zoom 12 → full size at zoom 17, computed natively on
GPU. This part of the original ask is already done.

## ✅ Done this session

- **Wishlist/Saved feature built end-to-end.** New feature
  (`lib/features/wishlist/`): entity (reuses the existing `StoreProduct`
  shape rather than duplicating it), REST datasource, an `AsyncNotifier`
  controller with optimistic add/remove, and a grid page at `/saved`
  reusing the shared `ProductCard` widget. Wired to the real
  `/v1/wishlist` endpoints.
  - **Backend bug fixed**: `wishlist.service.ts`'s `getWishlist` was
    returning raw S3 file paths instead of resolved URLs (every other
    product-image endpoint resolves them) — would have rendered broken
    images. Fixed to match `product.repository.ts`'s pattern.
  - **Heart/save affordance added** — `ProductCard` gained optional
    `isSaved`/`onToggleSave` params (opt-in; every other consumer of the
    widget is unaffected). Wired into the Home product grid and
    `ProductDetailPage`'s app bar. This closes a gap the first pass left
    open: the datasource's `add()` existed but nothing called it, so Saved
    could never have anything in it. Now it can.
  - **Bug found + fixed during review**: concurrent removes could
    resurrect an item. Removing A then immediately B, with A's server call
    then failing, restored the *entire stale pre-A snapshot* on rollback —
    silently undoing B's already-successful removal. Fixed to restore only
    the specific failed item into whatever state actually is at rollback
    time, not a stale snapshot.
- **Notifications wired to the real persisted feed.** The existing feed page
  (`lib/features/notifications/`) was socket-only, with a comment claiming
  *"the backend doesn't persist notifications yet"* — false; `GET
  /notifications`, `/unread-count`, and `PATCH /read-all` all existed and
  were simply never connected. Controller now backfills history on open and
  merges it with anything the socket already delivered. **Socket path
  verified untouched** (`git diff` showed zero changes to
  `notification_socket_datasource.dart`, `notification_providers.dart`,
  `notification_toast_host.dart`, and the exact `ref.listen(...)` line).
  - **Bug found + fixed during review**: double-counting. The server writes
    the DB row before emitting the socket event, so a notification that
    arrives over the socket before the initial `getUnreadCount()` fetch
    resolves is *already included* in that count — the merge logic was
    adding the local socket-tracked count on top of it. Fixed to trust the
    server's count alone at merge time.
  - **Known minor risk, not fixed** (narrow edge case, not worth the
    complexity): deep-linking straight into the feed page before the
    provider is otherwise alive could theoretically let a stale
    pre-mark-as-read count overwrite a just-cleared badge, since
    `markAllRead()` and `_loadHistory()`'s count fetch are two independent
    concurrent requests with no ordering guarantee. Self-corrects on the
    next real fetch.
- **Profile stats wired to real data.** Removed the hardcoded `'8'` /
  `'320'` / `'12'` literals and the fabricated "Gold member" badge entirely
  (no loyalty concept exists anywhere in the API). Orders and Saved now
  show real counts from `ordersProvider` and the new wishlist controller.
  "Saved" and "Notifications" menu items now navigate to the real pages
  instead of a "coming soon" toast.
- **Product card border** (`lib/shared/widgets/product_card.dart`) — added a
  visible border (`AppColors.ink.withValues(alpha: 0.08)`, matching
  `AppEffects.cardShadow`'s strength) around the product image. First tried
  `AppColors.ui.borderHairline` — too close to the placeholder's own fill
  color to read as a border at all; switched to the stronger ink-alpha
  approach after visual confirmation.
- **Product detail hero image** (`lib/features/store/presentation/pages/product_detail_page.dart`) —
  was full-bleed behind the transparent app bar; now an inset "capsule" card
  (margin + `AppRadius.xl` full rounding + same visible border). Removed
  `extendBodyBehindAppBar` since the image no longer sits behind it — the
  back button now sits on plain background above the card, confirmed
  acceptable trade-off.
- **Emulator set up from scratch** — Pixel 7, API 36, Google Play image.
  Required: `.env.prod` created (was missing entirely — gitignored, never
  existed locally, but `pubspec.yaml` bundles it as a required asset so even
  *dev* builds failed without it); AGP 8.7.3→8.11.1, Kotlin 2.0.20→2.2.20,
  Gradle 8.10.2→8.14 (some deps needed AGP ≥8.9.1); AVD's `hw.keyboard` was
  `no` — physical keyboard typing silently did nothing until flipped to
  `yes` and the emulator was restarted (config is boot-time only).
- **Simulated GPS location set** — emulator has no real GPS; pushed Baguio
  City coords (16.4145, 120.5960) via `adb emu geo fix`. Location permission
  was already granted; it just needed a location to exist at all.
- **Local API DB pointed at localhost** — `mapanytime-api/.env`
  `DATABASE_URL` was pointed at a remote staging RDS
  (`forhu-staging-style-os-mirror-postgres...`) which had **zero tables** —
  that's why login kept 401ing, not an `.env.dev` (Flutter) issue as first
  suspected. You switched it to the local Docker Postgres yourself
  mid-session; confirmed migrated + seeded correctly afterward.
- **Bulk map-density seeder** — new file
  `mapanytime-api/prisma/seeders/bulk_map_stores.seeder.ts`, registered in
  `prisma/seed.ts`. Added **52 stores, ~1,637 products** across all 13
  categories, scattered over real Baguio City / La Trinidad neighborhoods,
  owned by 5 new `bulk.sellerN@mapanytime.test` / `Seller123` accounts (kept
  separate from the hand-crafted sellers). Deterministic (seeded PRNG, not
  `Math.random()`) — re-running `npm run db:seed` won't duplicate or
  reshuffle anything. Already run successfully against local DB.
- **`multi_store_seller.seeder.ts` cleanup** — removed a dead code path that
  defined `seller.multistore@mapanytime.test` as "Nora Bumanglag"; that user
  is actually created first by `users.seeder.ts` as "Marco Cordillera", so
  the Nora branch could never fire. Simplified to
  `findUniqueOrThrow` with a comment explaining the seeding-order
  dependency.

## Known gotchas worth remembering

- **`hw.keyboard=no` on a fresh AVD** — Android emulator ignores the host
  physical keyboard entirely by default. Fix in Android Studio: Device
  Manager → ⋮ → Edit → Show Advanced Settings → Input → enable keyboard
  input. Or edit `config.ini` directly and cold-boot.
- **New AVD windows spawn off-screen** — first launch after creating an AVD
  put the window at `Top=-120` (above the visible screen). Not a crash, just
  needs `SetWindowPos` (or manually drag it) to bring it into view.
- **The emulator has a separate toolbar window** — clicking the emulator
  taskbar icon can focus the side toolbar strip instead of the actual phone
  screen (two separate top-level windows, same process). If clicks/keys
  aren't registering, click directly on the phone screen area, not near the
  edge where the toolbar sits.
- **`sdkmanager`/`avdmanager`/`adb` aren't on PATH** in this shell — use full
  paths: `/c/Android/Sdk/cmdline-tools/latest/bin/`,
  `/c/Android/Sdk/platform-tools/adb.exe`. Also needs `JAVA_HOME` set to
  Android Studio's bundled JBR
  (`/c/Program Files/Android/Android Studio/jbr`) for `sdkmanager`/`avdmanager`.
- **Pinch-to-zoom on the map** doesn't work with a mouse (no second finger).
  Hold **Ctrl** while dragging in the emulator to simulate a two-finger
  pinch.

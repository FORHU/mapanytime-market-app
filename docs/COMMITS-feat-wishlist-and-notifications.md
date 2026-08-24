# Branch: `feat/wishlist-and-notifications`

_Off `main` @ 10f9dd0. 8 commits, 2026-08-23._

Full findings list (fixed and flagged-only, across all three repos) live in
[`docs/PICKUP-NEXT.md`](PICKUP-NEXT.md) under "Review session, 2026-08-23"
and the sections above it.

---

## `chore(android): bump AGP/Gradle/Kotlin for emulator setup`

AGP 8.7.3→8.11.1, Kotlin 2.0.20→2.2.20, Gradle 8.10.2→8.14 — some
dependencies needed AGP ≥8.9.1.

**Files:** `android/gradle/wrapper/gradle-wrapper.properties`,
`android/settings.gradle.kts` — 3 insertions, 3 deletions

## `fix(payments): unwrap the real payment-methods envelope`

**The headline fix — checkout was fully broken before this.**
`GET /payments/methods` returns `{data: {providers: [...]}}`, but the
datasource read `response['data']` expecting a bare `List`, so `rawList`
stayed empty forever — zero payment methods ever loaded, and "Place
order" could never become tappable. Fixed to read `data.providers`, and
corrected the unit test fixture that encoded the wrong flat-list shape as
correct, which let this pass CI while being completely broken in the real
app.

**Files:** `lib/features/payments/data/datasources/payment_remote_datasource.dart`,
`test/features/payments/data/datasources/payment_remote_datasource_test.dart`
— 56 insertions, 47 deletions

## `feat(routes): add notification and wishlist endpoint/route constants`

Shared plumbing for the two features that follow: notification
history/unread-count/mark-all-read endpoints, wishlist CRUD endpoints, and
the new `/saved` route.

**Files:** `lib/core/constants/api_endpoints.dart`,
`lib/routes/app_routes.dart`, `lib/routes/route_names.dart` — 31 insertions

## `feat(notifications): wire feed to the persisted history endpoints`

The feed page was socket-only, with a comment claiming the backend
doesn't persist notifications yet — false; `GET /notifications`,
`/unread-count`, and `PATCH /read-all` all existed and were simply never
connected. The controller now backfills history on open and merges it
with anything the socket already delivered; the socket path itself is
untouched.

Trusts the server's unread count alone at merge time rather than adding a
locally-tracked socket count on top of it, which would double-count
notifications that land over the socket before the initial
`getUnreadCount()` call resolves (the server writes the DB row before
emitting the socket event, so an in-flight count fetch already includes
it).

**Files:** `lib/features/notifications/data/datasources/notification_remote_datasource.dart`
(new), `lib/features/notifications/domain/entities/app_notification.dart`,
`lib/features/notifications/presentation/controllers/notification_feed_controller.dart`,
`lib/features/notifications/presentation/pages/notification_feed_page.dart`
— 152 insertions, 11 deletions

## `feat(wishlist): add Saved feature end-to-end`

New feature: entity (reuses the existing `StoreProduct` shape rather than
duplicating it), REST datasource, an `AsyncNotifier` controller with
optimistic add/remove, and a grid page at `/saved` reusing the shared
`ProductCard` widget. Wired to the real `/v1/wishlist` endpoints.

`ProductCard` gains optional `isSaved`/`onToggleSave` params (opt-in;
every other consumer is unaffected) and a visible border around the
product image. Wired into the Home product grid and
`ProductDetailPage`'s app bar — closes the gap where the datasource's
`add()` existed but nothing called it. `ProductDetailPage`'s hero image is
now an inset card instead of full-bleed behind the app bar, so
`extendBodyBehindAppBar` is dropped.

Concurrent removes could resurrect an item: removing A then immediately
B, with A's server call then failing, restored the entire stale pre-A
snapshot on rollback — silently undoing B's already-successful removal.
Fixed to restore only the specific failed item into whatever state
actually is at rollback time.

**Files:** `lib/features/home/presentation/pages/home_page.dart`,
`lib/features/store/presentation/pages/product_detail_page.dart`,
`lib/features/wishlist/**` (new: datasource, entity, controller, page),
`lib/shared/widgets/product_card.dart` — 494 insertions, 28 deletions

## `feat(profile): wire stats to real data`

Removed hardcoded `'8'`/`'320'`/`'12'` literals and the fabricated "Gold
member" badge — no loyalty concept exists anywhere in the API. Orders and
Saved now show real counts from `ordersProvider` and the wishlist
controller. Saved and Notifications menu items now navigate to the real
pages instead of a "coming soon" toast.

**Files:** `lib/features/profile/presentation/pages/profile_page.dart` —
25 insertions, 41 deletions

## `docs: session pickup notes and pre-commit review findings`

New `docs/PICKUP-NEXT.md` — full session log plus the 2026-08-23 review
findings across all three repos (fixed and flagged-only).

**Files:** `docs/PICKUP-NEXT.md` (new) — 510 insertions

## `style: run dart format on api_endpoints.dart and saved_page.dart`

Formatting-only, caught by `dart format --set-exit-if-changed`.

**Files:** `lib/core/constants/api_endpoints.dart`,
`lib/features/wishlist/presentation/pages/saved_page.dart` — 4 insertions,
4 deletions

---

## Verification (post-commit, all green)

- `flutter analyze` — 0 issues
- `dart format --set-exit-if-changed lib test` — clean
- `flutter test` — all pass (34 test groups)
- `flutter build apk --debug` — succeeds, `build/app/outputs/flutter-apk/app-debug.apk`
  (699s — first build after the AGP/Gradle/Kotlin bump above)

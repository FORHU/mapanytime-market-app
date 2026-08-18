/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  /// Sends a one-time reset code to the given email.
  /// NOT YET IMPLEMENTED on the backend — request body `{ email }`.
  static const String forgotPassword = '/auth/forgot-password';

  /// Verifies the code and sets a new password.
  /// NOT YET IMPLEMENTED on the backend — request body
  /// `{ email, code, newPassword }`.
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String users = '/users';
  static const String me = '/users/me';

  /// Stores near a `lat`/`lng` query origin (used by the world map).
  static const String storesNearby = '/stores/nearby';

  /// Global categories. With no `parentId` query it returns the root (parent)
  /// categories — used for the map filter chips.
  static const String categories = '/categories';

  /// Root categories with their nested children — used for the Home filter's
  /// root → children drill-down.
  static const String categoryTrees = '/categories/trees';

  /// Buyer catalog: all active products across stores, filterable by
  /// `categoryId` / `storeId` / price. Powers the Home product grid.
  static const String allProducts = '/products/all';

  // ── Storefront ────────────────────────────────────────────────────────────

  /// Single store detail + hours + categories for the storefront page.
  /// Append `/<storeId>` → `GET /stores/<id>`.
  static const String storeById = '/stores';

  /// Active discount ads (BOGO/%/fixed-amount) across nearby stores, with a
  /// representative linked product. Public — powers the "For You" page's
  /// "Today's Deals" rail. Same bounding-box query params as [storesNearby].
  static const String merchantAdsNearby = '/merchant-ads/nearby';

  // ── Cart ──────────────────────────────────────────────────────────────────

  /// Get the current user's cart from Redis.  `GET /cart`.
  static const String cart = '/cart';

  /// Add / update an item in the cart.  `POST /cart/add`.
  static const String cartAdd = '/cart/add';

  /// Server-verified pricing preview (subtotal, auto-applied discounts, tax,
  /// total) for the cart or a selected subset of it.  `POST /cart/pricing`.
  static const String cartPricing = '/cart/pricing';

  // ── Orders ────────────────────────────────────────────────────────────────

  /// Create a new order from the Redis cart.  `POST /orders`.
  static const String ordersCreate = '/orders';

  /// Cancel an existing order.  `PATCH /orders/cancel`.
  static const String ordersCancel = '/orders/cancel';

  // ── Payments ──────────────────────────────────────────────────────────────

  /// Fetch QR payload for GCash/Bank payment.  Append `/<orderId>`.
  static const String paymentQr = '/payments/qr-payload';

  /// Simulate payment settlement (mock webhook).  `POST /payments/mock-webhook`.
  static const String paymentWebhook = '/payments/mock-webhook';

  // ── Inventory reservations ────────────────────────────────────────────────

  /// Hold stock for the checkout window.  `POST /inventory/reserve`.
  static const String inventoryReserve = '/inventory/reserve';

  /// The caller's still-valid holds.  `GET /inventory/reservations/active`.
  static const String activeReservations = '/inventory/reservations/active';

  /// Consume a hold once the order is placed.
  static String reservationConfirm(String id) =>
      '/inventory/reservations/$id/confirm';

  /// Give a hold back when checkout is abandoned.
  static String reservationRelease(String id) =>
      '/inventory/reservations/$id/release';

  // ── Returns ───────────────────────────────────────────────────────────────

  /// Submit a return request.  `POST /returns`.
  static const String returns = '/returns';

  /// The caller's return requests.  `GET /returns/buyer`.
  static const String buyerReturns = '/returns/buyer';
}

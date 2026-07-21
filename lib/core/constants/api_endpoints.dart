/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh-token';
  static const String logout = '/auth/logout';

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

  // ── Cart ──────────────────────────────────────────────────────────────────

  /// Get the current user's cart from Redis.  `GET /cart`.
  static const String cart = '/cart';

  /// Add / update an item in the cart.  `POST /cart/add`.
  static const String cartAdd = '/cart/add';

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
}

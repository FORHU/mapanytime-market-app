import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/core/errors/failure.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/home/data/datasources/product_remote_datasource.dart';
import 'package:mapanytime_market_app/features/home/data/repositories/product_repository.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/product_page.dart';
import 'package:mapanytime_market_app/features/home/domain/usecases/get_all_products_usecase.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remote = ProductRemoteDataSource(ref.watch(apiServiceProvider));
  return ProductRepositoryImpl(remote);
});

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>(
  (ref) => GetAllProductsUseCase(ref.watch(productRepositoryProvider)),
);

/// The accumulated, paged product list for the Home grid.
class HomeProductsData {
  const HomeProductsData({
    required this.items,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Product> items;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  HomeProductsData copyWith({
    List<Product>? items,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HomeProductsData(
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Loads the Home product grid one page at a time. [setCategory] switches the
/// active filter (empty = all) and reloads from page 1; [loadMore] appends the
/// next page for infinite scroll. A [Failure] is surfaced through the async
/// error channel (wrapped as [ProductLoadException]).
class HomeProductsController extends AsyncNotifier<HomeProductsData> {
  static const _limit = 20;

  String _categoryId = '';
  String _search = '';
  int _page = 1;
  bool _loadingMore = false;

  @override
  Future<HomeProductsData> build() => _fetchInitial();

  Future<HomeProductsData> _fetchInitial() async {
    _page = 1;
    final page = await _fetchPage(1);
    return HomeProductsData(
      items: page.items,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<ProductPage> _fetchPage(int page) async {
    final result = await ref.read(getAllProductsUseCaseProvider)(
      categoryId: _categoryId.isEmpty ? null : _categoryId,
      search: _search.isEmpty ? null : _search,
      page: page,
      limit: _limit,
    );
    return result.fold(
      (failure) => throw ProductLoadException(failure),
      (productPage) => productPage,
    );
  }

  /// Switch the category filter (empty = all) and reload from the first page.
  Future<void> setCategory(String categoryId) async {
    if (categoryId == _categoryId) return;
    _categoryId = categoryId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchInitial);
  }

  /// Set the search term (empty = none) and reload from the first page.
  Future<void> setSearch(String search) async {
    if (search == _search) return;
    _search = search;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchInitial);
  }

  /// Append the next page. No-op while already loading or when exhausted.
  Future<void> loadMore() async {
    final data = state.value;
    if (_loadingMore || data == null || !data.hasMore) return;

    _loadingMore = true;
    state = AsyncValue.data(data.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(_page + 1);
      _page += 1;
      state = AsyncValue.data(
        HomeProductsData(
          items: [...data.items, ...next.items],
          total: next.total,
          hasMore: next.hasMore,
        ),
      );
    } on Object {
      // Keep the pages already loaded; just clear the loading-more flag.
      state = AsyncValue.data(data.copyWith(isLoadingMore: false));
    } finally {
      _loadingMore = false;
    }
  }
}

final homeProductsControllerProvider =
    AsyncNotifierProvider<HomeProductsController, HomeProductsData>(
      HomeProductsController.new,
    );

/// Bridges a domain [Failure] into the async error channel (thrown objects must
/// be [Exception]s).
class ProductLoadException implements Exception {
  ProductLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

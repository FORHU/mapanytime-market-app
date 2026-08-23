import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';

class PaymentProviderGroup {
  const PaymentProviderGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.methods,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final List<PaymentMethod> methods;
}

class PaymentRemoteDataSource {
  const PaymentRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<PaymentProviderGroup>> fetchPaymentMethods({
    double? amount,
  }) async {
    final encodedAmount = amount != null && amount > 0
        ? Uri.encodeComponent('$amount')
        : null;
    final endpoint = encodedAmount != null
        ? '${ApiEndpoints.paymentMethods}?amount=$encodedAmount'
        : ApiEndpoints.paymentMethods;

    final response = await _api.get(endpoint);
    var rawList = <dynamic>[];

    if (response is Map) {
      final resData = response['data'];
      if (resData is Map) {
        // Real API envelope: { data: { providers: [...] } }.
        final providers = resData['providers'];
        if (providers is List) rawList = providers;
      } else if (resData is List) {
        rawList = resData;
      }
    } else if (response is List) {
      rawList = response;
    }

    return rawList.map((pJson) {
      final pMap = (pJson as Map).cast<String, dynamic>();
      final providerName = pMap['name'] as String? ?? '';
      final rawMethods = pMap['methods'];
      final methodList = (rawMethods is List ? rawMethods : <dynamic>[]).map((
        mJson,
      ) {
        final mMap = (mJson as Map).cast<String, dynamic>();
        return PaymentMethod.fromJson(mMap, providerName: providerName);
      }).toList();

      return PaymentProviderGroup(
        id: pMap['id'] as String? ?? '',
        code: pMap['code'] as String? ?? '',
        name: providerName,
        description: pMap['description'] as String?,
        methods: methodList,
      );
    }).toList();
  }
}

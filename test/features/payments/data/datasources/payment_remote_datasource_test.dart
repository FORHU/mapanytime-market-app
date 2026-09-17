import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/orders/data/order_remote_datasource.dart';
import 'package:mapanytime_market_app/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/order_payment_status.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late PaymentRemoteDataSource paymentDataSource;
  late OrderRemoteDataSource orderDataSource;

  setUp(() {
    mockApi = MockApiService();
    paymentDataSource = PaymentRemoteDataSource(mockApi);
    orderDataSource = OrderRemoteDataSource(mockApi);
  });

  group('PaymentRemoteDataSource.fetchPaymentMethods', () {
    const tResponse = {
      'statusCode': 200,
      'message': 'Active payment methods retrieved successfully',
      // Real API envelope from payment.controller.ts:17-21 is
      // { data: { providers: [...] } }, not a bare list under `data`.
      'data': {
        'providers': [
          {
            'id': 'prov-1',
            'code': 'PAYMONGO',
            'name': 'PayMongo',
            'description': 'Online payments',
            'methods': [
              {
                'id': 'pm-1',
                'code': 'GCASH',
                'name': 'GCash',
                'type': 'E_WALLET',
                'available': true,
                'feeAmount': 22.81,
                'buyerTotalAmount': 1022.81,
              },
              {
                'id': 'pm-2',
                'code': 'CARD',
                'name': 'Credit / Debit Card',
                'type': 'CARD',
                'available': false,
                'unavailableReason':
                    'Minimum order amount for cards is ₱500.00',
                'feeAmount': 46.08,
                'buyerTotalAmount': 1046.08,
              },
            ],
          },
          {
            'id': 'prov-2',
            'code': 'CASH',
            'name': 'Cash',
            'description': 'Pay at stall',
            'methods': [
              {
                'id': 'pm-3',
                'code': 'COD',
                'name': 'Cash on Pickup',
                'type': 'CASH',
                'available': true,
                'feeAmount': 0.0,
                'buyerTotalAmount': 1000.0,
              },
            ],
          },
        ],
      },
    };

    test(
      'parses provider groups and methods with fee metadata correctly',
      () async {
        when(() => mockApi.get(any())).thenAnswer((_) async => tResponse);

        final result = await paymentDataSource.fetchPaymentMethods(
          amount: 1000,
        );

        expect(result.length, 2);
        expect(result.first.name, 'PayMongo');
        expect(result.first.methods.length, 2);

        final gcash = result.first.methods.first;
        expect(gcash.id, 'pm-1');
        expect(gcash.name, 'GCash');
        expect(gcash.code, 'GCASH');
        expect(gcash.available, isTrue);
        expect(gcash.feeAmount, 22.81);
        expect(gcash.buyerTotalAmount, 1022.81);
        expect(gcash.isCash, isFalse);

        final card = result.first.methods[1];
        expect(card.available, isFalse);
        expect(
          card.unavailableReason,
          'Minimum order amount for cards is ₱500.00',
        );

        final cash = result[1].methods.first;
        expect(cash.isCash, isTrue);
        expect(cash.feeAmount, 0.0);
      },
    );
  });

  group('PaymentRemoteDataSource.fetchOrderPaymentStatus', () {
    test('parses the status envelope and reports a settled payment', () async {
      when(() => mockApi.get(any())).thenAnswer(
        (_) async => const {
          'statusCode': 200,
          'data': {
            'orderId': 'order-1',
            'paymentId': 'pay-1',
            'orderStatus': 'PROCESSING',
            'paymentStatus': 'COMPLETED',
            'amount': 1022.81,
            'currency': 'PHP',
            'provider': 'Xendit',
            'paymentMethod': 'GCash',
            'paidAt': '2026-08-20T17:05:00.000Z',
          },
        },
      );

      final result = await paymentDataSource.fetchOrderPaymentStatus('order-1');

      expect(result.orderId, 'order-1');
      expect(result.paymentStatus, PaymentStatusValue.completed);
      expect(result.orderStatus, 'PROCESSING');
      expect(result.amount, 1022.81);
      expect(result.paidAt, isNotNull);
      expect(result.isSettled, isTrue);
      expect(result.outcome, PaymentOutcome.paid);
    });

    /// The common case immediately after checkout: the buyer's browser is back
    /// before the webhook that settles the payment has arrived.
    test('reports a pending payment as unsettled and waiting', () async {
      when(() => mockApi.get(any())).thenAnswer(
        (_) async => const {
          'data': {
            'orderId': 'order-2',
            'orderStatus': 'PENDING',
            'paymentStatus': 'PENDING',
          },
        },
      );

      final result = await paymentDataSource.fetchOrderPaymentStatus('order-2');

      expect(result.isSettled, isFalse);
      expect(result.outcome, PaymentOutcome.waiting);
    });

    /// No webhook is emitted when a session merely expires, so the order being
    /// moved to FAILED is the only failure signal that ever reaches the app.
    test('reads a failed order as failure despite a PENDING payment', () async {
      when(() => mockApi.get(any())).thenAnswer(
        (_) async => const {
          'data': {
            'orderId': 'order-3',
            'orderStatus': 'FAILED',
            'paymentStatus': 'PENDING',
          },
        },
      );

      final result = await paymentDataSource.fetchOrderPaymentStatus('order-3');

      expect(result.outcome, PaymentOutcome.failed);
      expect(result.isSettled, isTrue);
    });

    test('tolerates an unknown status rather than throwing', () async {
      when(() => mockApi.get(any())).thenAnswer(
        (_) async => const {
          'data': {'orderId': 'order-4', 'paymentStatus': 'SOMETHING_NEW'},
        },
      );

      final result = await paymentDataSource.fetchOrderPaymentStatus('order-4');

      expect(result.paymentStatus, PaymentStatusValue.unknown);
      expect(result.outcome, PaymentOutcome.waiting);
    });
  });

  group('OrderRemoteDataSource.createOrder', () {
    const tCreateOrderResponse = {
      'statusCode': 201,
      'message': 'Order created successfully',
      'data': {
        'id': 'order-12345',
        'status': 'PENDING',
        'totalAmount': 1022.81,
        'checkoutUrl': 'https://checkout.paymongo.com/cs_test_123',
        'expiresAt': '2026-08-20T18:00:00.000Z',
      },
    };

    test('returns OrderCreationResult with checkoutUrl and orderId', () async {
      when(
        () => mockApi.post(any(), any()),
      ).thenAnswer((_) async => tCreateOrderResponse);

      final result = await orderDataSource.createOrder(
        type: 'PICKUP',
        pickupAt: '2026-08-20T16:00:00.000Z',
        paymentMethodId: 'pm-1',
        paymentMethod: 'GCASH',
        productIds: ['prod-1', 'prod-2'],
      );

      expect(result.orderId, 'order-12345');
      expect(result.checkoutUrl, 'https://checkout.paymongo.com/cs_test_123');
      expect(result.expiresAt, '2026-08-20T18:00:00.000Z');
    });
  });
}

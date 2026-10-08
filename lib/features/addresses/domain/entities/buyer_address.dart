import 'package:equatable/equatable.dart';

/// Kinds of address the API stores (`ADDRESSTYPE`).
enum AddressType {
  home('HOME', 'Home'),
  office('OFFICE', 'Office'),
  billing('BILLING', 'Billing');

  const AddressType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AddressType fromApi(Object? value) => AddressType.values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => AddressType.home,
  );
}

/// One of the buyer's saved addresses (`GET /addresses`).
class BuyerAddress extends Equatable {
  const BuyerAddress({
    required this.id,
    required this.type,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.isDefault,
    this.addressLine2,
    this.barangay,
    this.city,
    this.province,
    this.zipCode,
    this.country = 'Philippines',
  });

  factory BuyerAddress.fromJson(Map<String, dynamic> json) {
    String? opt(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    return BuyerAddress(
      id: json['id'] as String,
      type: AddressType.fromApi(json['addressType']),
      recipientName: (json['recipientName'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      addressLine1: (json['addressLine1'] as String?) ?? '',
      addressLine2: opt('addressLine2'),
      barangay: opt('barangay'),
      city: opt('city'),
      province: opt('province'),
      zipCode: opt('zipCode'),
      country: opt('country') ?? 'Philippines',
      isDefault: json['isDefault'] == true,
    );
  }

  final String id;
  final AddressType type;
  final String recipientName;

  /// E.164, e.g. `+639171234567`.
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String? barangay;
  final String? city;
  final String? province;
  final String? zipCode;
  final String country;
  final bool isDefault;

  /// The address as one line: the main line plus any optional parts that
  /// aren't already in it (sign-up stores everything in [addressLine1]).
  String get displayLine {
    final parts = [addressLine1];
    for (final part in [addressLine2, barangay, city, province, zipCode]) {
      if (part != null &&
          !addressLine1.toLowerCase().contains(part.toLowerCase())) {
        parts.add(part);
      }
    }
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    type,
    recipientName,
    phoneNumber,
    addressLine1,
    addressLine2,
    barangay,
    city,
    province,
    zipCode,
    country,
    isDefault,
  ];
}

/// What the add / edit form sends.
class AddressDraft {
  const AddressDraft({
    required this.type,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine1,
    this.isDefault = false,
  });

  final AddressType type;
  final String recipientName;
  final String phoneNumber;
  final String addressLine1;
  final bool isDefault;

  Map<String, Object> toJson() => {
    'addressType': type.apiValue,
    'recipientName': recipientName,
    'phoneNumber': phoneNumber,
    'addressLine1': addressLine1,
    'isDefault': isDefault,
  };
}

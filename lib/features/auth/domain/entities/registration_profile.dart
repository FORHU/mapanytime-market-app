/// Sex as printed on a Philippine government ID.
enum Sex {
  male('MALE'),
  female('FEMALE');

  const Sex(this.apiValue);

  /// Value of the API's `SEX` enum.
  final String apiValue;
}

/// Government IDs a buyer can sign up with — mirrors the API's `BUYERIDTYPE`.
enum IdType {
  philsys('PHILSYS', 'PhilSys National ID'),
  driversLicense('DRIVERS_LICENSE', "Driver's License"),
  passport('PASSPORT', 'Passport'),
  umid('UMID', 'UMID'),
  postalId('POSTAL_ID', 'Postal ID'),
  prcId('PRC_ID', 'PRC ID');

  const IdType(this.apiValue, this.label);

  final String apiValue;

  /// Proper name of the ID; the same in every language.
  final String label;
}

/// What the buyer confirmed on the "Check your details" step, sent with the
/// sign-up alongside the ID photo.
class RegistrationProfile {
  const RegistrationProfile({
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.address,
    required this.idType,
    required this.idNumber,
    required this.idPhotoPath,
    this.sex,
  });

  /// E.164, e.g. `+639171234567`.
  final String phoneNumber;
  final DateTime dateOfBirth;
  final Sex? sex;

  /// One line, as confirmed against the ID.
  final String address;
  final IdType idType;
  final String idNumber;

  /// Local path of the ID photo picked with image_picker.
  final String idPhotoPath;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/home/data/datasources/reverse_geocoding_datasource.dart';

Map<String, dynamic> _place(String name, {String? region}) => {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'properties': {
        'feature_type': 'place',
        'name': name,
        'context': {
          if (region != null) 'region': {'name': region},
          'country': {'name': 'Philippines'},
        },
      },
    },
  ],
};

void main() {
  const labelFrom = ReverseGeocodingDatasource.labelFrom;

  test('joins place and region', () {
    expect(labelFrom(_place('Baguio', region: 'Benguet')), 'Baguio, Benguet');
  });

  test('falls back to the place name alone', () {
    expect(labelFrom(_place('Baguio')), 'Baguio');
  });

  test('does not repeat a region with the same name', () {
    expect(labelFrom(_place('Manila', region: 'Manila')), 'Manila');
  });

  test('null when there are no features or no name', () {
    expect(labelFrom({'features': <Object>[]}), isNull);
    expect(labelFrom(<String, dynamic>{}), isNull);
    expect(labelFrom(_place('  ')), isNull);
  });
}

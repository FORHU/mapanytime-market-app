/// Presentational dummy data for the Home page's greeting and hero stats.
///
/// The app bar (greeting / name / location) and hero counters are still static
/// sample content — swap for real providers later. Categories and products are
/// now fetched from the API (see the category tree + home products providers).
library;

/// Static sample content for the Home page header and hero.
abstract final class HomeMock {
  static const greeting = 'Good Morning,';
  static const userName = 'Sara Smith';
  static const location = 'Candon City, Ilocos Sur';

  static const nearbyCount = 138;
  static const openNowCount = 92;
  static const dealsCount = 16;
}

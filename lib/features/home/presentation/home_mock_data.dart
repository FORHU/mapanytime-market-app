/// Presentational dummy data for the Home page's header.
///
/// The app bar's user name is still static sample content — swap for a real
/// provider later. The location comes from the device (see
/// homeLocationControllerProvider). Categories and products are fetched from
/// the API (see the category tree + home products providers); deals come from
/// recommendationsFeedProvider.
library;

/// Static sample content for the Home page header.
abstract final class HomeMock {
  static const userName = 'Sara Smith';
}

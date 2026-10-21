import 'package:flutter_test/flutter_test.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/navigation_provider.dart';
import 'package:jakdrain/providers/map_filter_provider.dart';

void main() {
  group('Jakdrain Unit & State Tests', () {
    test('NavigationProvider initial index is 0', () {
      final nav = NavigationProvider();
      expect(nav.currentIndex, 0);
      nav.setIndex(1);
      expect(nav.currentIndex, 1);
      nav.reset();
      expect(nav.currentIndex, 0);
    });

    test('MapFilterProvider filters reports correctly', () {
      final filterProvider = MapFilterProvider();
      expect(filterProvider.activeFilter, isNull);

      final reports = MockData.sampleReports;
      expect(reports.isNotEmpty, isTrue);

      filterProvider.setFilter(DrainageStatus.kritis);
      expect(filterProvider.activeFilter, DrainageStatus.kritis);

      final filtered = filterProvider.filterReports(reports);
      expect(filtered.every((r) => r.status == DrainageStatus.kritis), isTrue);
    });

    test('MockData contains valid sample reports and weather', () {
      expect(MockData.sampleReports.length, greaterThanOrEqualTo(5));
      expect(MockData.currentWeather.condition.isNotEmpty, isTrue);
    });
  });
}

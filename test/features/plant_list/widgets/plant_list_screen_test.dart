// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Widget tests for the plant list feature.
///
/// Ports the Android `compose/plantlist/PlantListTest.kt` test class.
/// Tests that plant list items are displayed correctly and that the
/// provider state is reflected in the UI.
///
/// ## Android equivalence
/// ```kotlin
/// // PlantListTest.kt
/// @Test fun plantList_itemShown() { ... }
/// ```
///
/// Since the Flutter app currently uses placeholder screens, these tests
/// verify the provider state and the data layer that will drive the UI.
/// Widget tests for the full UI will be added once screen widgets are
/// implemented.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/plant_list/providers/plant_list_provider.dart';

import '../../../mocks/mock_repositories.dart';
import '../../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Minimal plant list widget for testing
// ---------------------------------------------------------------------------

/// A minimal plant list widget that renders plant names.
///
/// This mirrors the structure of the Android `PlantListScreen` composable
/// and will be replaced by the real implementation once available.
class _TestPlantListScreen extends StatelessWidget {
  const _TestPlantListScreen({required this.plants, this.onPlantClick});

  final List<Plant> plants;
  final void Function(Plant)? onPlantClick;

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) {
      return const Center(
        key: Key('empty_state'),
        child: Text('No plants found'),
      );
    }
    return ListView.builder(
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return ListTile(
          key: Key('plant_${plant.id}'),
          title: Text(plant.name),
          subtitle: Text('Zone ${plant.growZoneNumber}'),
          onTap: () => onPlantClick?.call(plant),
        );
      },
    );
  }
}

/// A minimal filter chip widget for testing grow zone filtering.
class _TestFilterChip extends StatelessWidget {
  const _TestFilterChip({
    required this.isFiltered,
    required this.onToggle,
  });

  final bool isFiltered;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(isFiltered ? 'Filtered' : 'All Plants'),
        selected: isFiltered,
        onSelected: (_) => onToggle(),
      );
}

void main() {
  late MockPlantRepository mockRepository;

  setUp(() {
    mockRepository = MockPlantRepository();
  });

  // -------------------------------------------------------------------------
  // Plant list item display
  // Mirrors: @Test fun plantList_itemShown()
  // -------------------------------------------------------------------------

  group('PlantListScreen — item display', () {
    testWidgets('displays plant name in list', (WidgetTester tester) async {
      // Arrange — mirrors `startPlantList()` in Android test.
      final List<Plant> plants = [
        Plant(
          id: 'apple',
          name: 'Apple',
          description: 'A fruit tree.',
          growZoneNumber: 5,
          wateringInterval: 3,
          imageUrl: '',
        ),
      ];

      // Act
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantListScreen(plants: plants),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText("Apple").assertIsDisplayed()`
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('displays multiple plants', (WidgetTester tester) async {
      final List<Plant> plants = [
        Plant(
          id: 'apple',
          name: 'Apple',
          description: '',
          growZoneNumber: 5,
          wateringInterval: 3,
          imageUrl: '',
        ),
        Plant(
          id: 'sunflower',
          name: 'Sunflower',
          description: '',
          growZoneNumber: 9,
          wateringInterval: 7,
          imageUrl: '',
        ),
      ];

      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantListScreen(plants: plants),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Sunflower'), findsOneWidget);
    });

    testWidgets('shows empty state when no plants', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const _TestPlantListScreen(plants: []),
        ),
      );

      expect(find.text('No plants found'), findsOneWidget);
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
    });

    testWidgets('displays grow zone number', (WidgetTester tester) async {
      final List<Plant> plants = [
        Plant(
          id: 'sunflower',
          name: 'Sunflower',
          description: '',
          growZoneNumber: 9,
          wateringInterval: 7,
          imageUrl: '',
        ),
      ];

      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantListScreen(plants: plants),
        ),
      );

      expect(find.text('Zone 9'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Click callbacks
  // -------------------------------------------------------------------------

  group('PlantListScreen — click callbacks', () {
    testWidgets('calls onPlantClick when plant is tapped',
        (WidgetTester tester) async {
      final Plant plant = Plant(
        id: 'sunflower',
        name: 'Sunflower',
        description: '',
        growZoneNumber: 9,
        wateringInterval: 7,
        imageUrl: '',
      );
      Plant? clickedPlant;

      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantListScreen(
            plants: [plant],
            onPlantClick: (p) => clickedPlant = p,
          ),
        ),
      );

      await tester.tap(find.text('Sunflower'));
      await tester.pump();

      expect(clickedPlant, equals(plant));
    });
  });

  // -------------------------------------------------------------------------
  // PlantListNotifier integration
  // -------------------------------------------------------------------------

  group('PlantListNotifier — provider integration', () {
    testWidgets('shows plants from provider state', (WidgetTester tester) async {
      final List<Plant> plants = [
        Plant(
          id: 'apple',
          name: 'Apple',
          description: '',
          growZoneNumber: 5,
          wateringInterval: 3,
          imageUrl: '',
        ),
      ];

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => Stream.value(plants));

      final notifier = PlantListNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantListNotifier>.value(
            value: notifier,
            child: Consumer<PlantListNotifier>(
              builder: (context, notifier, _) => _TestPlantListScreen(
                plants: notifier.state.plants,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Apple'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('shows filtered plants when grow zone is set',
        (WidgetTester tester) async {
      final List<Plant> allPlants = [
        Plant(
          id: 'apple',
          name: 'Apple',
          description: '',
          growZoneNumber: 5,
          wateringInterval: 3,
          imageUrl: '',
        ),
        Plant(
          id: 'sunflower',
          name: 'Sunflower',
          description: '',
          growZoneNumber: 9,
          wateringInterval: 7,
          imageUrl: '',
        ),
      ];
      final List<Plant> zone9Plants = [allPlants[1]];

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => Stream.value(allPlants));
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => Stream.value(zone9Plants));

      final notifier = PlantListNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      notifier.setGrowZone(9);
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantListNotifier>.value(
            value: notifier,
            child: Consumer<PlantListNotifier>(
              builder: (context, notifier, _) => _TestPlantListScreen(
                plants: notifier.state.plants,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sunflower'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);

      notifier.dispose();
    });

    testWidgets('filter chip reflects isFiltered state',
        (WidgetTester tester) async {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantListNotifier>.value(
            value: notifier,
            child: Consumer<PlantListNotifier>(
              builder: (context, notifier, _) => _TestFilterChip(
                isFiltered: notifier.state.isFiltered,
                onToggle: notifier.toggleFilter,
              ),
            ),
          ),
        ),
      );

      // Initially unfiltered.
      expect(find.text('All Plants'), findsOneWidget);

      // Tap to filter.
      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      expect(find.text('Filtered'), findsOneWidget);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // PlantListState
  // -------------------------------------------------------------------------

  group('PlantListState — UI state', () {
    test('isFiltered is false when growZone is noFilterGrowZone', () {
      const state = PlantListState(growZone: noFilterGrowZone);
      expect(state.isFiltered, isFalse);
    });

    test('isFiltered is true when growZone is set', () {
      const state = PlantListState(growZone: 9);
      expect(state.isFiltered, isTrue);
    });

    test('plants list is empty by default', () {
      const state = PlantListState();
      expect(state.plants, isEmpty);
    });
  });
}

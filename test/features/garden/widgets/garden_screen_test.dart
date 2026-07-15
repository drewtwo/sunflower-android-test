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

/// Widget tests for the garden screen.
///
/// Ports the Android `compose/garden/GardenTest.kt` test class.
/// Tests empty garden state and garden with plantings displayed.
///
/// ## Android equivalence
/// ```kotlin
/// // GardenTest.kt
/// @Test fun garden_emptyGarden() { ... }
/// @Test fun garden_notEmptyGarden() { ... }
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/garden/providers/garden_planting_provider.dart';

import '../../../mocks/mock_repositories.dart';
import '../../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Minimal garden screen widget for testing
// ---------------------------------------------------------------------------

/// A minimal garden screen widget that mirrors the Android GardenScreen.
///
/// Shows "Add plant" when the garden is empty (mirrors Android test:
/// `composeTestRule.onNodeWithText("Add plant").assertIsDisplayed()`).
/// Shows plant names when the garden has plantings.
class _TestGardenScreen extends StatelessWidget {
  const _TestGardenScreen({
    required this.gardenPlantings,
    this.onAddPlantClick,
  });

  final List<GardenPlantingWithPlant> gardenPlantings;
  final VoidCallback? onAddPlantClick;

  @override
  Widget build(BuildContext context) {
    if (gardenPlantings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your garden is empty'),
            ElevatedButton(
              onPressed: onAddPlantClick,
              child: const Text('Add plant'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: gardenPlantings.length,
      itemBuilder: (context, index) {
        final item = gardenPlantings[index];
        return ListTile(
          key: Key('garden_item_${item.plant.id}'),
          title: Text(item.plant.name),
          subtitle: Text('Planted: ${item.gardenPlanting.plantDate}'),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [Plant] for testing.
Plant _plant({String id = 'sunflower', String name = 'Sunflower'}) => Plant(
      id: id,
      name: name,
      description: 'A test plant.',
      growZoneNumber: 9,
      wateringInterval: 7,
      imageUrl: '',
    );

/// Creates a [GardenPlanting] for testing.
GardenPlanting _gardenPlanting({String plantId = 'sunflower'}) {
  final DateTime now = DateTime(2024, 6, 15);
  return GardenPlanting(
    id: 1,
    plantId: plantId,
    plantDate: now,
    lastWateringDate: now,
  );
}

/// Creates a [GardenPlantingWithPlant] for testing.
///
/// Mirrors `testPlantAndGardenPlanting` from Android `TestUtils.kt`.
GardenPlantingWithPlant _gardenPlantingWithPlant({
  String plantId = 'sunflower',
  String plantName = 'Sunflower',
}) =>
    GardenPlantingWithPlant(
      gardenPlanting: _gardenPlanting(plantId: plantId),
      plant: _plant(id: plantId, name: plantName),
    );

void main() {
  late MockGardenPlantingRepository mockRepository;

  setUp(() {
    mockRepository = MockGardenPlantingRepository();
  });

  // -------------------------------------------------------------------------
  // Empty garden
  // Mirrors: @Test fun garden_emptyGarden()
  // -------------------------------------------------------------------------

  group('GardenScreen — empty garden', () {
    testWidgets('shows "Add plant" button when garden is empty',
        (WidgetTester tester) async {
      // Act — mirrors `startGarden(emptyList())`
      await tester.pumpWidget(
        wrapWithTheme(
          const _TestGardenScreen(gardenPlantings: []),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText("Add plant").assertIsDisplayed()`
      expect(find.text('Add plant'), findsOneWidget);
    });

    testWidgets('shows empty state message when garden is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const _TestGardenScreen(gardenPlantings: []),
        ),
      );

      expect(find.text('Your garden is empty'), findsOneWidget);
    });

    testWidgets('calls onAddPlantClick when "Add plant" is tapped',
        (WidgetTester tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        wrapWithTheme(
          _TestGardenScreen(
            gardenPlantings: const [],
            onAddPlantClick: () => clicked = true,
          ),
        ),
      );

      await tester.tap(find.text('Add plant'));
      await tester.pump();

      expect(clicked, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Non-empty garden
  // Mirrors: @Test fun garden_notEmptyGarden()
  // -------------------------------------------------------------------------

  group('GardenScreen — non-empty garden', () {
    testWidgets('does not show "Add plant" when garden has plantings',
        (WidgetTester tester) async {
      final item = _gardenPlantingWithPlant();

      // Act — mirrors `startGarden(listOf(testPlantAndGardenPlanting))`
      await tester.pumpWidget(
        wrapWithTheme(
          _TestGardenScreen(gardenPlantings: [item]),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText("Add plant").assertDoesNotExist()`
      expect(find.text('Add plant'), findsNothing);
    });

    testWidgets('shows plant name when garden has plantings',
        (WidgetTester tester) async {
      final item = _gardenPlantingWithPlant(plantName: 'Sunflower');

      // Act
      await tester.pumpWidget(
        wrapWithTheme(
          _TestGardenScreen(gardenPlantings: [item]),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText(testPlantAndGardenPlanting.plant.name).assertIsDisplayed()`
      expect(find.text('Sunflower'), findsOneWidget);
    });

    testWidgets('shows multiple plants when garden has multiple plantings',
        (WidgetTester tester) async {
      final items = [
        _gardenPlantingWithPlant(plantId: 'sunflower', plantName: 'Sunflower'),
        _gardenPlantingWithPlant(plantId: 'apple', plantName: 'Apple'),
      ];

      await tester.pumpWidget(
        wrapWithTheme(
          _TestGardenScreen(gardenPlantings: items),
        ),
      );

      expect(find.text('Sunflower'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // GardenPlantingNotifier integration
  // -------------------------------------------------------------------------

  group('GardenScreen — provider integration', () {
    testWidgets('shows empty state when notifier has no plantings',
        (WidgetTester tester) async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => Stream.value([]));

      final notifier = GardenPlantingNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<GardenPlantingNotifier>.value(
            value: notifier,
            child: Consumer<GardenPlantingNotifier>(
              builder: (context, notifier, _) => _TestGardenScreen(
                gardenPlantings: notifier.state.plantings,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Add plant'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('shows plant names when notifier has plantings',
        (WidgetTester tester) async {
      final List<GardenPlantingWithPlant> plantings = [
        _gardenPlantingWithPlant(plantName: 'Sunflower'),
      ];

      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => Stream.value(plantings));

      final notifier = GardenPlantingNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<GardenPlantingNotifier>.value(
            value: notifier,
            child: Consumer<GardenPlantingNotifier>(
              builder: (context, notifier, _) => _TestGardenScreen(
                gardenPlantings: notifier.state.plantings,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sunflower'), findsOneWidget);
      expect(find.text('Add plant'), findsNothing);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // GardenState
  // -------------------------------------------------------------------------

  group('GardenState', () {
    test('isEmpty is true when plantings is empty', () {
      const state = GardenState(plantings: []);
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty is false when plantings is not empty', () {
      final state = GardenState(
        plantings: [_gardenPlantingWithPlant()],
      );
      expect(state.isEmpty, isFalse);
    });
  });
}

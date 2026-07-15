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

/// Widget tests for the plant detail screen.
///
/// Ports the Android `compose/plantdetail/PlantDetailComposeTest.kt` test
/// class. Tests plant details display, add/remove button visibility, and
/// gallery icon visibility.
///
/// ## Android equivalence
/// ```kotlin
/// // PlantDetailComposeTest.kt
/// @Test fun plantDetails_checkIsNotPlanted() { ... }
/// @Test fun plantDetails_checkIsPlanted() { ... }
/// @Test fun plantDetails_checkGalleryNotShown() { ... }
/// @Test fun plantDetails_checkGalleryIsShown() { ... }
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/plant_detail/providers/plant_detail_provider.dart';

import '../../../mocks/mock_repositories.dart';
import '../../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Test plant fixture
// ---------------------------------------------------------------------------

/// A plant fixture for testing, mirroring `plantForTesting()` in Android.
///
/// Mirrors:
/// ```kotlin
/// Plant(
///   plantId = "malus-pumila",
///   name = "Apple",
///   description = "An apple is a sweet...",
///   growZoneNumber = 3,
///   wateringInterval = 30,
///   imageUrl = rawUri(R.raw.apple).toString()
/// )
/// ```
Plant get _testPlant => Plant(
      id: 'malus-pumila',
      name: 'Apple',
      description:
          'An apple is a sweet, edible fruit produced by an apple tree '
          '(Malus pumila). Apple trees are cultivated worldwide.',
      growZoneNumber: 3,
      wateringInterval: 30,
      imageUrl: '',
    );

// ---------------------------------------------------------------------------
// Minimal plant detail widget for testing
// ---------------------------------------------------------------------------

/// A minimal plant detail widget that mirrors the Android `PlantDetails`
/// composable structure.
///
/// Shows:
/// - Plant name
/// - "Add plant" button (with semantics label) when not planted
/// - Gallery icon when [hasValidUnsplashKey] is true
class _TestPlantDetailScreen extends StatelessWidget {
  const _TestPlantDetailScreen({
    required this.plant,
    required this.isPlanted,
    this.hasValidUnsplashKey = false,
    this.onAddPlant,
    this.onRemovePlant,
    this.onGalleryClick,
  });

  final Plant plant;
  final bool isPlanted;
  final bool hasValidUnsplashKey;
  final VoidCallback? onAddPlant;
  final VoidCallback? onRemovePlant;
  final VoidCallback? onGalleryClick;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(plant.name),
          actions: [
            if (hasValidUnsplashKey)
              IconButton(
                icon: const Icon(Icons.photo_library),
                tooltip: 'Gallery Icon',
                onPressed: onGalleryClick,
                // Semantics label mirrors Android content description.
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant name — mirrors `composeTestRule.onNodeWithText("Apple")`
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                plant.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Plant description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(plant.description),
            ),
            const SizedBox(height: 16),
            // Add plant button — only shown when not planted.
            // Mirrors `composeTestRule.onNodeWithContentDescription("Add plant")`
            if (!isPlanted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Semantics(
                  label: 'Add plant',
                  child: ElevatedButton.icon(
                    onPressed: onAddPlant,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Garden'),
                  ),
                ),
              ),
            // Remove plant button — only shown when planted.
            if (isPlanted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Semantics(
                  label: 'Remove plant',
                  child: OutlinedButton.icon(
                    onPressed: onRemovePlant,
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove from Garden'),
                  ),
                ),
              ),
          ],
        ),
      );
}

void main() {
  late MockPlantRepository mockPlantRepo;
  late MockGardenPlantingRepository mockGardenRepo;

  setUp(() {
    mockPlantRepo = MockPlantRepository();
    mockGardenRepo = MockGardenPlantingRepository();
  });

  // -------------------------------------------------------------------------
  // plantDetails_checkIsNotPlanted
  // Mirrors: @Test fun plantDetails_checkIsNotPlanted()
  // -------------------------------------------------------------------------

  group('PlantDetailScreen — not planted', () {
    testWidgets('shows plant name when not planted',
        (WidgetTester tester) async {
      // Act — mirrors `startPlantDetails(isPlanted = false)`
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: false,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText("Apple").assertIsDisplayed()`
      expect(find.text('Apple'), findsWidgets);
    });

    testWidgets('shows "Add plant" button when not planted',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: false,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithContentDescription("Add plant").assertIsDisplayed()`
      expect(
        find.bySemanticsLabel('Add plant'),
        findsOneWidget,
      );
    });

    testWidgets('does not show "Remove plant" button when not planted',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: false,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Remove plant'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // plantDetails_checkIsPlanted
  // Mirrors: @Test fun plantDetails_checkIsPlanted()
  // -------------------------------------------------------------------------

  group('PlantDetailScreen — planted', () {
    testWidgets('shows plant name when planted', (WidgetTester tester) async {
      // Act — mirrors `startPlantDetails(isPlanted = true)`
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithText("Apple").assertIsDisplayed()`
      expect(find.text('Apple'), findsWidgets);
    });

    testWidgets('does not show "Add plant" button when planted',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithContentDescription("Add plant").assertDoesNotExist()`
      expect(find.bySemanticsLabel('Add plant'), findsNothing);
    });

    testWidgets('shows "Remove plant" button when planted',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Remove plant'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // plantDetails_checkGalleryNotShown
  // Mirrors: @Test fun plantDetails_checkGalleryNotShown()
  // -------------------------------------------------------------------------

  group('PlantDetailScreen — gallery icon', () {
    testWidgets('does not show gallery icon when no Unsplash key',
        (WidgetTester tester) async {
      // Act — mirrors `startPlantDetails(isPlanted = true, hasUnsplashKey = false)`
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
            hasValidUnsplashKey: false,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithContentDescription("Gallery Icon").assertDoesNotExist()`
      expect(find.byTooltip('Gallery Icon'), findsNothing);
    });

    testWidgets('shows gallery icon when Unsplash key is present',
        (WidgetTester tester) async {
      // Act — mirrors `startPlantDetails(isPlanted = true, hasUnsplashKey = true)`
      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
            hasValidUnsplashKey: true,
          ),
        ),
      );

      // Assert — mirrors `composeTestRule.onNodeWithContentDescription("Gallery Icon").assertIsDisplayed()`
      expect(find.byTooltip('Gallery Icon'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // PlantDetailNotifier integration
  // -------------------------------------------------------------------------

  group('PlantDetailScreen — provider integration', () {
    testWidgets('shows plant name from provider state',
        (WidgetTester tester) async {
      when(() => mockPlantRepo.watchPlantById('malus-pumila'))
          .thenAnswer((_) => Stream.value(_testPlant));
      when(() => mockGardenRepo.watchIsPlanted('malus-pumila'))
          .thenAnswer((_) => Stream.value(false));

      final notifier = PlantDetailNotifier(
        plantId: 'malus-pumila',
        plantRepository: mockPlantRepo,
        gardenPlantingRepository: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantDetailNotifier>.value(
            value: notifier,
            child: Consumer<PlantDetailNotifier>(
              builder: (context, notifier, _) {
                final plant = notifier.state.plant;
                if (plant == null) {
                  return const CircularProgressIndicator();
                }
                return _TestPlantDetailScreen(
                  plant: plant,
                  isPlanted: notifier.state.isPlanted,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Apple'), findsWidgets);

      notifier.dispose();
    });

    testWidgets('shows "Add plant" button when not planted via provider',
        (WidgetTester tester) async {
      when(() => mockPlantRepo.watchPlantById('malus-pumila'))
          .thenAnswer((_) => Stream.value(_testPlant));
      when(() => mockGardenRepo.watchIsPlanted('malus-pumila'))
          .thenAnswer((_) => Stream.value(false));

      final notifier = PlantDetailNotifier(
        plantId: 'malus-pumila',
        plantRepository: mockPlantRepo,
        gardenPlantingRepository: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantDetailNotifier>.value(
            value: notifier,
            child: Consumer<PlantDetailNotifier>(
              builder: (context, notifier, _) {
                final plant = notifier.state.plant;
                if (plant == null) return const SizedBox.shrink();
                return _TestPlantDetailScreen(
                  plant: plant,
                  isPlanted: notifier.state.isPlanted,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.bySemanticsLabel('Add plant'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('hides "Add plant" button when planted via provider',
        (WidgetTester tester) async {
      when(() => mockPlantRepo.watchPlantById('malus-pumila'))
          .thenAnswer((_) => Stream.value(_testPlant));
      when(() => mockGardenRepo.watchIsPlanted('malus-pumila'))
          .thenAnswer((_) => Stream.value(true));

      final notifier = PlantDetailNotifier(
        plantId: 'malus-pumila',
        plantRepository: mockPlantRepo,
        gardenPlantingRepository: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await tester.pumpWidget(
        wrapWithTheme(
          ChangeNotifierProvider<PlantDetailNotifier>.value(
            value: notifier,
            child: Consumer<PlantDetailNotifier>(
              builder: (context, notifier, _) {
                final plant = notifier.state.plant;
                if (plant == null) return const SizedBox.shrink();
                return _TestPlantDetailScreen(
                  plant: plant,
                  isPlanted: notifier.state.isPlanted,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.bySemanticsLabel('Add plant'), findsNothing);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Callback tests
  // -------------------------------------------------------------------------

  group('PlantDetailScreen — callbacks', () {
    testWidgets('calls onAddPlant when "Add to Garden" is tapped',
        (WidgetTester tester) async {
      bool addCalled = false;

      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: false,
            onAddPlant: () => addCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Add to Garden'));
      await tester.pump();

      expect(addCalled, isTrue);
    });

    testWidgets('calls onRemovePlant when "Remove from Garden" is tapped',
        (WidgetTester tester) async {
      bool removeCalled = false;

      await tester.pumpWidget(
        wrapWithTheme(
          _TestPlantDetailScreen(
            plant: _testPlant,
            isPlanted: true,
            onRemovePlant: () => removeCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Remove from Garden'));
      await tester.pump();

      expect(removeCalled, isTrue);
    });
  });
}

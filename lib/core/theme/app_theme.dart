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

/// Material 3 theme configuration for the Sunflower Flutter app.
///
/// Provides [sunflowerLightTheme] and [sunflowerDarkTheme] [ThemeData]
/// instances, and the [SunflowerTheme] convenience widget that selects
/// between them based on the system brightness.
///
/// Color tokens are sourced from [AppColors] (ported from Android
/// `ui/Color.kt`). Typography is sourced from [sunflowerTextTheme]
/// (ported from Android `ui/Type.kt`). Shapes mirror the Android
/// `ui/Shapes.kt` definitions.
library;

import 'package:flutter/material.dart';
import 'package:sunflower_flutter/core/theme/app_colors.dart';
import 'package:sunflower_flutter/core/theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Shape tokens — ported from Android ui/Shapes.kt
// ---------------------------------------------------------------------------

/// The [ShapeBorder] used for small components (cards, chips, etc.).
///
/// Mirrors the Android `Shapes.small` definition:
/// top-start = 0 dp, top-end = 12 dp, bottom-start = 12 dp, bottom-end = 0 dp.
const RoundedRectangleBorder _smallShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.zero,
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.zero,
  ),
);

/// The [ShapeBorder] used for medium components (dialogs, bottom sheets, etc.).
///
/// Mirrors the Android `Shapes.medium` definition (same radii as small).
const RoundedRectangleBorder _mediumShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.zero,
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.zero,
  ),
);

// ---------------------------------------------------------------------------
// Light color scheme
// ---------------------------------------------------------------------------

/// The Material 3 [ColorScheme] for the light theme.
const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: mdThemeLightPrimary,
  onPrimary: mdThemeLightOnPrimary,
  primaryContainer: mdThemeLightPrimaryContainer,
  onPrimaryContainer: mdThemeLightOnPrimaryContainer,
  secondary: mdThemeLightSecondary,
  onSecondary: mdThemeLightOnSecondary,
  secondaryContainer: mdThemeLightSecondaryContainer,
  onSecondaryContainer: mdThemeLightOnSecondaryContainer,
  tertiary: mdThemeLightTertiary,
  onTertiary: mdThemeLightOnTertiary,
  tertiaryContainer: mdThemeLightTertiaryContainer,
  onTertiaryContainer: mdThemeLightOnTertiaryContainer,
  error: mdThemeLightError,
  errorContainer: mdThemeLightErrorContainer,
  onError: mdThemeLightOnError,
  onErrorContainer: mdThemeLightOnErrorContainer,
  surface: mdThemeLightSurface,
  onSurface: mdThemeLightOnSurface,
  surfaceContainerHighest: mdThemeLightSurfaceVariant,
  onSurfaceVariant: mdThemeLightOnSurfaceVariant,
  outline: mdThemeLightOutline,
  outlineVariant: mdThemeLightOutlineVariant,
  shadow: mdThemeLightShadow,
  scrim: mdThemeLightScrim,
  inverseSurface: mdThemeLightInverseSurface,
  onInverseSurface: mdThemeLightInverseOnSurface,
  inversePrimary: mdThemeLightInversePrimary,
  surfaceTint: mdThemeLightSurfaceTint,
);

// ---------------------------------------------------------------------------
// Dark color scheme
// ---------------------------------------------------------------------------

/// The Material 3 [ColorScheme] for the dark theme.
const ColorScheme _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: mdThemeDarkPrimary,
  onPrimary: mdThemeDarkOnPrimary,
  primaryContainer: mdThemeDarkPrimaryContainer,
  onPrimaryContainer: mdThemeDarkOnPrimaryContainer,
  secondary: mdThemeDarkSecondary,
  onSecondary: mdThemeDarkOnSecondary,
  secondaryContainer: mdThemeDarkSecondaryContainer,
  onSecondaryContainer: mdThemeDarkOnSecondaryContainer,
  tertiary: mdThemeDarkTertiary,
  onTertiary: mdThemeDarkOnTertiary,
  tertiaryContainer: mdThemeDarkTertiaryContainer,
  onTertiaryContainer: mdThemeDarkOnTertiaryContainer,
  error: mdThemeDarkError,
  errorContainer: mdThemeDarkErrorContainer,
  onError: mdThemeDarkOnError,
  onErrorContainer: mdThemeDarkOnErrorContainer,
  surface: mdThemeDarkSurface,
  onSurface: mdThemeDarkOnSurface,
  surfaceContainerHighest: mdThemeDarkSurfaceVariant,
  onSurfaceVariant: mdThemeDarkOnSurfaceVariant,
  outline: mdThemeDarkOutline,
  outlineVariant: mdThemeDarkOutlineVariant,
  shadow: mdThemeDarkShadow,
  scrim: mdThemeDarkScrim,
  inverseSurface: mdThemeDarkInverseSurface,
  onInverseSurface: mdThemeDarkInverseOnSurface,
  inversePrimary: mdThemeDarkInversePrimary,
  surfaceTint: mdThemeDarkSurfaceTint,
);

// ---------------------------------------------------------------------------
// ThemeData instances
// ---------------------------------------------------------------------------

/// The [ThemeData] for the light variant of the Sunflower theme.
///
/// Uses Material 3 with the Sunflower color scheme, typography, and shapes.
final ThemeData sunflowerLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  textTheme: sunflowerTextTheme,
  cardTheme: CardThemeData(
    shape: _smallShape,
    clipBehavior: Clip.antiAlias,
    elevation: 2,
  ),
  dialogTheme: DialogThemeData(shape: _mediumShape),
  bottomSheetTheme: const BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 4,
  ),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: mdThemeLightPrimaryContainer,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    shape: CircleBorder(),
  ),
);

/// The [ThemeData] for the dark variant of the Sunflower theme.
///
/// Uses Material 3 with the Sunflower dark color scheme, typography, and shapes.
final ThemeData sunflowerDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  textTheme: sunflowerTextTheme,
  cardTheme: CardThemeData(
    shape: _smallShape,
    clipBehavior: Clip.antiAlias,
    elevation: 2,
  ),
  dialogTheme: DialogThemeData(shape: _mediumShape),
  bottomSheetTheme: const BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 4,
  ),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: mdThemeDarkPrimaryContainer,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    shape: CircleBorder(),
  ),
);

// ---------------------------------------------------------------------------
// Convenience widget
// ---------------------------------------------------------------------------

/// A widget that applies the Sunflower Material 3 theme to its [child].
///
/// Automatically selects [sunflowerLightTheme] or [sunflowerDarkTheme]
/// based on the current system brightness, unless [darkTheme] is
/// explicitly provided.
///
/// Example:
/// ```dart
/// SunflowerTheme(
///   child: MaterialApp.router(routerConfig: appRouter),
/// )
/// ```
class SunflowerTheme extends StatelessWidget {
  /// Creates a [SunflowerTheme] widget.
  const SunflowerTheme({
    required this.child,
    super.key,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

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

/// Root widget for the Sunflower Flutter app.
///
/// [SunflowerApp] is the top-level [StatelessWidget] that wires together:
/// - Material 3 theming ([sunflowerLightTheme] / [sunflowerDarkTheme])
/// - Navigation ([appRouter] via go_router)
/// - Localization ([GlobalMaterialLocalizations], [GlobalWidgetsLocalizations])
///
/// It is intentionally kept thin — all business logic lives in feature
/// modules and the DI layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sunflower_flutter/core/theme/app_theme.dart';
import 'package:sunflower_flutter/navigation/app_routes.dart';

/// The root widget of the Sunflower app.
///
/// Wrap this in [ProviderScope] (if using Riverpod) or [MultiProvider]
/// (if using provider) at the call site in [main] once state management
/// is wired up.
class SunflowerApp extends StatelessWidget {
  /// Creates the [SunflowerApp] widget.
  const SunflowerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        // -----------------------------------------------------------------------
        // App metadata
        // -----------------------------------------------------------------------
        title: 'Sunflower',
        debugShowCheckedModeBanner: false,

        // -----------------------------------------------------------------------
        // Theming — Material 3 with Sunflower color scheme
        // -----------------------------------------------------------------------
        theme: sunflowerLightTheme,
        darkTheme: sunflowerDarkTheme,
        themeMode: ThemeMode.system,

        // -----------------------------------------------------------------------
        // Navigation — go_router
        // -----------------------------------------------------------------------
        routerConfig: appRouter,

        // -----------------------------------------------------------------------
        // Localization
        // -----------------------------------------------------------------------
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('en'),
          Locale('de'),
          Locale('es'),
          Locale('fr'),
          Locale('it'),
          Locale('ja'),
          Locale('pt'),
          Locale('ru'),
          Locale('sv'),
          Locale('tr'),
          Locale('vi'),
          Locale('zh'),
          Locale('bn'),
          Locale('ca'),
        ],
      );
}

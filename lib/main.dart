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

/// Entry point for the Sunflower Flutter app.
///
/// ## Startup sequence
/// 1. [WidgetsFlutterBinding.ensureInitialized] — required before any
///    async work in `main`.
/// 2. [ServiceLocator.setup] — registers all get_it singletons (database,
///    HTTP client, repositories). Awaited so the database is ready before
///    the first frame.
/// 3. [runApp] — mounts the widget tree with [SunflowerApp] as the root.
///
/// ## Environment configuration
/// The Unsplash API key is injected at build time via `--dart-define`:
/// ```
/// flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
/// ```
/// See [AppConstants.unsplashAccessKey] and [README_FLUTTER.md] for details.
library;

import 'package:flutter/material.dart';
import 'package:sunflower_flutter/app/app.dart';
import 'package:sunflower_flutter/di/service_locator.dart';

/// Application entry point.
Future<void> main() async {
  // Required before any async work or plugin usage.
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the dependency injection container.
  // This registers the database, HTTP client, and repositories.
  await ServiceLocator.setup();

  // Mount the widget tree.
  runApp(const SunflowerApp());
}

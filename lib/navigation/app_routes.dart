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

/// go_router configuration for the Sunflower app.
///
/// Defines all routes, nested navigation for the bottom tab bar, and
/// deep-linking strategy. Mirrors the Android Navigation Compose graph
/// defined in `compose/SunflowerApp.kt` and `compose/Screen.kt`.
///
/// ## Route structure
/// ```
/// /                         → redirect → /home/plant-list
/// /home                     → HomeScreen (bottom nav shell)
///   /home/plant-list        → PlantListScreen  (tab 0)
///   /home/garden            → GardenScreen     (tab 1)
/// /plant/:plantId           → PlantDetailScreen
/// /gallery?plantName=...    → GalleryScreen
/// ```
///
/// ## Deep linking
/// The router supports deep links via the `go_router` package's built-in
/// deep-link handling. No additional configuration is required for Android
/// (handled by `AndroidManifest.xml` intent filters) or iOS (handled by
/// `Info.plist` URL schemes / Associated Domains).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunflower_flutter/navigation/route_paths.dart';

// ---------------------------------------------------------------------------
// Placeholder screen widgets
// ---------------------------------------------------------------------------
// These will be replaced by real screen implementations as each feature
// module is built out.

/// Temporary placeholder for the Home shell screen.
class _HomeShellScreen extends StatelessWidget {
  const _HomeShellScreen({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (int index) =>
              navigationShell.goBranch(index),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.yard_outlined),
              selectedIcon: Icon(Icons.yard),
              label: 'Plants',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_florist_outlined),
              selectedIcon: Icon(Icons.local_florist),
              label: 'My Garden',
            ),
          ],
        ),
      );
}

/// Temporary placeholder for the Plant List screen.
class _PlantListPlaceholder extends StatelessWidget {
  const _PlantListPlaceholder();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Plant List — coming soon')),
      );
}

/// Temporary placeholder for the Garden screen.
class _GardenPlaceholder extends StatelessWidget {
  const _GardenPlaceholder();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('My Garden — coming soon')),
      );
}

/// Temporary placeholder for the Plant Detail screen.
class _PlantDetailPlaceholder extends StatelessWidget {
  const _PlantDetailPlaceholder({required this.plantId});
  final String plantId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(plantId)),
        body: const Center(child: Text('Plant Detail — coming soon')),
      );
}

/// Temporary placeholder for the Gallery screen.
class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder({required this.plantName});
  final String plantName;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('$plantName photos')),
        body: const Center(child: Text('Gallery — coming soon')),
      );
}

// ---------------------------------------------------------------------------
// Router configuration
// ---------------------------------------------------------------------------

/// The [GoRouter] instance for the Sunflower app.
///
/// Use this as the `routerConfig` parameter of [MaterialApp.router].
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.plantList,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    // -------------------------------------------------------------------------
    // Root redirect
    // -------------------------------------------------------------------------
    GoRoute(
      path: RoutePaths.root,
      redirect: (_, __) => RoutePaths.plantList,
    ),

    // -------------------------------------------------------------------------
    // Home shell with bottom navigation (StatefulShellRoute)
    // -------------------------------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) =>
          _HomeShellScreen(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        // Branch 0 — Plant List
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RoutePaths.plantList,
              name: RouteNames.plantList,
              builder: (_, __) => const _PlantListPlaceholder(),
            ),
          ],
        ),

        // Branch 1 — My Garden
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RoutePaths.garden,
              name: RouteNames.garden,
              builder: (_, __) => const _GardenPlaceholder(),
            ),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    // Plant Detail (outside the shell — full-screen)
    // -------------------------------------------------------------------------
    GoRoute(
      path: RoutePaths.plantDetail,
      name: RouteNames.plantDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String plantId = state.pathParameters['plantId'] ?? '';
        return _PlantDetailPlaceholder(plantId: plantId);
      },
    ),

    // -------------------------------------------------------------------------
    // Gallery (outside the shell — full-screen)
    // -------------------------------------------------------------------------
    GoRoute(
      path: RoutePaths.gallery,
      name: RouteNames.gallery,
      builder: (BuildContext context, GoRouterState state) {
        final String plantName =
            state.uri.queryParameters['plantName'] ?? '';
        return _GalleryPlaceholder(plantName: plantName);
      },
    ),
  ],

  // Global error builder — shown when a route is not found.
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);

// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Uncomment the following lines when enabling Firebase Crashlytics
// import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'src/app_lifecycle/app_lifecycle.dart';
import 'src/audio/audio_controller.dart';
import 'src/crashlytics/crashlytics.dart';
import 'src/games_services/score.dart';
import 'src/level_selection/level_selection_screen.dart';
import 'src/level_selection/levels.dart';
import 'src/main_menu/main_menu_screen.dart';
import 'src/play_session/play_session_screen.dart';
import 'src/player_progress/persistence/local_storage_player_progress_persistence.dart';
import 'src/player_progress/persistence/player_progress_persistence.dart';
import 'src/player_progress/player_progress.dart';
import 'src/settings/persistence/local_storage_settings_persistence.dart';
import 'src/settings/persistence/settings_persistence.dart';
import 'src/settings/settings.dart';
import 'src/settings/settings_screen.dart';
import 'src/style/my_transition.dart';
import 'src/style/palette.dart';
import 'src/style/snack_bar.dart';
import 'src/win_game/win_game_screen.dart';

Future<void> main() async {
  // To enable Firebase Crashlytics, uncomment the following lines and
  // the import statements at the top of this file.
  // See the 'Crashlytics' section of the main README.md file for details.

  FirebaseCrashlytics? crashlytics;
  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   try {
  //     WidgetsFlutterBinding.ensureInitialized();
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //     crashlytics = FirebaseCrashlytics.instance;
  //   } catch (e) {
  //     debugPrint("Firebase couldn't be initialized: $e");
  //   }
  // }

  await guardWithCrashlytics(
    guardedMain,
    crashlytics: crashlytics,
  );
}

/// Without logging and crash reporting, this would be `void main()`.
void guardedMain() {
  WidgetsFlutterBinding.ensureInitialized();

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

runApp(
    MyApp(
      settingsPersistence: LocalStorageSettingsPersistence(),
      playerProgressPersistence: LocalStoragePlayerProgressPersistence(),
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatelessWidget {
  static final _router = GoRouter(
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) =>
              const MainMenuScreen(key: Key('main menu')),
          routes: [
            GoRoute(
                path: 'play',
                pageBuilder: (context, state) => buildMyTransition<void>(
                      key: ValueKey('play'),
                      child: const LevelSelectionScreen(
                        key: Key('level selection'),
                      ),
                      color: context.watch<Palette>().backgroundLevelSelection,
                    ),
                routes: [
                  GoRoute(
                    path: 'session/:level',
                    pageBuilder: (context, state) {
                      final levelNumber =
                          int.parse(state.pathParameters['level']!);
                      final level = gameLevels
                          .singleWhere((e) => e.number == levelNumber);
                      return buildMyTransition<void>(
                        key: ValueKey('level'),
                        child: PlaySessionScreen(
                          level,
                          key: const Key('play session'),
                        ),
                        color: context.watch<Palette>().backgroundPlaySession,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'won',
                    redirect: (context, state) {
                      if (state.extra == null) {
                        // Trying to navigate to a win screen without any data.
                        // Possibly by using the browser's back button.
                        return '/';
                      }

                      // Otherwise, do not redirect.
                      return null;
                    },
                    pageBuilder: (context, state) {
                      final mapScore = state.extra! as Map<String, dynamic>;
                      final score = mapScore['score'] as Score;

                      final mapLevel = state.extra! as Map<String, dynamic>;
                      final level = mapLevel['level'] as int;

                      return buildMyTransition<void>(
                        key: ValueKey('won'),
                        child: WinGameScreen(
                          score: score,
                          level: level,
                          key: const Key('win game'),
                        ),
                        color: context.watch<Palette>().backgroundPlaySession,
                      );
                    },
                  )
                ]),
            GoRoute(
              path: 'settings',
              builder: (context, state) =>
                  const SettingsScreen(key: Key('settings')),
            ),
          ]),
    ],
  );

  final PlayerProgressPersistence playerProgressPersistence;

  final SettingsPersistence settingsPersistence;

  const MyApp({
    required this.playerProgressPersistence,
    required this.settingsPersistence,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) {
              var progress = PlayerProgress(playerProgressPersistence);
              progress.getLatestFromStore();
              return progress;
            },
          ),
          Provider<SettingsController>(
            lazy: false,
            create: (context) => SettingsController(
              persistence: settingsPersistence,
            )..loadStateFromPersistence(),
          ),
          ProxyProvider2<SettingsController, ValueNotifier<AppLifecycleState>,
              AudioController>(
            // Ensures that the AudioController is created on startup,
            // and not "only when it's needed", as is default behavior.
            // This way, music starts immediately.
            lazy: false,
            create: (context) => AudioController()..initialize(),
            update: (context, settings, lifecycleNotifier, audio) {
              if (audio == null) throw ArgumentError.notNull();
              audio.attachSettings(settings);
              audio.attachLifecycleNotifier(lifecycleNotifier);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
          ),
          Provider(
            create: (context) => Palette(),
          ),
        ],
        child: Builder(builder: (context) {
          final palette = context.watch<Palette>();

          return MaterialApp.router(
            title: 'Flutter Demo',
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: palette.mediumGreen,
                background: palette.cream,
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(
                  color: palette.ink,
                ),
              ),
              useMaterial3: true,
            ),
            routeInformationProvider: _router.routeInformationProvider,
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
            scaffoldMessengerKey: scaffoldMessengerKey,
          );
        }),
      ),
    );
  }
}

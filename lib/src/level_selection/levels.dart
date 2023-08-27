// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const gameLevels = [
  GameLevel(
    number: 1,
    width: 5,
    height: 7,
    mines: 6,
    difficulty: 5,
    // TODO: When ready, change these achievement IDs.
    // You configure this in App Store Connect.
    //achievementIdIOS: 'first_win',
    // You get this string when you configure an achievement in Play Console.
    //achievementIdAndroid: 'NhkIwB69ejkMAOOLDb',
  ),
  GameLevel(
    number: 2,
    width: 7,
    height: 10,
    mines: 20,
    difficulty: 42,
  ),
  GameLevel(
    number: 3,
    width: 10,
    height: 15,
    mines: 25,
    difficulty: 100,
  ),
  GameLevel(
    number: 4,
    width: 2,
    height: 2,
    mines: 1,
    difficulty: 100,
  ),
];

class GameLevel {
  final int number;
  final int width;
  final int height;
  final int mines;

  final int difficulty;

  /// The achievement to unlock when the level is finished, if any.
  final String? achievementIdIOS;

  final String? achievementIdAndroid;

  bool get awardsAchievement => achievementIdAndroid != null;

  const GameLevel({
    required this.number,
    required this.width,
    required this.height,
    required this.difficulty,
    required this.mines,
    this.achievementIdIOS,
    this.achievementIdAndroid,
  })  : assert(
            (achievementIdAndroid != null && achievementIdIOS != null) ||
                (achievementIdAndroid == null && achievementIdIOS == null),
            'Either both iOS and Android achievement ID must be provided, '
            'or none'),
        assert(width > 0 && height > 0 && (height * width) > mines,
            'Invalid level configuration (mines >= cells or no positive dimensions)');
}

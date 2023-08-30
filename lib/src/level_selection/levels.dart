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

  const GameLevel({
    required this.number,
    required this.width,
    required this.height,
    required this.difficulty,
    required this.mines,
  })  : assert(width > 0 && height > 0 && (height * width) > mines,
            'Invalid level configuration (mines >= cells or no positive dimensions)');
}

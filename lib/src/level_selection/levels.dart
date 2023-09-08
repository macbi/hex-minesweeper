// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Type {
  square,
  hexagon,
}

const gameLevels = [
  GameLevel(
    number: 1,
    width: 5,
    height: 7,
    mines: 6,
    type: Type.square,
  ),
  GameLevel(
    number: 2,
    width: 7,
    height: 10,
    mines: 12,
    type: Type.square,
  ),
  GameLevel(
    number: 3,
    width: 10,
    height: 15,
    mines: 18,
    type: Type.square,
  ),
  GameLevel(
    number: 4,
    width: 2,
    height: 2,
    mines: 3,
    type: Type.square,
  ),
  GameLevel(
    number: 5,
    width: 5,
    height: 7,
    mines: 6,
    type: Type.hexagon,
  ),
  GameLevel(
    number: 6,
    width: 7,
    height: 10,
    mines: 12,
    type: Type.hexagon,
  ),
];

class GameLevel {
  final int number;
  final int width;
  final int height;
  final int mines;
  final Type type;


  const GameLevel({
    required this.number,
    required this.width,
    required this.height,
    required this.mines,
    required this.type,
  })  : assert(width > 0 && height > 0 && (height * width) > mines,
            'Invalid level configuration (mines >= cells or no positive dimensions)');
}

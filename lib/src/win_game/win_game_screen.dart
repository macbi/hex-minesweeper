// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../games_services/score.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import '../level_selection/levels.dart';

class WinGameScreen extends StatelessWidget {
  final Score score;
  final int level;

  const WinGameScreen({
    super.key,
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final levelNumber = gameLevels.length;

    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Center(
              child: Text(
                'You won!',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
            Center(
              child: Text(
                'Time: ${score.formattedTime}',
                style: const TextStyle(fontFamily: 'Permanent Marker', fontSize: 20),
              ),
            ),
          ],
        ),
        rectangularMenuArea: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                  onPressed: () {
                    GoRouter.of(context).go('/');
                  },
                  child: const Text('Main Menu')
              ),
              FilledButton(
                onPressed: () {
                  GoRouter.of(context).go(level<levelNumber ? '/play/session/${level + 1}': '/play');
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

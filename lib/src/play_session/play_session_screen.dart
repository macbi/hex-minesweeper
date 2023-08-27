// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_template/src/play_session/cell.dart';
import 'package:game_template/src/play_session/cell_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';
import 'dart:math';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/level_state.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  @override
  void initState() {
    super.initState();
    generateGrid();

    _startOfPlay = DateTime.now();

    // Preload ad for the win screen.
    final adsRemoved = context.read<InAppPurchaseController?>()?.adRemoval.active ?? false;
    if (!adsRemoved) {
      final adsController = context.read<AdsController?>();
      adsController?.preloadAd();
    }
  }

  Widget buildButton(CellModel cell) {
    return GestureDetector(
        onTap: () {
          _log.info('Cell (${cell.x}, ${cell.y}) tapped');
          _revealCell(cell);
        },
        onLongPress: () {
          _markFlagged(cell);
        },
        child: CellWidget(size: width, cell: cell));
  }

  void _markFlagged(CellModel cell) {
    if (cell.isRevealed) return;
    setState(() {
      cell.isFlagged = !cell.isFlagged;
    });
  }

  var width = 8;
  var height = 8;
  var cells = [];
  var totalCellsRevealed = 0;
  var totalMines = 6;

  void generateGrid() {
    cells = [];
    totalCellsRevealed = 0;
    totalMines = widget.level.mines;
    height = widget.level.height;
    width = widget.level.width;

    for (int i = 0; i < width; i++) {
      List<CellModel> row = [];
      for (int j = 0; j < height; j++) {
        final cell = CellModel(i, j);
        row.add(cell);
      }
      cells.add(row);
    }

    // Marking mines
    for (int i = 0; i < totalMines; i++) {
      var x = Random().nextInt(width);
      var y = Random().nextInt(height);
      if (cells[x][y].isMine) {
        i--;
      }
      cells[x][y].isMine = true;
    }

    //  add numbers to cells
    for (int i = 0; i < width; ++i) {
      for (int j = 0; j < height; ++j) {
        for (CellModel cell in getCellNeighbourhood(cells[i][j])) {
          if (cell.isMine) {
            cells[i][j].value++;
          }
        }
      }
    }
  }

  List<CellModel> getCellNeighbourhood(CellModel cell) {
    List<CellModel> neighbours = [];
    for (int i = max(0, cell.x - 1); i <= min(width - 1, cell.x + 1); ++i) {
      for (int j = max(0, cell.y - 1); j <= min(height - 1, cell.y + 1); ++j) {
        if (i == cell.x && j == cell.y) continue;
        neighbours.add(cells[i][j]);
      }
    }
    return neighbours;
  }

  Row buildButtonRow(int column) {
    List<Widget> list = [];

    for (int i = 0; i < width; i++) {
      list.add(
        Expanded(
          child: buildButton(cells[i][column]),
        ),
      );
    }

    return Row(
      children: list,
    );
  }

  Column buildButtonColumn() {
    List<Widget> rows = [];

    for (int i = 0; i < height; i++) {
      rows.add(
        buildButtonRow(i),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: rows,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LevelState(
            goal: widget.level.mines,
            onWin: _playerWon,
          ),
        ),
      ],
      child: IgnorePointer(
        ignoring: _duringCelebration,
        child: Scaffold(
          backgroundColor: palette.backgroundPlaySession,
          body: Stack(
            children: [
              Center(
                // This is the entirety of the "game".
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        margin: const EdgeInsets.all(1.0),
                        child: buildButtonColumn(),
                      ),
                    ),
                    //const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => GoRouter.of(context).go('/play'),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox.expand(
                child: Visibility(
                  visible: _duringCelebration,
                  child: IgnorePointer(
                    child: Confetti(
                      isStopped: !_duringCelebration,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playerWon() async {
    _log.info('Level ${widget.level.number} won');

    final score = Score(
      widget.level.number,
      widget.level.difficulty,
      DateTime.now().difference(_startOfPlay),
    );

    final playerProgress = context.read<PlayerProgress>();
    playerProgress.setLevelReached(widget.level.number);

    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    final gamesServicesController = context.read<GamesServicesController?>();
    if (gamesServicesController != null) {
      // Award achievement.
      if (widget.level.awardsAchievement) {
        await gamesServicesController.awardAchievement(
          android: widget.level.achievementIdAndroid!,
          iOS: widget.level.achievementIdIOS!,
        );
      }

      // Send score to leaderboard.
      await gamesServicesController.submitLeaderboardScore(score);
    }

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }

  void _revealCell(CellModel cell) {
    if (cell.isRevealed || cell.isFlagged) return;

    if (cell.isMine && totalCellsRevealed == 0) {
      //TODO implement lack of mine on first click
    }

    setState(() {
      cell.isRevealed = true;
    });

    if (cell.isMine && totalCellsRevealed > 0) {
      _log.info('Level ${widget.level.number} lost');
      _showGameOverDialog();
      return;
    }

    totalCellsRevealed++;

    if (totalCellsRevealed == (width * height) - totalMines) {
      //TODO implement win
    }

    if (cell.value == 0) {
      for (CellModel neighbour in getCellNeighbourhood(cell)) {
        _revealCell(neighbour);
      }
    }
  }

  void _showGameOverDialog() {
    //TODO implement dialog with restart and back to menu
  }
}

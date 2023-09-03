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

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/level_state.dart';
import '../games_services/score.dart';
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

  static const _postLoseDuration = Duration(milliseconds: 1000);

  bool _duringCelebration = false;

  bool _duringLose = false;

  bool _firstReveal = false;

  late DateTime _startOfPlay;

  @override
  void initState() {
    super.initState();
    generateGrid();
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

  int width = 0;
  int height = 0;
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
  }

  void generateMines(CellModel cell) {
    // Marking mines
    for (int i = 0; i < totalMines; i++) {
      var x = Random().nextInt(width);
      var y = Random().nextInt(height);
      if (cells[x][y].isMine) {
        i--;
      }
      if (x == cell.x && y == cell.y) {
        i--;
        continue;
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
      child: Scaffold(
        backgroundColor: palette.cream,
        body: Stack(
          children: [
            Center(
              // This is the entirety of the "game".
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IgnorePointer(
                    ignoring: _duringCelebration || _duringLose,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        margin: const EdgeInsets.all(1.0),
                        child: buildButtonColumn(),
                      ),
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
            IgnorePointer(
              ignoring: _duringCelebration || _duringLose,
              child: SizedBox.expand(
                child: Visibility(
                  visible: _duringCelebration,
                  child: IgnorePointer(
                    child: Confetti(
                      isStopped: !_duringCelebration,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _playerWon() async {
    _log.info('Level ${widget.level.number} won');

    final score = Score(
      widget.level.number,
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

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score, 'level': widget.level.number});
  }

  void _revealCell(CellModel cell) async {
    if (cell.isRevealed || cell.isFlagged) return;

    if (!_firstReveal) {
      _firstReveal = true;

      generateMines(cell);

      _startOfPlay = DateTime.now();
    }

    setState(() {
      cell.isRevealed = true;
    });

    if (cell.isMine && totalCellsRevealed > 0) {
      _log.info('Level ${widget.level.number} lost');
      _duringLose = true;

      await Future<void>.delayed(_postLoseDuration);

      _showGameOverDialog();
      return;
    }

    totalCellsRevealed++;

    if (totalCellsRevealed == (width * height) - totalMines) {
      _playerWon();
    }

    if (cell.value == 0) {
      for (CellModel neighbour in getCellNeighbourhood(cell)) {
        _revealCell(neighbour);
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You lost'),
        actions: [
          TextButton(
            onPressed: () {
              _restart();
              Navigator.of(context).pop();
            },
            child: const Text('Restart'),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/'),
            child: const Text('Back to menu'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _firstReveal = false;
      _duringCelebration = false;
      totalCellsRevealed = 0;
      generateGrid();
      _duringLose = false;
    });
  }
}

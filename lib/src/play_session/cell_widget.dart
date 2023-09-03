import 'package:flutter/material.dart';
import 'cell.dart';
import 'package:game_template/src/style/palette.dart';
import 'package:provider/provider.dart';



class CellWidget extends StatefulWidget {
  const CellWidget({
    required this.cell,
    required this.size,
    Key? key,
  }) : super(key: key);

  final CellModel cell;
  final int size;

  @override
  _CellWidgetState createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Container(
        margin: const EdgeInsets.all(1),
        height: MediaQuery.of(context).size.width / widget.size + 1,
        decoration: BoxDecoration(
          color: widget.cell.isRevealed ? (widget.cell.isMine ? palette.redHighlight : palette.lightGreen) : palette.mediumGreen,
        ),
        child: (widget.cell.isMine && widget.cell.isRevealed)
            ? Center(
                child: Icon(
                  Icons.dangerous,
                  color: palette.darkGreen,
                ),
              )
            : widget.cell.isFlagged
                ? Center(
                    child: Icon(
                      Icons.flag,
                      color: palette.darkGreen,
                    ),
                  )
                : widget.cell.isRevealed
                    ? Center(
                        child: Text(
                          widget.cell.value.toString(),
                          style: TextStyle(
                            color: palette.cream,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : Container()
    );
  }
}

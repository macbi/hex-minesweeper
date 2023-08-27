import 'package:flutter/material.dart';
import 'cell.dart';

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
    return Container(
        margin: const EdgeInsets.only(right: 1, bottom: 1),
        height: MediaQuery.of(context).size.width / widget.size + 1,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: widget.cell.isRevealed ? (widget.cell.isMine ? Colors.red[100] : Colors.grey[200 + (widget.cell.value * 50)]) : Colors.white,
        ),
        child: (widget.cell.isMine && widget.cell.isRevealed)
            ? Center(
                child: Icon(
                  Icons.dangerous,
                  color: Colors.redAccent,
                ),
              )
            : widget.cell.isFlagged
                ? Center(
                    child: Icon(
                      Icons.flag,
                      color: Colors.green,
                    ),
                  )
                : widget.cell.isRevealed
                    ? Center(
                        child: Text(
                          widget.cell.value.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : Container()
    );
  }
}

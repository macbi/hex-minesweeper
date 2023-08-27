import 'dart:ui';
import 'package:flutter/material.dart';

class CellModel{
 final int x;
 final int y;
 bool isMine = false;
 bool isRevealed = false;
 int value = 0;
 bool isFlagged = false;

 CellModel(this.x, this.y);
}
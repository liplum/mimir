import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:sit/utils/list2d/list2d.dart';
import 'package:sudoku_solver_generator/sudoku_solver_generator.dart';

part "board.g.dart";

const sudokuSides = 9;

@immutable
@JsonSerializable()
@CopyWith(skipFields: true)
class SudokuCell {
  static const emptyInputNumber = 0;
  static const disableInputNumber = -1;
  final int index;

  /// A negative value (e.g., -1) indicates a pre-filled cell generated by the puzzle.
  /// The user cannot modify this value.
  /// `0` means the cell is empty and awaits user input.
  final int userInput;

  /// The correct value that the user should fill in the cell (1 to 9).
  final int correctValue;

  const SudokuCell({
    required this.index,
    this.userInput = SudokuCell.disableInputNumber,
    this.correctValue = SudokuCell.emptyInputNumber,
  }) : assert(correctValue == 0 || (1 <= correctValue && correctValue <= 9),
            "The puzzle should generate correct value in [1,9] but $correctValue");

  bool get isPuzzle => userInput < 0;

  bool get canUserInput => userInput >= 0;

  bool get emptyInput {
    assert(userInput >= 0, "Developer should check `isPuzzle` before access this");
    return userInput == 0;
  }

  bool get isSolved {
    assert(userInput >= 0, "Developer should check `isPuzzle` before access this");
    return userInput == correctValue;
  }

  @override
  bool operator ==(Object other) {
    return other is SudokuCell &&
        runtimeType == other.runtimeType &&
        userInput == other.userInput &&
        correctValue == other.correctValue;
  }

  @override
  int get hashCode => Object.hash(userInput, correctValue);

  factory SudokuCell.fromJson(Map<String, dynamic> json) => _$SudokuCellFromJson(json);

  Map<String, dynamic> toJson() => _$SudokuCellToJson(this);
}

@immutable
extension type const SudokuBoard(List2D<SudokuCell> _cells) {
// class SudokuBoard {
//   final List2D<SudokuCell> _cells;
//
//   const SudokuBoard(this._cells);
  factory SudokuBoard.generate({required int emptySquares}) {
    final generator = SudokuGenerator(emptySquares: emptySquares);
    final puzzle = generator.newSudoku;
    final solved = generator.newSudokuSolved;
    return SudokuBoard(List2D.generate(
      sudokuSides,
      sudokuSides,
      (row, column, index) => SudokuCell(
        index: index,
        userInput: puzzle[row][column] == 0 ? 0 : -1,
        correctValue: solved[row][column],
      ),
    ));
  }

  factory SudokuBoard.byDefault() {
    return SudokuBoard(
      List2D.generate(
        sudokuSides,
        sudokuSides,
        (row, column, index) => SudokuCell(
          index: index,
        ),
      ),
    );
  }

  bool get isSolved {
    for (final cell in _cells) {
      if (cell.isPuzzle) continue;
      if (!cell.isSolved) return false;
    }
    return true;
  }

  bool canFill({
    required int cellIndex,
    required int number,
  }) {
    final cell = _cells.getByIndex(cellIndex);
    if (!cell.canUserInput) return false;
    return true;
  }

  SudokuCell getCellByIndex(int cellIndex) {
    return _cells.getByIndex(cellIndex);
  }

  SudokuBoard changeCell(int cellIndex, int userInput) {
    final oldCells = _cells;
    final newCell = oldCells.getByIndex(cellIndex).copyWith(
          userInput: userInput,
        );
    final newCells = List2D.of(oldCells)..setByIndex(cellIndex, newCell);
    return SudokuBoard(newCells);
  }

  bool isCellOnEdge(int cellIndex) {
    return _cells.onEdge(_cells.getRowFrom(cellIndex), _cells.getColumnFrom(cellIndex));
  }

  SudokuBoardZone getZone(int zoneIndex) {
    return SudokuBoardZone(this, zoneIndex);
  }

  SudokuBoardZone getZoneWhereCell(SudokuCell cell) {
    final zoneIndex = SudokuBoardZone.getZoneIndexByIndex(cell.index);
    return getZone(zoneIndex);
  }

  factory SudokuBoard.fromJson(dynamic json) {
    return SudokuBoard(
      List2D<SudokuCell>.fromJson(json, (value) => SudokuCell.fromJson(value as Map<String, dynamic>)),
    );
  }

  dynamic toJson() {
    return _cells;
  }
}

@immutable
class SudokuBoardZone {
  final int zoneIndex;
  final SudokuBoard parent;
  final List2D<SudokuCell> _cells;

  SudokuBoardZone(
    this.parent,
    this.zoneIndex,
  ) : _cells = parent._cells.subview(
          rows: 3,
          columns: 3,
          rowOffset: zoneIndex ~/ 3,
          columnOffset: zoneIndex % 3,
        );

  int get parentRowOffset => (zoneIndex ~/ 3) * 3;

  int get parentColumnOffset => (zoneIndex % 3) * 3;
  static int getZoneIndexOf(int row, int column) {
    int x = column ~/ 3;
    int y = row ~/ 3;
    return y * 3 + x;
  }

  static int getZoneIndexByIndex(int boardIndex) {
    return getZoneIndexOf(boardIndex ~/ 9, boardIndex % 9);
  }

  ({int localRow, int localColumn}) mapBoardIndexToLocal(int boardIndex) {
    final parentRow = parent._cells.getRowFrom(boardIndex);
    final parentColumn = parent._cells.getColumnFrom(boardIndex);
    final localRow = (parentRow - parentRowOffset) % 3;
    final localColumn = (parentColumn - parentColumnOffset) % 3;
    assert(0 <= localRow && localRow < 3, "$localRow not in [0,3)");
    assert(0 <= localColumn && localColumn < 3, "$localColumn not in [0,3)");
    print(
        "The cell #$boardIndex at ($parentRow,$parentColumn) on parent is at ($localRow,$localColumn) on zone#$zoneIndex");
    return (localRow: localRow, localColumn: localColumn);
  }

  bool isOnEdge(int boardIndex) {
    final (:localRow, :localColumn) = mapBoardIndexToLocal(boardIndex);
    return _cells.onEdge(localRow, localColumn);
  }

  bool isCellOnEdge(SudokuCell cell) {
    return isOnEdge(cell.index);
  }
}

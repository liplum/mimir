import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sit/game/entity/game_status.dart';
import 'package:sit/game/sudoku/entity/state.dart';

import '../entity/mode.dart';
import '../entity/board.dart';

class GameLogic extends StateNotifier<GameStateSudoku> {
  GameLogic([GameStateSudoku? initial]) : super(initial ?? GameStateSudoku.byDefault());

  void initGame({required GameMode gameMode}) {
    final board = SudokuBoard.generate(emptySquares: gameMode.blanks);
    state = GameStateSudoku.newGame(mode: gameMode, board: board);
  }

  Duration get playtime => state.playtime;

  set playtime(Duration playtime) => state = state.copyWith(
        playtime: playtime,
      );

  Future<void> save() async {
    if (state.status.shouldSave) {
    } else {}
  }

  void setNoted(int cellIndex, int number, bool noted) {
    final oldNotes = state.notes;
    final newNotes = List.of(oldNotes)..[cellIndex] = oldNotes[cellIndex].setNoted(number, noted);
    state = state.copyWith(
      notes: newNotes,
    );
  }

  bool getNoted(int cellIndex, int number) {
    return state.notes[cellIndex].getNoted(number);
  }

  void fillCell(int cellIndex, int number) {
    final oldBoard = state.board;
    final oldCell = oldBoard.getCellByIndex(cellIndex);
     number = oldCell.userInput == number ? SudokuCell.emptyInputNumber : number;
    final newBoard = oldBoard.changeCell(cellIndex, number);
    state = state.copyWith(
      board: newBoard,
    );
  }

  int getFilled(int cellIndex) {
    return state.board.getCellByIndex(cellIndex).userInput;
  }

  void checkWin() {
    if (state.board.isSolved) {
      state = state.copyWith(
        status: GameStatus.victory,
      );
    }
  }
}

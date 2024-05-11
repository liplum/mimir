// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GameStateSudokuCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// GameStateSudoku(...).copyWith(id: 12, name: "My name")
  /// ````
  GameStateSudoku call({
    GameStatus? status,
    GameMode? mode,
    SudokuBoard? board,
    Duration? playtime,
    List<SudokuCellNote>? notes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGameStateSudoku.copyWith(...)`.
class _$GameStateSudokuCWProxyImpl implements _$GameStateSudokuCWProxy {
  const _$GameStateSudokuCWProxyImpl(this._value);

  final GameStateSudoku _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// GameStateSudoku(...).copyWith(id: 12, name: "My name")
  /// ````
  GameStateSudoku call({
    Object? status = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
    Object? board = const $CopyWithPlaceholder(),
    Object? playtime = const $CopyWithPlaceholder(),
    Object? notes = const $CopyWithPlaceholder(),
  }) {
    return GameStateSudoku(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GameStatus,
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as GameMode,
      board: board == const $CopyWithPlaceholder() || board == null
          ? _value.board
          // ignore: cast_nullable_to_non_nullable
          : board as SudokuBoard,
      playtime: playtime == const $CopyWithPlaceholder() || playtime == null
          ? _value.playtime
          // ignore: cast_nullable_to_non_nullable
          : playtime as Duration,
      notes: notes == const $CopyWithPlaceholder() || notes == null
          ? _value.notes
          // ignore: cast_nullable_to_non_nullable
          : notes as List<SudokuCellNote>,
    );
  }
}

extension $GameStateSudokuCopyWith on GameStateSudoku {
  /// Returns a callable class that can be used as follows: `instanceOfGameStateSudoku.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$GameStateSudokuCWProxy get copyWith => _$GameStateSudokuCWProxyImpl(this);
}

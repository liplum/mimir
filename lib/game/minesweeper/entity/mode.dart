import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sit/game/entity/mode.dart';

@JsonSerializable(createToJson: false, createFactory: false)
class GameModeMinesweeper extends GameMode {
  final int gameRows;
  final int gameColumns;
  final int gameMines;
  static const defaultRows = 15;
  static const defaultColumns = 8;
  static const easy = GameModeMinesweeper._(
    name: "easy",
    gameRows: defaultRows,
    gameColumns: defaultColumns,
    gameMines: 18,
  );
  static const normal = GameModeMinesweeper._(
    name: "normal",
    gameRows: defaultRows,
    gameColumns: defaultColumns,
    gameMines: 30,
  );
  static const hard = GameModeMinesweeper._(
    name: "hard",
    gameRows: defaultRows,
    gameColumns: defaultColumns,
    gameMines: 43,
  );

  static final name2mode = {
    "easy": easy,
    "normal": normal,
    "hard": hard,
  };

  static final all = [
    easy,
    normal,
    hard,
  ];

  const GameModeMinesweeper._({
    required super.name,
    required this.gameRows,
    required this.gameColumns,
    required this.gameMines,
  });

  factory GameModeMinesweeper.fromJson(String name) => name2mode[name] ?? easy;

  @override
  bool operator ==(Object other) {
    return other is GameModeMinesweeper &&
        runtimeType == other.runtimeType &&
        name == other.name &&
        gameRows == other.gameRows &&
        gameColumns == other.gameColumns &&
        gameMines == other.gameMines;
  }

  @override
  int get hashCode => Object.hash(name, gameRows, gameColumns, gameMines);

  @override
  String l10n() => "game.minesweeper.gameMode.$name".tr();
}

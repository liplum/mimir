// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cell4Save _$Cell4SaveFromJson(Map<String, dynamic> json) => Cell4Save(
      mine: json['mine'] as bool? ?? false,
      state: $enumDecodeNullable(_$CellStateEnumMap, json['state']) ?? CellState.covered,
    );

Map<String, dynamic> _$Cell4SaveToJson(Cell4Save instance) => <String, dynamic>{
      'mine': instance.mine,
      'state': _$CellStateEnumMap[instance.state]!,
    };

const _$CellStateEnumMap = {
  CellState.covered: 0,
  CellState.blank: 1,
  CellState.flag: 2,
};

SaveMinesweeper _$SaveMinesweeperFromJson(Map<String, dynamic> json) => SaveMinesweeper(
      cells:
          json['cells'] == null ? _defaultCells() : List2D<Cell4Save>.fromJson(json['cells'] as Map<String, dynamic>),
      playTime: json['playTime'] == null ? Duration.zero : Duration(microseconds: (json['playTime'] as num).toInt()),
      mode: json['mode'] == null ? GameMode.easy : GameMode.fromJson(json['mode'] as String),
    );

Map<String, dynamic> _$SaveMinesweeperToJson(SaveMinesweeper instance) => <String, dynamic>{
      'cells': instance.cells,
      'playTime': instance.playTime.inMicroseconds,
      'mode': instance.mode,
    };

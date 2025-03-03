import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mimir/design/adaptive/foundation.dart';
import 'package:mimir/utils/byte_io/byte_io.dart';
import 'package:mimir/utils/error.dart';
import 'package:statistics/statistics.dart';

import '../../entity/loc.dart';
import '../../entity/timetable.dart';
import '../widget/copy_day.dart';
import '../widget/move_day.dart';
import '../widget/remove_day.dart';
import '../widget/swap_days.dart';

import "../../i18n.dart";

part "patch.g.dart";

/// for json serializable
const _patchSetType = "patchSet";

/// for QR code
const _patchSetTypeIndex = 255;

sealed class TimetablePatchEntry {
  static const version = 1;

  const TimetablePatchEntry();

  factory TimetablePatchEntry.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    if (type == _patchSetType) {
      try {
        return TimetablePatchSet.fromJson(json);
      } catch (error, stackTrace) {
        debugPrintError(error, stackTrace);
        return TimetableUnknownPatch(legacy: json);
      }
    } else {
      return TimetablePatch.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();

  String l10n();

  @override
  String toString() => toDartCode();

  String toDartCode();

  void _serialize(ByteWriter writer);

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  static TimetablePatchEntry deserialize(ByteReader reader) {
    // ignore: unused_local_variable
    final revision = reader.uint8();
    final typeId = reader.uint8();
    if (typeId == _patchSetTypeIndex) {
      return TimetablePatchSet.deserialize(reader);
    } else if (0 <= typeId && typeId < TimetablePatchType.values.length) {
      final type = TimetablePatchType.values[typeId];
      return type._deserialize(reader);
    }
    assert(false);
    return const TimetableUnknownPatch();
  }

  static void serialize(TimetablePatchEntry entry, ByteWriter writer) {
    writer.uint8(version);
    if (entry is TimetablePatchSet) {
      writer.uint8(_patchSetTypeIndex);
    } else if (entry is TimetablePatch) {
      writer.uint8(entry.type.index);
    } else {
      writer.uint8(254);
    }
    entry._serialize(writer);
  }

  static TimetablePatchEntry decodeByteList(Uint8List bytes) {
    final reader = ByteReader(bytes);
    return deserialize(reader);
  }

  static Uint8List encodeByteList(TimetablePatchEntry entry) {
    final writer = ByteWriter(512);
    serialize(entry, writer);
    return writer.build();
  }
}

@JsonEnum(alwaysCreate: true)
enum TimetablePatchType<TPatch extends TimetablePatch> {
  // addLesson,
  // removeLesson,
  // replaceLesson,
  // swapLesson,
  // moveLesson,
  // addDay,
  unknown<TimetableUnknownPatch>(
    Icons.question_mark,
    TimetableUnknownPatch.onCreate,
    TimetableUnknownPatch.deserialize,
  ),
  moveDay<TimetableMoveDayPatch>(
    Icons.turn_sharp_right,
    TimetableMoveDayPatch.onCreate,
    TimetableMoveDayPatch.deserialize,
  ),
  removeDay<TimetableRemoveDayPatch>(
    Icons.delete,
    TimetableRemoveDayPatch.onCreate,
    TimetableRemoveDayPatch.deserialize,
  ),
  copyDay<TimetableCopyDayPatch>(
    Icons.copy,
    TimetableCopyDayPatch.onCreate,
    TimetableCopyDayPatch.deserialize,
  ),
  swapDays<TimetableSwapDaysPatch>(
    Icons.swap_horiz,
    TimetableSwapDaysPatch.onCreate,
    TimetableSwapDaysPatch.deserialize,
  ),
  ;

  static const creatable = [
    moveDay,
    removeDay,
    copyDay,
    swapDays,
  ];

  final IconData icon;
  final FutureOr<TPatch?> Function(BuildContext context, Timetable timetable, [TPatch? patch]) _onCreate;
  final TPatch Function(ByteReader reader) _deserialize;

  const TimetablePatchType(this.icon, this._onCreate, this._deserialize);

  FutureOr<TPatch?> create(BuildContext context, Timetable timetable, [TPatch? patch]) async {
    dynamic any = this;
    // I have to cast [this] to dynamic :(
    final newPatch = await any._onCreate(context, timetable, patch);
    return newPatch;
  }

  String l10n() => "timetable.patch.type.$name".tr();
}

abstract interface class WithTimetableDayLoc {
  Iterable<TimetableDayLoc> get allLoc;
}

extension WithTimetableDayLocX on WithTimetableDayLoc {
  bool allLocInRange(Timetable timetable) {
    return allLoc.every((loc) => loc.mode == TimetableDayLocMode.date ? timetable.inRange(loc.date) : true);
  }
}

/// To opt-in [JsonSerializable], please specify `toJson` parameter to [TimetablePatch.toJson].
sealed class TimetablePatch extends TimetablePatchEntry {
  @JsonKey()
  TimetablePatchType get type;

  const TimetablePatch();

  factory TimetablePatch.fromJson(Map<String, dynamic> json) {
    final type = $enumDecode(_$TimetablePatchTypeEnumMap, json["type"], unknownValue: TimetablePatchType.unknown);
    try {
      return switch (type) {
        // TimetablePatchType.addLesson => TimetableAddLessonPatch.fromJson(json),
        // TimetablePatchType.removeLesson => TimetableAddLessonPatch.fromJson(json),
        // TimetablePatchType.replaceLesson => TimetableAddLessonPatch.fromJson(json),
        // TimetablePatchType.swapLesson => TimetableAddLessonPatch.fromJson(json),
        // TimetablePatchType.moveLesson => TimetableAddLessonPatch.fromJson(json),
        // TimetablePatchType.addDay => TimetableAddLessonPatch.fromJson(json),
        TimetablePatchType.unknown => TimetableUnknownPatch.fromJson(json),
        TimetablePatchType.removeDay => TimetableRemoveDayPatch.fromJson(json),
        TimetablePatchType.swapDays => TimetableSwapDaysPatch.fromJson(json),
        TimetablePatchType.moveDay => TimetableMoveDayPatch.fromJson(json),
        TimetablePatchType.copyDay => TimetableCopyDayPatch.fromJson(json),
      };
    } catch (error, stackTrace) {
      debugPrintError(error, stackTrace);
      return const TimetableUnknownPatch();
    }
  }

  @override
  String l10n();
}

@JsonSerializable()
@CopyWith()
class TimetablePatchSet extends TimetablePatchEntry {
  final String name;
  final List<TimetablePatch> patches;

  const TimetablePatchSet({
    required this.name,
    required this.patches,
  });

  factory TimetablePatchSet.fromJson(Map<String, dynamic> json) => _$TimetablePatchSetFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimetablePatchSetToJson(this)..["type"] = _patchSetType;

  @override
  String toDartCode() {
    return 'TimetablePatchSet(name:"$name",patches:${patches.map((p) => p.toDartCode()).toList(growable: false)})';
  }

  static void _serializeLocal(TimetablePatchSet obj, ByteWriter writer) {
    writer.strUtf8(obj.name);
    writer.uint8(min(obj.patches.length, 255));
    for (final patch in obj.patches) {
      TimetablePatchEntry.serialize(patch, writer);
    }
  }

  static TimetablePatchSet deserialize(ByteReader reader) {
    final name = reader.strUtf8();
    final length = reader.uint8();
    final patches = <TimetablePatch>[];
    for (var i = 0; i < length; i++) {
      patches.add(TimetablePatchEntry.deserialize(reader) as TimetablePatch);
    }
    return TimetablePatchSet(name: name, patches: patches);
  }

  @override
  void _serialize(ByteWriter writer) => _serializeLocal(this, writer);

  @override
  String l10n() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimetablePatchSet && name == other.name && patches.equals(other.patches);

  @override
  int get hashCode => Object.hash(name, patches.computeHashcode());
}

class BuiltinTimetablePatchSet implements TimetablePatchSet {
  final String key;
  final bool Function(Timetable timetable)? recommended;

  @override
  String get name => "timetable.patch.builtin.$key".tr();
  @override
  final List<TimetablePatch> patches;

  const BuiltinTimetablePatchSet({
    required this.key,
    required this.patches,
    required this.recommended,
  });

  @override
  void _serialize(ByteWriter writer) => TimetablePatchSet._serializeLocal(this, writer);

  @override
  Map<String, dynamic> toJson() => _$TimetablePatchSetToJson(this)..["type"] = _patchSetType;

  @override
  String toDartCode() {
    return 'BuiltinTimetablePatchSet(patches:${patches.map((p) => p.toDartCode()).toList(growable: false)})';
  }

  @override
  String toString() => toDartCode();

  @override
  String l10n() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BuiltinTimetablePatchSet && key == other.key && patches.equals(other.patches);

  @override
  int get hashCode => Object.hash(key, patches.computeHashcode());
}

//
// @JsonSerializable()
// class TimetableAddLessonPatch extends TimetablePatch {
//   @override
//   final type = TimetablePatchType.addLesson;
//
//   const TimetableAddLessonPatch();
//
//   factory TimetableAddLessonPatch.fromJson(Map<String, dynamic> json) => _$TimetableAddLessonPatchFromJson(json);
//
//   @override
//   Map<String, dynamic> toJson() => _$TimetableAddLessonPatchToJson(this);
// }

// @JsonSerializable()
// class TimetableRemoveLessonPatch extends TimetablePatch {
//   @override
//   final type = TimetablePatchType.removeLesson;
//
//   const TimetableRemoveLessonPatch();
//
//   factory TimetableRemoveLessonPatch.fromJson(Map<String, dynamic> json) => _$TimetableRemoveLessonPatchFromJson(json);
//
//   @override
//   Map<String, dynamic> toJson() => _$TimetableRemoveLessonPatchToJson(this);
// }
//
// @JsonSerializable()
// class TimetableMoveLessonPatch extends TimetablePatch {
//   @override
//   final type = TimetablePatchType.moveLesson;
//
//   const TimetableMoveLessonPatch();
//
//   factory TimetableMoveLessonPatch.fromJson(Map<String, dynamic> json) => _$TimetableMoveLessonPatchFromJson(json);
//
//   @override
//   Map<String, dynamic> toJson() => _$TimetableMoveLessonPatchToJson(this);
// }

@JsonSerializable()
class TimetableUnknownPatch extends TimetablePatch {
  @JsonKey()
  @override
  TimetablePatchType get type => TimetablePatchType.unknown;

  final Map<String, dynamic>? legacy;

  const TimetableUnknownPatch({this.legacy});

  static Future<TimetableUnknownPatch?> onCreate(
    BuildContext context,
    Timetable timetable, [
    TimetableUnknownPatch? patch,
  ]) async {
    throw UnsupportedError("TimetableUnknownPatch can't be created");
  }

  factory TimetableUnknownPatch.fromJson(Map<String, dynamic> json) {
    return TimetableUnknownPatch(legacy: json);
  }

  @override
  void _serialize(ByteWriter writer) {
    writer.uint8(type.index);
  }

  static TimetableUnknownPatch deserialize(ByteReader reader) {
    return const TimetableUnknownPatch();
  }

  @override
  Map<String, dynamic> toJson() => (legacy ?? {})..["type"] = _$TimetablePatchTypeEnumMap[type];

  @override
  String toDartCode() {
    return "TimetableUnknownPatch(legacy:$legacy)";
  }

  @override
  String l10n() {
    return i18n.unknown;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimetableUnknownPatch && runtimeType == other.runtimeType;

  @override
  int get hashCode => (TimetableUnknownPatch).hashCode;
}

@JsonSerializable()
class TimetableRemoveDayPatch extends TimetablePatch implements WithTimetableDayLoc {
  @override
  TimetablePatchType get type => TimetablePatchType.removeDay;

  @JsonKey()
  final List<TimetableDayLoc> all;

  @override
  Iterable<TimetableDayLoc> get allLoc => all;

  const TimetableRemoveDayPatch({
    required this.all,
  });

  TimetableRemoveDayPatch.oneDay({
    required TimetableDayLoc loc,
  }) : all = <TimetableDayLoc>[loc];

  @override
  void _serialize(ByteWriter writer) {
    writer.uint8(min(all.length, 255));
    for (final loc in all) {
      loc.serialize(writer);
    }
  }

  static TimetableRemoveDayPatch deserialize(ByteReader reader) {
    final length = reader.uint8();
    final all = <TimetableDayLoc>[];
    for (var i = 0; i < length; i++) {
      all.add(TimetableDayLoc.deserialize(reader));
    }
    return TimetableRemoveDayPatch(
      all: all,
    );
  }

  factory TimetableRemoveDayPatch.fromJson(Map<String, dynamic> json) => _$TimetableRemoveDayPatchFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimetableRemoveDayPatchToJson(this)..["type"] = _$TimetablePatchTypeEnumMap[type];

  static Future<TimetableRemoveDayPatch?> onCreate(
    BuildContext context,
    Timetable timetable, [
    TimetableRemoveDayPatch? patch,
  ]) async {
    return await context.showSheet(
      (ctx) => TimetableRemoveDayPatchSheet(
        timetable: timetable,
        patch: patch,
      ),
    );
  }

  @override
  String toDartCode() {
    return "TimetableRemoveDayPatch(loc:${all.map((loc) => loc.toDartCode()).toList()})";
  }

  @override
  String l10n() {
    return i18n.patch.removeDay(all.map((loc) => loc.l10n()).join(", "));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableRemoveDayPatch && runtimeType == other.runtimeType && all.equals(other.all);

  @override
  int get hashCode => all.computeHashcode();
}

@JsonSerializable()
class TimetableMoveDayPatch extends TimetablePatch implements WithTimetableDayLoc {
  @override
  TimetablePatchType get type => TimetablePatchType.moveDay;
  @JsonKey()
  final TimetableDayLoc source;
  @JsonKey()
  final TimetableDayLoc target;

  @override
  Iterable<TimetableDayLoc> get allLoc => [source, target];

  const TimetableMoveDayPatch({
    required this.source,
    required this.target,
  });

  @override
  void _serialize(ByteWriter writer) {
    source.serialize(writer);
    target.serialize(writer);
  }

  static TimetableMoveDayPatch deserialize(ByteReader reader) {
    final source = TimetableDayLoc.deserialize(reader);
    final target = TimetableDayLoc.deserialize(reader);
    return TimetableMoveDayPatch(source: source, target: target);
  }

  factory TimetableMoveDayPatch.fromJson(Map<String, dynamic> json) => _$TimetableMoveDayPatchFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimetableMoveDayPatchToJson(this)..["type"] = _$TimetablePatchTypeEnumMap[type];

  static Future<TimetableMoveDayPatch?> onCreate(
    BuildContext context,
    Timetable timetable, [
    TimetableMoveDayPatch? patch,
  ]) async {
    return await context.showSheet(
      (ctx) => TimetableMoveDayPatchSheet(
        timetable: timetable,
        patch: patch,
      ),
    );
  }

  @override
  String toDartCode() {
    return "TimetableMoveDayPatch(source:${source.toDartCode()},target:${target.toDartCode()},)";
  }

  @override
  String l10n() {
    return i18n.patch.moveDay(source.l10n(), target.l10n());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableMoveDayPatch &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target;

  @override
  int get hashCode => Object.hash(source, target);
}

@JsonSerializable()
class TimetableCopyDayPatch extends TimetablePatch implements WithTimetableDayLoc {
  @override
  TimetablePatchType get type => TimetablePatchType.copyDay;
  @JsonKey()
  final TimetableDayLoc source;
  @JsonKey()
  final TimetableDayLoc target;

  @override
  Iterable<TimetableDayLoc> get allLoc => [source, target];

  const TimetableCopyDayPatch({
    required this.source,
    required this.target,
  });

  @override
  void _serialize(ByteWriter writer) {
    source.serialize(writer);
    target.serialize(writer);
  }

  static TimetableCopyDayPatch deserialize(ByteReader reader) {
    final source = TimetableDayLoc.deserialize(reader);
    final target = TimetableDayLoc.deserialize(reader);
    return TimetableCopyDayPatch(source: source, target: target);
  }

  factory TimetableCopyDayPatch.fromJson(Map<String, dynamic> json) => _$TimetableCopyDayPatchFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimetableCopyDayPatchToJson(this)..["type"] = _$TimetablePatchTypeEnumMap[type];

  static Future<TimetableCopyDayPatch?> onCreate(
    BuildContext context,
    Timetable timetable, [
    TimetableCopyDayPatch? patch,
  ]) async {
    return await context.showSheet(
      (ctx) => TimetableCopyDayPatchSheet(
        timetable: timetable,
        patch: patch,
      ),
    );
  }

  @override
  String l10n() {
    return i18n.patch.copyDay(source.l10n(), target.l10n());
  }

  @override
  String toDartCode() {
    return "TimetableCopyDayPatch(source:${source.toDartCode()},target:${target.toDartCode()})";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableCopyDayPatch &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target;

  @override
  int get hashCode => Object.hash(source, target);
}

@JsonSerializable()
class TimetableSwapDaysPatch extends TimetablePatch implements WithTimetableDayLoc {
  @override
  TimetablePatchType get type => TimetablePatchType.swapDays;
  @JsonKey()
  final TimetableDayLoc a;
  @JsonKey()
  final TimetableDayLoc b;

  @override
  Iterable<TimetableDayLoc> get allLoc => [a, b];

  const TimetableSwapDaysPatch({
    required this.a,
    required this.b,
  });

  static TimetableSwapDaysPatch deserialize(ByteReader reader) {
    final a = TimetableDayLoc.deserialize(reader);
    final b = TimetableDayLoc.deserialize(reader);
    return TimetableSwapDaysPatch(a: a, b: b);
  }

  factory TimetableSwapDaysPatch.fromJson(Map<String, dynamic> json) => _$TimetableSwapDaysPatchFromJson(json);

  @override
  void _serialize(ByteWriter writer) {
    a.serialize(writer);
    b.serialize(writer);
  }

  @override
  Map<String, dynamic> toJson() => _$TimetableSwapDaysPatchToJson(this)..["type"] = _$TimetablePatchTypeEnumMap[type];

  static Future<TimetableSwapDaysPatch?> onCreate(
    BuildContext context,
    Timetable timetable, [
    TimetableSwapDaysPatch? patch,
  ]) async {
    return await context.showSheet(
      (ctx) => TimetableSwapDaysPatchSheet(
        timetable: timetable,
        patch: patch,
      ),
    );
  }

  @override
  String l10n() {
    return i18n.patch.swapDays(a.l10n(), b.l10n());
  }

  @override
  String toDartCode() {
    return "TimetableSwapDaysPatch(a:${a.toDartCode()},b:${b.toDartCode()})";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSwapDaysPatch && runtimeType == other.runtimeType && a == other.a && b == other.b;

  @override
  int get hashCode => Object.hash(a, b);
}
// factory .fromJson(Map<String, dynamic> json) => _$FromJson(json);
//
// Map<String, dynamic> toJson() => _$ToJson(this);

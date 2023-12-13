import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sit/storage/hive/type_id.dart';

part 'school.g.dart';

typedef SchoolYear = int;

@HiveType(typeId: CacheHiveType.semester)
@JsonEnum()
enum Semester {
  @HiveField(0)
  all,
  @HiveField(1)
  term1,
  @HiveField(2)
  term2;

  String localized() => "school.semester.$name".tr();
}

@HiveType(typeId: CacheHiveType.semesterInfo)
class SemesterInfo {
  @HiveField(0)
  final SchoolYear year;
  @HiveField(1)
  final Semester semester;

  const SemesterInfo({
    required this.year,
    required this.semester,
  });

  @override
  String toString() {
    return "$year:$semester";
  }

  @override
  bool operator ==(Object other) {
    return other is SemesterInfo &&
        runtimeType == other.runtimeType &&
        year == other.year &&
        semester == other.semester;
  }

  @override
  int get hashCode => Object.hash(year, semester);
}

String semesterToFormField(Semester semester) {
  const mapping = {
    Semester.all: '',
    Semester.term1: '3',
    Semester.term2: '12',
  };
  return mapping[semester]!;
}

@HiveType(typeId: CacheHiveType.courseCat)
enum CourseCat {
  /// 通识课
  @HiveField(0)
  genEd,

  /// 公共基础课
  @HiveField(1)
  publicCore,

  /// 学科专业基础课
  @HiveField(2)
  specialized,

  /// 综合实践
  @HiveField(3)
  integratedPractice,

  /// 实践教学
  @HiveField(4)
  practicalInstruction,
  @HiveField(5)
  none;

  static CourseCat parse(String? str) {
    return switch (str) {
      "通识课" => genEd,
      "公共基础课" => publicCore,
      "学科专业基础课" => specialized,
      "综合实践" => integratedPractice,
      "实践教学" => practicalInstruction,
      _ => none,
    };
  }
}

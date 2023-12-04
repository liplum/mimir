import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/design/widgets/app.dart';
import 'package:sit/school/entity/school.dart';
import 'package:sit/school/event.dart';
import 'package:sit/school/exam_result/init.dart';
import 'package:sit/school/exam_result/page/evaluation.dart';
import 'package:sit/school/exam_result/widgets/ug.dart';
import 'package:sit/settings/settings.dart';
import 'package:sit/utils/async_event.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/utils/guard_launch.dart';
import 'package:universal_platform/universal_platform.dart';

import 'entity/result.ug.dart';
import "i18n.dart";

const _recentLength = 2;

class ExamResultUgAppCard extends StatefulWidget {
  const ExamResultUgAppCard({super.key});

  @override
  State<ExamResultUgAppCard> createState() => _ExamResultUgAppCardState();
}

class _ExamResultUgAppCardState extends State<ExamResultUgAppCard> {
  List<ExamResultUg>? resultList;
  late final EventSubscription $refreshEvent;

  @override
  void initState() {
    super.initState();
    $refreshEvent = schoolEventBus.addListener(() async {
      refresh();
    });
    refresh();
  }

  @override
  void dispose() {
    $refreshEvent.cancel();
    super.dispose();
  }

  void refresh() {
    final now = DateTime.now();
    final current = SemesterInfo(
      year: now.month >= 9 ? now.year : now.year - 1,
      semester: now.month >= 3 && now.month <= 7 ? Semester.term2 : Semester.term1,
    );
    setState(() {
      resultList = ExamResultInit.ugStorage.getResultList(current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultList = this.resultList;
    return AppCard(
      title: i18n.title.text(),
      view: resultList == null ? null : buildRecentResults(resultList),
      leftActions: [
        FilledButton.icon(
          onPressed: () async {
            await context.push("/exam-result/ug");
          },
          icon: const Icon(Icons.fact_check),
          label: i18n.check.text(),
        ),
        OutlinedButton(
          onPressed: () async {
            if (UniversalPlatform.isDesktop) {
              await guardLaunchUrl(context, teacherEvaluationUri);
            } else {
              await context.push("/teacher-eval");
            }
          },
          child: i18n.teacherEval.text(),
        )
      ],
    );
  }

  Widget? buildRecentResults(List<ExamResultUg> resultList) {
    if (resultList.isEmpty) return null;
    resultList.sort((a, b) => -ExamResultUg.compareByTime(a, b));
    final results = resultList.sublist(0, min(_recentLength, resultList.length));
    return Settings.school.examResult.listenAppCardShowResultDetails() >>
        (ctx, _) {
          final showDetails = Settings.school.examResult.appCardShowResultDetails;
          return results
              .map((result) => ExamResultUgCard(
                    result,
                    showDetails: showDetails,
                  ))
              .toList()
              .column();
        };
  }
}

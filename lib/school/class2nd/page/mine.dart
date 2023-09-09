import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimir/credential/symbol.dart';
import 'package:mimir/design/adaptive/adaptive.dart';
import 'package:mimir/design/animation/livelist.dart';
import 'package:mimir/design/colors.dart';
import 'package:mimir/l10n/extension.dart';
import 'package:rettulf/rettulf.dart';

import '../entity/list.dart';
import '../entity/score.dart';
import '../init.dart';
import '../widgets/summary.dart';
import '../utils.dart';
import 'detail.dart';
import "../i18n.dart";

class AttendedActivityPage extends StatefulWidget {
  const AttendedActivityPage({super.key});

  @override
  State<AttendedActivityPage> createState() => _AttendedActivityPageState();
}

class _AttendedActivityPageState extends State<AttendedActivityPage> with AutomaticKeepAliveClientMixin, AdaptivePageProtocol {
  List<ScJoinedActivity>? joined;
  ScScoreSummary? summary;

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (context.isPortrait) {
      return Scaffold(
        body: buildPortrait(context),
      );
    } else {
      return AdaptiveNavigation(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: buildLandscape(context),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  void onRefresh() {
    ScInit.scScoreService.getScoreSummary().then((value) {
      if (summary != value) {
        summary = value;
        if (!mounted) return;
        setState(() {
          navigatorKey = GlobalKey();
        });
      }
    });
    getMyActivityListJoinScore(ScInit.scScoreService).then((value) {
      if (joined != value) {
        joined = value;
        if (!mounted) return;
        setState(() {
          navigatorKey = GlobalKey();
        });
      }
    });
  }

  ScScoreSummary getTargetScore() {
    final admissionYear = int.tryParse(context.auth.credential?.account.substring(0, 2) ?? "") ?? 2000;
    return calcTargetScore(admissionYear);
  }

  Widget buildPortrait(BuildContext context) {
    final targetScore = getTargetScore();
    return [
      Align(
        alignment: Alignment.topCenter,
        child: buildSummeryCard(context, targetScore, summary),
      ),
      buildLiveList(context).expanded()
    ].column();
  }

  Widget buildLandscape(BuildContext ctx) {
    final targetScore = getTargetScore();
    return [
      buildSummeryCard(ctx, targetScore, summary).expanded(),
      buildLiveList(context).expanded(),
    ].row();
  }

  Widget buildJoinedActivityCard(BuildContext context, ScJoinedActivity rawActivity) {
    final titleStyle = context.textTheme.titleMedium;
    final subtitleStyle = context.textTheme.bodySmall;

    final color = rawActivity.isPassed ? Colors.green : context.themeColor;
    final trailingStyle = context.textTheme.titleLarge?.copyWith(color: color);
    final activity = ActivityParser.parse(rawActivity);

    return ListTile(
      title: Text(activity.realTitle, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${i18n.application.time}: ${context.formatYmdhmsNum(rawActivity.time)}', style: subtitleStyle),
          Text('${i18n.application.id}: ${rawActivity.applyId}', style: subtitleStyle),
        ],
      ),
      trailing: Text(rawActivity.amount.abs() > 0.01 ? rawActivity.amount.toStringAsFixed(2) : rawActivity.status,
          style: trailingStyle),
      onTap: rawActivity.activityId != -1
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailPage(activity, hero: rawActivity.applyId, enableApply: false)),
              );
            }
          : null,
    ).inCard().hero(rawActivity.applyId).padSymmetric(h: 8);
  }

// Animation
  final _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Widget buildLiveList(BuildContext ctx) {
    final activities = joined;
    if (activities == null) {
      return const CircularProgressIndicator();
    } else {
      return ScrollConfiguration(
        behavior: const CupertinoScrollBehavior(),
        child: LiveList(
          controller: _scrollController,
          itemCount: activities.length,
          physics: const BouncingScrollPhysics(),
          showItemInterval: const Duration(milliseconds: 40),
          itemBuilder: (ctx, index, animation) => buildJoinedActivityCard(ctx, activities[index]).aliveWith(animation),
        ),
      );
    }
  }
}

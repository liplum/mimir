import 'package:flutter/material.dart';
import 'package:sit/design/widgets/common.dart';
import 'package:rettulf/rettulf.dart';

import '../entity/result.pg.dart';
import '../init.dart';
import '../widgets/pg.dart';
import '../i18n.dart';

class ExamResultPgPage extends StatefulWidget {
  const ExamResultPgPage({super.key});

  @override
  State<ExamResultPgPage> createState() => _ExamResultPgPageState();
}

class _ExamResultPgPageState extends State<ExamResultPgPage> {
  List<ExamResultPg>? resultList;
  bool isFetching = false;
  bool isSelecting = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      resultList = ExamResultInit.pgStorage.getResultList();
      isFetching = true;
    });
    try {
      final resultList = await ExamResultInit.pgService.fetchResultList();
      await ExamResultInit.pgStorage.setResultList(resultList);
      if (!mounted) return;
      setState(() {
        this.resultList = resultList;
        isFetching = false;
      });
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultList = this.resultList;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: i18n.title.text(),
            bottom: isFetching
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          if (resultList != null)
            if (resultList.isEmpty)
              SliverFillRemaining(
                child: LeavingBlank(
                  icon: Icons.inbox_outlined,
                  desc: i18n.noResultsTip,
                ),
              )
            else
              SliverList.builder(
                itemCount: resultList.length,
                itemBuilder: (item, i) => ExamResultPgCard(
                  resultList[i],
                  elevated: false,
                ),
              ),
        ],
      ),
    );
  }
}

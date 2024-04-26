import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/design/adaptive/foundation.dart';
import 'package:sit/design/adaptive/multiplatform.dart';
import 'package:sit/l10n/extension.dart';
import 'package:sit/timetable/entity/loc.dart';
import 'package:sit/timetable/utils.dart';
import 'package:sit/utils/save.dart';

import '../../entity/patch.dart';
import '../../entity/timetable.dart';
import '../../page/preview.dart';
import '../../i18n.dart';
import 'shared.dart';

class TimetableRemoveDayPatchWidget extends StatelessWidget {
  final TimetableRemoveDayPatch patch;
  final SitTimetable timetable;
  final ValueChanged<TimetableRemoveDayPatch> onChanged;

  const TimetableRemoveDayPatchWidget({
    super.key,
    required this.patch,
    required this.timetable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: "Remove day".text(),
      subtitle: patch.l10n().text(),
      trailing: Icon(context.icons.edit),
      onTap: () async {
        final newPath = await context.show$Sheet$(
          (ctx) => TimetableRemoveDayPatchSheet(
            timetable: timetable,
            patch: patch,
          ),
        );
        onChanged(newPath);
      },
    );
  }
}

class TimetableRemoveDayPatchSheet extends StatefulWidget {
  final SitTimetable timetable;
  final TimetableRemoveDayPatch? patch;

  const TimetableRemoveDayPatchSheet({
    super.key,
    required this.timetable,
    required this.patch,
  });

  @override
  State<TimetableRemoveDayPatchSheet> createState() => _TimetableRemoveDayPatchSheetState();
}

class _TimetableRemoveDayPatchSheetState extends State<TimetableRemoveDayPatchSheet> {
  TimetableDayLoc? get initialLoc => widget.patch?.loc;
  late var mode = initialLoc?.mode ?? TimetableDayLocMode.date;
  late var pos = initialLoc?.mode == TimetableDayLocMode.pos ? initialLoc?.pos : null;
  late var date = initialLoc?.mode == TimetableDayLocMode.date ? initialLoc?.date : null;
  var anyChanged = false;

  void markChanged() => anyChanged |= true;

  bool canSave() => buildPatch() != null;

  @override
  Widget build(BuildContext context) {
    return PromptSaveBeforeQuitScope(
      canSave: anyChanged,
      onSave: onSave,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: "Remove day".text(),
              actions: [
                PlatformTextButton(
                  onPressed: onPreview,
                  child: i18n.preview.text(),
                ),
                PlatformTextButton(
                  onPressed: canSave() ? onSave : null,
                  child: i18n.save.text(),
                ),
              ],
            ),
            SliverList.list(children: [
              buildMode().padSymmetric(v: 8, h: 16),
              ...switch (mode) {
                TimetableDayLocMode.pos => buildPosTab(),
                TimetableDayLocMode.date => buildDateTab(),
              },
            ]),
          ],
        ),
      ),
    );
  }

  Widget buildMode() {
    return TimetableDayLocModeSwitcher(
      selected: mode,
      onSelected: (newMode) async {
        setState(() {
          mode = newMode;
        });
      },
    );
  }

  List<Widget> buildPosTab() {
    return [
      TimetableDayLocPosSelectionTile(
        title: "What day to be removed".text(),
        timetable: widget.timetable,
        pos: pos,
        onChanged: (newPos) {
          setState(() {
            pos = newPos;
          });
          markChanged();
        },
      ),
    ];
  }

  List<Widget> buildDateTab() {
    return [
      TimetableDayLocDateSelectionTile(
        title: "What day to be removed".text(),
        timetable: widget.timetable,
        date: date,
        onChanged: (newPos) {
          setState(() {
            date = newPos;
          });
          markChanged();
        },
      ),
    ];
  }

  Future<void> onPreview() async {
    await previewTimetable(context, timetable: buildTimetable());
  }

  void onSave() {
    context.pop(buildPatch());
  }

  SitTimetable buildTimetable() {
    final patch = buildPatch();
    final newPatches = List.of(widget.timetable.patches);
    if (patch != null) {
      newPatches.add(patch);
    }
    return widget.timetable.copyWith(
      patches: newPatches,
    );
  }

  TimetableRemoveDayPatch? buildPatch() {
    final pos = this.pos;
    final date = this.date;
    final loc = switch (mode) {
      TimetableDayLocMode.pos => pos != null ? TimetableDayLoc.pos(pos) : null,
      TimetableDayLocMode.date => date != null ? TimetableDayLoc.date(date) : null,
    };
    return loc != null ? TimetableRemoveDayPatch(loc: loc) : null;
  }
}

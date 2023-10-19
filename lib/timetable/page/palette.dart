import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' hide isCupertino;
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/design/adaptive/multiplatform.dart';
import 'package:sit/design/widgets/card.dart';
import 'package:sit/l10n/extension.dart';
import 'package:sit/timetable/page/preview.dart';
import 'package:sit/timetable/widgets/style.dart';

import '../entity/platte.dart';
import '../i18n.dart';
import '../init.dart';

class TimetablePaletteEditor extends StatefulWidget {
  final TimetablePalette palette;

  const TimetablePaletteEditor({
    super.key,
    required this.palette,
  });

  @override
  State<TimetablePaletteEditor> createState() => _TimetablePaletteEditorState();
}

class _Tab {
  static const length = 2;
  static const info = 0;
  static const colors = 1;
}

class _TimetablePaletteEditorState extends State<TimetablePaletteEditor> {
  late final $name = TextEditingController(text: widget.palette.name);
  late final $author = TextEditingController(text: widget.palette.author);
  late var colors = widget.palette.colors;
  final $selected = TimetableInit.storage.timetable.$selected;
  var selectedTimetable = TimetableInit.storage.timetable.selectedRow;

  @override
  void initState() {
    super.initState();
    $selected.addListener(refresh);
  }

  @override
  void dispose() {
    $name.dispose();
    $author.dispose();
    $selected.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    setState(() {
      selectedTimetable = TimetableInit.storage.timetable.selectedRow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: _Tab.length,
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            // These are the slivers that show up in the "outer" scroll view.
            final selectedTimetable = TimetableInit.storage.timetable.selectedRow;
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  floating: true,
                  title: i18n.p13n.palette.title.text(),
                  actions: [
                    if (selectedTimetable != null)
                      PlatformTextButton(
                        child: i18n.preview.text(),
                        onPressed: () async {
                          await context.navigator.push(
                            MaterialPageRoute(
                              builder: (ctx) => TimetablePreviewPage(
                                timetable: selectedTimetable,
                                style: TimetableStyleData(
                                  platte: buildPalette(),
                                  cell: CourseCellStyle.fromStorage(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    PlatformTextButton(
                      child: i18n.save.text(),
                      onPressed: () {
                        context.navigator.pop(buildPalette());
                      },
                    ),
                  ],
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(child: i18n.p13n.palette.infoTab.text()),
                      Tab(child: i18n.p13n.palette.colorsTab.text()),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              CustomScrollView(
                slivers: [
                  SliverList.list(children: [
                    buildName(),
                    buildAuthor(),
                  ]),
                ],
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ListTile(
                      title: [
                        [const Icon(Icons.light_mode), Brightness.light.l10n().text()].row(mas: MainAxisSize.min),
                        [const Icon(Icons.dark_mode), Brightness.dark.l10n().text()].row(mas: MainAxisSize.min),
                      ].row(maa: MainAxisAlignment.spaceBetween),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: colors.length,
                    itemBuilder: buildColorTile,
                  ),
                  SliverList.list(children: [
                    const Divider(indent: 12, endIndent: 12),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: i18n.p13n.palette.addColor.text(),
                      onTap: () {
                        setState(() {
                          colors.add((light: Colors.white30, dark: Colors.black12));
                        });
                      },
                    ),
                  ]),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  TimetablePalette buildPalette() {
    return TimetablePalette(
      name: $name.text,
      author: $author.text,
      colors: colors,
    );
  }

  Widget buildColorTile(BuildContext ctx, int index) {
    Future<void> changeColor(Color old, Brightness brightness) async {
      final newColor = await showColorPickerDialog(
        ctx,
        old,
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.both: true,
          ColorPickerType.primary: false,
          ColorPickerType.accent: false,
          ColorPickerType.custom: true,
          ColorPickerType.wheel: true,
        },
      );
      if (newColor != old) {
        await HapticFeedback.mediumImpact();
        setState(() {
          if (brightness == Brightness.light) {
            colors[index] = (light: newColor, dark: colors[index].dark);
          } else {
            colors[index] = (light: colors[index].light, dark: newColor);
          }
        });
      }
    }

    final current = colors[index];
    if (!isCupertino) {
      return Dismissible(
        direction: DismissDirection.endToStart,
        key: ObjectKey(current),
        onDismissed: (dir) async {
          setState(() {
            colors.removeAt(index);
          });
        },
        child: PaletteColorTile(
          colors: current,
          onEdit: (old, brightness) async {
            await changeColor(old, brightness);
          },
        ),
      );
    }
    return SwipeActionCell(
      key: ObjectKey(current),
      trailingActions: <SwipeAction>[
        SwipeAction(
          title: i18n.delete,
          style: context.textTheme.titleSmall ?? const TextStyle(),
          performsFirstActionWithFullSwipe: true,
          onTap: (CompletionHandler handler) async {
            await handler(true);
            setState(() {
              colors.removeAt(index);
            });
          },
          color: Colors.red,
        ),
      ],
      child: PaletteColorTile(
        colors: current,
        onEdit: (old, brightness) async {
          await changeColor(old, brightness);
        },
      ),
    );
  }

  Widget buildName() {
    return ListTile(
      isThreeLine: true,
      title: i18n.p13n.palette.name.text(),
      subtitle: TextField(
        controller: $name,
        decoration: InputDecoration(
          hintText: i18n.p13n.palette.namePlaceholder,
        ),
      ),
    );
  }

  Widget buildAuthor() {
    return ListTile(
      isThreeLine: true,
      title: i18n.p13n.palette.author.text(),
      subtitle: TextField(
        controller: $author,
        decoration: InputDecoration(
          hintText: i18n.p13n.palette.authorPlaceholder,
        ),
      ),
    );
  }
}

class PaletteColorTile extends StatelessWidget {
  final Color2Mode colors;
  final void Function(Color old, Brightness brightness)? onEdit;

  const PaletteColorTile({
    super.key,
    required this.colors,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final (:light, :dark) = colors;
    return ListTile(
      isThreeLine: true,
      visualDensity: VisualDensity.compact,
      title: [
        "#${light.hexAlpha}".text(),
        "#${dark.hexAlpha}".text(),
      ].row(maa: MainAxisAlignment.spaceBetween),
      subtitle: [
        buildColorBar(light, Brightness.light).expanded(),
        const SizedBox(width: 5),
        buildColorBar(dark, Brightness.dark).expanded(),
      ].row(mas: MainAxisSize.min, maa: MainAxisAlignment.spaceEvenly),
    );
  }

  Widget buildColorBar(
    Color color,
    Brightness brightness,
  ) {
    final onEdit = this.onEdit;
    return OutlinedCard(
      color: brightness == Brightness.light ? Colors.black : Colors.white,
      margin: EdgeInsets.zero,
      child: FilledCard(
        color: color,
        clip: Clip.hardEdge,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onEdit == null
              ? null
              : () {
                  onEdit.call(color, brightness);
                },
          onLongPress: () async {
            await Clipboard.setData(ClipboardData(text: "#${color.hexAlpha}"));
          },
          child: const SizedBox(height: 35),
        ),
      ),
    );
  }
}

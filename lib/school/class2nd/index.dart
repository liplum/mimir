import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mimir/design/widgets/app.dart';
import 'package:rettulf/rettulf.dart';

import "i18n.dart";

class Class2ndAppCard extends StatefulWidget {
  const Class2ndAppCard({super.key});

  @override
  State<Class2ndAppCard> createState() => _Class2ndAppCardState();
}

class _Class2ndAppCardState extends State<Class2ndAppCard> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: i18n.title.text(),
      leftActions: [
        FilledButton.icon(
          onPressed: () async {
            await context.push("/class2nd/activity");
          },
          label: "Activity".text(),
          icon: const Icon(Icons.local_activity_outlined),
        ),
        OutlinedButton(
          onPressed: () async {
            await context.push("/class2nd/attended");
          },
          child: "Attended".text(),
        )
      ],
      rightActions: [
        IconButton(
          onPressed: () async {},
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/design/adaptive/dialog.dart';
import 'package:sit/me/edu_email/index.dart';
import 'package:sit/me/network_tool/index.dart';
import 'package:sit/me/widgets/greeting.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/qrcode/handle.dart';
import 'package:url_launcher/url_launcher_string.dart';
import "i18n.dart";

const _qGroupNumber = "917740212";
const _joinQGroupUri =
    "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=$_qGroupNumber&card_type=group&source=qrcode";

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            titleTextStyle: context.textTheme.headlineSmall,
            actions: [
              buildScannerAction(),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.push("/settings");
                },
              ),
            ],
          ),
          const SliverToBoxAdapter(
            child: Greeting(),
          ),
          const SliverToBoxAdapter(
            child: EduEmailAppCard(),
          ),
          const SliverToBoxAdapter(
            child: NetworkToolAppCard(),
          ),
          SliverToBoxAdapter(
            child: buildGroupInvitation(),
          ),
        ],
      ),
    );
  }

  Widget buildGroupInvitation() {
    return ListTile(
      title: "预览版 QQ交流群".text(),
      subtitle: _qGroupNumber.text(),
      trailing: [
        IconButton(
          onPressed: () async {
            try {
              await launchUrlString(_joinQGroupUri);
            } catch (_) {}
          },
          icon: const Icon(Icons.group),
        ),
        IconButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: _qGroupNumber));
            if (!mounted) return;
            context.showSnackBar("已复制到剪贴板".text());
          },
          icon: const Icon(Icons.copy),
        ),
      ].row(mas: MainAxisSize.min),
      onTap: () async {
        try {
          await launchUrlString(_joinQGroupUri);
        } catch (_) {}
      },
    );
  }

  Widget buildScannerAction() {
    return IconButton(
      onPressed: () async {
        final res = await context.push("/tools/scanner");
        if (res is String) {
          if (!mounted) return;
          final result = await onHandleQrCodeData(context: context, data: res);
          if (result == QrCodeHandleResult.success) {
            return;
          }
        }
        if(!mounted) return;
        // TODO: QR Code
        await context.showTip(title: "Result", desc: res.toString(), ok: i18n.ok);
      },
      icon: const Icon(Icons.qr_code_scanner_outlined),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/design/adaptive/dialog.dart';
import 'package:sit/design/adaptive/editor.dart';
import 'package:sit/design/adaptive/foundation.dart';
import 'package:sit/design/adaptive/multiplatform.dart';
import 'package:sit/design/widgets/list_tile.dart';
import 'package:sit/init.dart';
import 'package:sit/network/widgets/checker.dart';
import 'package:sit/qrcode/page/view.dart';
import 'package:sit/settings/settings.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/settings/dev.dart';
import 'package:sit/utils/error.dart';
import 'package:sit/utils/save.dart';
import '../entity/proxy.dart';
import '../i18n.dart';
import '../qrcode/proxy.dart';

class ProxySettingsPage extends ConsumerStatefulWidget {
  const ProxySettingsPage({
    super.key,
  });

  @override
  ConsumerState<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends ConsumerState<ProxySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const RangeMaintainingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar.large(
            pinned: true,
            snap: false,
            floating: false,
            title: i18n.proxy.title.text(),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              buildEnableProxyToggle(),
              buildProxyModeSwitcher(),
              const Divider(),
              buildProxyTypeTile(
                ProxyCat.http,
                icon: const Icon(Icons.http),
              ),
              buildProxyTypeTile(
                ProxyCat.https,
                icon: const Icon(Icons.https),
              ),
              if (Dev.on)
                buildProxyTypeTile(
                  ProxyCat.all,
                  icon: const Icon(Icons.public),
                ),
              const Divider(),
              TestConnectionTile(
                where: WhereToCheck.studentReg,
                check: () async => await Init.ugRegSession.checkConnectivity(),
              ),
              const ProxyShareQrCodeTile(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget buildProxyTypeTile(
    ProxyCat type, {
    required Widget icon,
  }) {
    final ProxyProfile? profile;
    try {
      profile = ref.watch(Settings.proxy.$profileOf(type));
    } catch (error, stackTrace) {
      debugPrintError(error, stackTrace);
      rethrow;
    }
    return ListTile(
      leading: icon,
      title: type.l10n().text(),
      subtitle: profile?.address.toString().text(),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final profile = await context.showSheet<dynamic>(
          (ctx) => ProxyProfileEditorPage(type: type),
        );
        if (profile is ProxyProfile) {
          ref.read(Settings.proxy.$profileOf(type).notifier).set(profile);
        } else if (profile == ProxyProfile.clear) {
          ref.read(Settings.proxy.$profileOf(type).notifier).set(null);
        }
      },
    );
  }

  Widget buildEnableProxyToggle() {
    final anyEnabled = ref.watch(Settings.proxy.$anyEnabled);
    return _EnableProxyToggleTile(
      enabled: anyEnabled,
      onChanged: (newV) {
        setState(() {
          ref.read(Settings.proxy.$anyEnabled.notifier).set?.call(newV);
        });
      },
    );
  }

  Widget buildProxyModeSwitcher() {
    final integratedProxyMode = ref.watch(Settings.proxy.$integratedProxyMode);
    return _ProxyModeSwitcherTile(
      proxyMode: integratedProxyMode,
      onChanged: (value) {
        setState(() {
          ref.watch(Settings.proxy.$integratedProxyMode.notifier).set?.call(value);
        });
      },
    );
  }
}

Uri? _validateProxyUri(String uriString) {
  final uri = Uri.tryParse(uriString);
  if (uri == null || !uri.isAbsolute) {
    return null;
  }
  return uri;
}

Uri? _validateProxyUriForType(String uriString, ProxyCat type) {
  final uri = _validateProxyUri(uriString);
  if (uri == null) return null;
  return !type.supportedProtocols.contains(uri.scheme) ? null : uri;
}

class ProxyShareQrCodeTile extends StatelessWidget {
  const ProxyShareQrCodeTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(context.icons.qrcode),
      title: i18n.proxy.shareQrCode.text(),
      subtitle: i18n.proxy.shareQrCodeDesc.text(),
      trailing: Icon(context.icons.share),
      onTap: () async {
        final proxy = Settings.proxy;
        final qrCodeData = const ProxyDeepLink().encode(
          http: proxy.http,
          https: proxy.https,
          all: proxy.all,
        );
        context.showSheet(
          (context) => QrCodePage(
            title: i18n.proxy.title,
            data: qrCodeData.toString(),
          ),
        );
      },
    );
  }
}

Future<void> onProxyFromQrCode({
  required BuildContext context,
  required ProxyProfile? http,
  required ProxyProfile? https,
  required ProxyProfile? all,
}) async {
  final confirm = await context.showActionRequest(
    desc: i18n.proxy.setFromQrCodeDesc,
    action: i18n.proxy.setFromQrCodeAction,
    cancel: i18n.cancel,
  );
  if (confirm != true) return;
  bool isValid(Uri? uri, ProxyCat type) {
    return uri == null ? true : _validateProxyUriForType(uri.toString(), type) != null;
  }

  var valid = isValid(http?.address, ProxyCat.http) &&
      isValid(https?.address, ProxyCat.https) &&
      isValid(all?.address, ProxyCat.all);
  if (!valid) {
    if (!context.mounted) return;
    context.showTip(
      title: i18n.error,
      desc: i18n.proxy.invalidProxyFormatTip,
      primary: i18n.close,
    );
    return;
  }
  final cat2Address = {
    ProxyCat.http: http,
    ProxyCat.https: https,
    ProxyCat.all: all,
  };
  Settings.proxy.applyForeach((cat, profile, set) {
    final profile = cat2Address[cat];
    if (profile != null) {
      set(profile);
    }
  });

  await HapticFeedback.mediumImpact();
  if (!context.mounted) return;
  context.push("/settings/proxy");
}

class ProxyProfileEditorPage extends ConsumerStatefulWidget {
  final ProxyCat type;

  const ProxyProfileEditorPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<ProxyProfileEditorPage> createState() => _ProxyProfileEditorPageState();
}

class _ProxyProfileEditorPageState extends ConsumerState<ProxyProfileEditorPage> {
  late final profile = Settings.proxy.getProfileOf(widget.type);
  late var enabled = profile?.enabled ?? false;
  late var proxyMode = profile?.mode ?? ProxyMode.schoolOnly;
  late var scheme = profile?.address.scheme;
  late var host = profile?.address.host;
  late var port = profile?.address.port;
  late var enableAuth = profile?.address.userInfo.isNotEmpty == true;
  late var userInfo = profile?.address.userInfo;

  ProxyCat get type => widget.type;

  Uri? get uri {
    final scheme = this.scheme;
    final host = this.host;
    final port = this.port;
    final userInfo = this.userInfo;
    if (scheme != null && host != null && port != null) {
      return Uri(
        scheme: scheme,
        host: host,
        port: port,
        userInfo: userInfo,
      );
    } else {
      return null;
    }
  }

  set uri(Uri? uri) {
    scheme = uri?.scheme;
    host = uri?.host;
    port = uri?.port;
    userInfo = uri?.userInfo;
  }

  bool canSave() {
    if (scheme == null && host == null && port == null) return true;
    if (scheme != null && host != null && port != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final canSave = this.canSave();
    return PromptSaveBeforeQuitScope(
      changed: canSave && buildProfile() != profile,
      onSave: onSave,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: widget.type.l10n().text(),
              actions: [
                PlatformTextButton(
                  onPressed: uri?.toString().isNotEmpty == true
                      ? () {
                          setState(() {
                            uri = null;
                            enableAuth = false;
                          });
                        }
                      : null,
                  child: i18n.clear.text(),
                ),
                PlatformTextButton(
                  onPressed: canSave ? onSave : null,
                  child: i18n.save.text(),
                ),
              ],
            ),
            SliverList.list(children: [
              buildEnableProxyToggle(),
              buildProxyModeSwitcher(),
              buildProxyUrlTile(),
              const Divider(),
              buildProxyProtocolTile(),
              buildProxyHostTile(),
              buildProxyPortTile(),
              buildEnableAuth(),
              if (enableAuth) buildProxyAuthTile().padOnly(l: 32),
            ]),
          ],
        ),
      ),
    );
  }

  void onSave() {
    context.pop(buildProfile() ?? ProxyProfile.clear);
  }

  ProxyProfile? buildProfile() {
    var uri = this.uri;
    if (uri == null) return null;
    if (!enableAuth) {
      uri = uri.replace(userInfo: "");
    }
    return ProxyProfile(
      address: uri,
      enabled: enabled,
      mode: proxyMode,
    );
  }

  Widget buildProxyUrlTile() {
    final uri = this.uri;
    return DetailListTile(
      leading: const Icon(Icons.link),
      title: "URL",
      subtitle: uri?.toString(),
      trailing: Icon(context.icons.edit),
      onTap: () async {
        var newFullProxy = await Editor.showStringEditor(
          context,
          desc: i18n.proxy.title,
          initial: uri?.toString() ?? type.buildDefaultUri().toString(),
        );
        if (newFullProxy == null) return;
        newFullProxy = newFullProxy.trim();
        final newUri = _validateProxyUriForType(newFullProxy, type);
        if (newUri == null) {
          if (!mounted) return;
          context.showTip(
            title: i18n.error,
            desc: i18n.proxy.invalidProxyFormatTip,
            primary: i18n.close,
          );
          return;
        }
        if (newUri != uri) {
          setState(() {
            this.uri = newUri;
            enableAuth = newUri.userInfo.isNotEmpty;
          });
        }
      },
    );
  }

  Widget buildProxyProtocolTile() {
    final scheme = this.scheme;
    return ListTile(
      isThreeLine: true,
      leading: const Icon(Icons.https),
      title: i18n.proxy.protocol.text(),
      subtitle: type.supportedProtocols
          .map((protocol) => ChoiceChip(
                label: protocol.toUpperCase().text(),
                selected: protocol == scheme,
                onSelected: (value) {
                  setState(() {
                    this.scheme = protocol;
                  });
                },
              ))
          .toList()
          .wrap(spacing: 4),
    );
  }

  Widget buildProxyHostTile() {
    final host = this.host;
    return DetailListTile(
      leading: const Icon(Icons.link),
      title: i18n.proxy.hostname,
      subtitle: host,
      trailing: Icon(context.icons.edit),
      onTap: () async {
        final newHostRaw = await Editor.showStringEditor(
          context,
          desc: i18n.proxy.hostname,
          initial: host ?? type.defaultHost,
        );
        if (newHostRaw == null) return;
        final newHost = newHostRaw.trim();
        if (newHost != host) {
          setState(() {
            this.host = newHostRaw.isNotEmpty ? newHostRaw : null;
          });
        }
      },
    );
  }

  Widget buildProxyPortTile() {
    final port = this.port;
    return DetailListTile(
      leading: const Icon(Icons.settings_input_component_outlined),
      title: i18n.proxy.port,
      subtitle: port?.toString(),
      trailing: Icon(context.icons.edit),
      onTap: () async {
        final newPort = await Editor.showIntEditor(
          context,
          desc: i18n.proxy.port,
          initial: port ?? type.defaultPort,
        );
        if (newPort == null) return;
        if (newPort != port) {
          setState(() {
            this.port = newPort;
          });
        }
      },
    );
  }

  Widget buildEnableAuth() {
    return ListTile(
      leading: const Icon(Icons.key),
      title: i18n.proxy.enableAuth.text(),
      trailing: Switch.adaptive(
        value: enableAuth,
        onChanged: (newV) {
          setState(() {
            enableAuth = newV;
          });
        },
      ),
    );
  }

  Widget buildProxyAuthTile() {
    final userInfo = this.userInfo;
    final userInfoParts = userInfo?.split(":");
    final auth = userInfoParts == null
        ? null
        : userInfoParts.length == 2
            ? (username: userInfoParts[0], password: userInfoParts[1])
            : (username: userInfoParts[0], password: null);
    final text = auth != null
        ? auth.password != null
            ? "${auth.username}:${auth.password}"
            : auth.username
        : null;
    return DetailListTile(
      title: i18n.proxy.authentication,
      subtitle: text,
      trailing: Icon(context.icons.edit),
      onTap: () async {
        final newAuth = await showAdaptiveDialog<({String username, String password})>(
          context: context,
          builder: (_) => StringsEditor(
            fields: [
              (name: "username", initial: auth?.username ?? ""),
              (name: "password", initial: auth?.password ?? ""),
            ],
            title: i18n.proxy.authentication,
            ctor: (values) => (username: values[0].trim(), password: values[1].trim()),
          ),
        );
        if (newAuth != null && newAuth != auth) {
          setState(() {
            this.userInfo = newAuth.username.isEmpty
                ? null
                : newAuth.password.isNotEmpty
                    ? "${newAuth.username}:${newAuth.password}"
                    : newAuth.username;
          });
        }
      },
    );
  }

  Widget buildEnableProxyToggle() {
    return _EnableProxyToggleTile(
      enabled: enabled,
      onChanged: (newV) {
        setState(() {
          enabled = newV;
        });
      },
    );
  }

  Widget buildProxyModeSwitcher() {
    return _ProxyModeSwitcherTile(
      proxyMode: proxyMode,
      onChanged: (value) {
        setState(() {
          proxyMode = value;
        });
      },
    );
  }
}

class _EnableProxyToggleTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _EnableProxyToggleTile({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: i18n.proxy.enableProxy.text(),
      subtitle: i18n.proxy.enableProxyDesc.text(),
      leading: const Icon(Icons.vpn_key),
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _ProxyModeSwitcherTile extends StatefulWidget {
  final ProxyMode? proxyMode;
  final ValueChanged<ProxyMode> onChanged;

  const _ProxyModeSwitcherTile({
    required this.proxyMode,
    required this.onChanged,
  });

  @override
  State<_ProxyModeSwitcherTile> createState() => _ProxyModeSwitcherTileState();
}

class _ProxyModeSwitcherTileState extends State<_ProxyModeSwitcherTile> {
  final $tooltip = GlobalKey<TooltipState>(debugLabel: "Info tooltip");

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      leading: const Icon(Icons.public),
      title: i18n.proxy.proxyMode.text(),
      subtitle: ProxyMode.values
          .map((mode) => ChoiceChip(
                label: mode.l10nName().text(),
                selected: widget.proxyMode == mode,
                onSelected: (value) {
                  widget.onChanged(mode);
                },
              ))
          .toList()
          .wrap(spacing: 4),
      onTap: () async {
        $tooltip.currentState?.ensureTooltipVisible();
        await Future.delayed(const Duration(milliseconds: 1500));
        Tooltip.dismissAllToolTips();
      },
      trailing: Tooltip(
        key: $tooltip,
        triggerMode: TooltipTriggerMode.tap,
        message: buildTooltip(),
        child: Icon(context.icons.info),
      ).padAll(8),
    );
  }

  String buildTooltip() {
    final proxyMode = widget.proxyMode;
    if (proxyMode == null) {
      return ProxyMode.values.map((mode) => "${mode.l10nName()}: ${mode.l10nTip()}").join("\n");
    } else {
      return proxyMode.l10nTip();
    }
  }
}

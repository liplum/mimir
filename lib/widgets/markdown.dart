import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart';

import 'html.dart';

class FeaturedMarkdownWidget extends StatefulWidget {
  final String data;
  final bool async;
  final bool restyle;

  const FeaturedMarkdownWidget({
    super.key,
    required this.data,
    this.async = false,
    this.restyle = false,
  });

  @override
  State<FeaturedMarkdownWidget> createState() => _FeaturedMarkdownWidgetState();
}

class _FeaturedMarkdownWidgetState extends State<FeaturedMarkdownWidget> {
  late String html;

  @override
  void initState() {
    super.initState();
    html = buildHtml();
  }

  @override
  void didUpdateWidget(FeaturedMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      setState(() {
        html = buildHtml();
      });
    }
  }

  String buildHtml() {
    return markdownToHtml(
      widget.data,
      inlineSyntaxes: [
        InlineHtmlSyntax(),
        StrikethroughSyntax(),
        AutolinkExtensionSyntax(),
        EmojiSyntax(),
      ],
      blockSyntaxes: const [
        FencedCodeBlockSyntax(),
        TableSyntax(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restyle) {
      return RestyledHtmlWidget(
        html,
        async: widget.async,
      );
    } else {
      return HtmlWidget(
        html,
        buildAsync: widget.async,
      );
    }
  }
}

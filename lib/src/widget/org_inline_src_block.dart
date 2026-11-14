import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/src/highlight.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode inline source block
class OrgInlineSrcBlockWidget extends StatelessWidget {
  const OrgInlineSrcBlockWidget(this.block, {super.key});

  final OrgInlineSrcBlock block;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final orgTheme = OrgTheme.dataOf(context);
    final blockStyle = orgTheme.blockStyle(defaultStyle);
    // The language keeps metaColor, unless blockTextStyle sets a color: the
    // style applies to the inline block as a whole, as org-block does.
    final languageStyle = defaultStyle
        .copyWith(color: orgTheme.metaColor)
        .merge(orgTheme.blockTextStyle);
    final metaStyle = languageStyle.color == null
        ? languageStyle.copyWith(color: orgTheme.metaColor)
        : languageStyle;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: block.leading, style: blockStyle),
          TextSpan(text: block.language, style: metaStyle),
          if (block.arguments != null)
            TextSpan(text: block.arguments, style: blockStyle),
          TextSpan(text: '{', style: blockStyle),
          if (supportedSrcLanguage(block.language))
            buildSrcHighlightSpan(
              context,
              code: trimPrefSuff(block.body, '{', '}'),
              languageId: block.language,
            )
          else
            TextSpan(
              text: trimPrefSuff(block.body, '{', '}'),
              style: blockStyle,
            ),
          TextSpan(text: '}', style: blockStyle),
        ],
      ),
    );
  }
}

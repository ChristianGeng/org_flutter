import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

const _mono = TextStyle(fontFamily: 'TestMono');

const _doc = '''
Plain text with ~inline code~ and =inline verbatim= in it.

Inline source: src_sh[:exports code]{echo inlinesrc}

Highlighted inline source: src_dart{var inlineHighlighted = 1}

#+begin_src dart
var highlightedValue = 1;
#+end_src

#+begin_src nosuchlanguage
unknown language body
#+end_src

#+begin_src
no language body
#+end_src

#+begin_example
example body
#+end_example

#+begin_export html
export body
#+end_export

: fixed width line

#+begin_verse
verse body
#+end_verse
''';

const _codeNeedles = [
  'inline code',
  'inline verbatim',
  'echo inlinesrc',
  'inlineHighlighted',
  'highlightedValue',
  'unknown language body',
  'no language body',
  'example body',
  'export body',
  'fixed width line',
];

/// The effective style of the first text run containing [needle], with the
/// styles of all enclosing spans applied.
TextStyle _styleOf(String needle) {
  TextStyle? found;
  bool visit(InlineSpan span, TextStyle inherited) {
    final style = inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.contains(needle) ?? false) {
        found = style;
        return false;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        if (!visit(child, style)) return false;
      }
    }
    return true;
  }

  for (final element in find.byType(RichText).evaluate()) {
    final richText = element.widget as RichText;
    if (!visit(richText.text, const TextStyle())) break;
  }
  if (found == null) fail('No text run contains "$needle"');
  return found!;
}

/// A tall test window, so the whole document is built (it is in a scrolling
/// list, and only visible children are built).
void _tallWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _org({TextStyle? codeTextStyle}) => wrap(
  Org(
    _doc,
    lightTheme: OrgThemeData.light().copyWith(codeTextStyle: codeTextStyle),
    darkTheme: OrgThemeData.dark().copyWith(codeTextStyle: codeTextStyle),
  ),
);

void main() {
  group('codeTextStyle', () {
    testWidgets('Applies to code', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org(codeTextStyle: _mono));
      for (final needle in _codeNeedles) {
        expect(_styleOf(needle).fontFamily, 'TestMono', reason: needle);
      }
      // The language name of an inline source block is in the code font too
      expect(_styleOf('sh').fontFamily, 'TestMono');
      // Without a color in codeTextStyle, code keeps codeColor
      expect(_styleOf('example body').color, OrgThemeData.light().codeColor);
    });
    testWidgets('Color in codeTextStyle overrides codeColor', (tester) async {
      const red = Color(0xffff0000);
      _tallWindow(tester);
      await tester.pumpWidget(_org(codeTextStyle: _mono.copyWith(color: red)));
      expect(_styleOf('example body').color, red);
      expect(_styleOf('inline code').color, red);
    });
    testWidgets('Does not apply to other text', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org(codeTextStyle: _mono));
      for (final needle in ['Plain text with', 'verse body']) {
        expect(_styleOf(needle).fontFamily, isNot('TestMono'), reason: needle);
      }
    });
    testWidgets('Null keeps code in the surrounding font', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org());
      final surrounding = _styleOf('Plain text with').fontFamily;
      for (final needle in _codeNeedles) {
        expect(_styleOf(needle).fontFamily, surrounding, reason: needle);
      }
    });
  });
  group('Widgets inside highlighted source', () {
    testWidgets('Coderef', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        wrap(
          Org(
            '''
#+begin_src dart
var step = 1; // (ref:step)
#+end_src
''',
            lightTheme: OrgThemeData.light().copyWith(codeTextStyle: _mono),
            darkTheme: OrgThemeData.dark().copyWith(codeTextStyle: _mono),
          ),
        ),
      );
      expect(_styleOf('(ref:step)').fontFamily, 'TestMono');
    });
    testWidgets('Nested tokens keep the enclosing color', (tester) async {
      _tallWindow(tester);
      const green = Color(0xff00aa00);
      final theme = OrgThemeData.light().copyWith(
        codeTextStyle: _mono,
        srcTheme: {
          'string': const TextStyle(color: green),
          'subst': const TextStyle(fontWeight: FontWeight.bold),
        },
      );
      await tester.pumpWidget(
        wrap(
          Org(
            r'''
#+begin_src dart
var s = "a ${nestedvar} b";
#+end_src
''',
            lightTheme: theme,
            darkTheme: theme,
          ),
        ),
      );
      final style = _styleOf('nestedvar');
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, green);
      expect(style.fontFamily, 'TestMono');
    });
    testWidgets('Search match', (tester) async {
      _tallWindow(tester);
      final doc = OrgDocument.parse('''
#+begin_src dart
var searchme = 1;
#+end_src
''');
      await tester.pumpWidget(
        wrap(
          OrgController(
            root: doc,
            searchQuery: 'searchme',
            child: OrgRootWidget(
              lightTheme: OrgThemeData.light().copyWith(codeTextStyle: _mono),
              darkTheme: OrgThemeData.dark().copyWith(codeTextStyle: _mono),
              child: OrgDocumentWidget(doc),
            ),
          ),
        ),
      );
      expect(_styleOf('searchme').fontFamily, 'TestMono');
    });
    testWidgets('Unmatched code during search', (tester) async {
      _tallWindow(tester);
      final doc = OrgDocument.parse('''
Plain words here.

#+begin_src dart
var findme = 1; final unmatchedrun = 2;
#+end_src
''');
      await tester.pumpWidget(
        wrap(
          OrgController(
            root: doc,
            searchQuery: 'findme',
            child: OrgRootWidget(
              lightTheme: OrgThemeData.light().copyWith(codeTextStyle: _mono),
              darkTheme: OrgThemeData.dark().copyWith(codeTextStyle: _mono),
              child: OrgDocumentWidget(doc),
            ),
          ),
        ),
      );
      // The match inside the source block, and unstyled code around it
      expect(_styleOf('findme').fontFamily, 'TestMono');
      expect(_styleOf('unmatchedrun').fontFamily, 'TestMono');
      // Plain text outside the block
      expect(_styleOf('Plain words here').fontFamily, isNot('TestMono'));
    });
  });
  group('OrgThemeData.codeTextStyle', () {
    test('copyWith', () {
      final theme = OrgThemeData.light().copyWith(codeTextStyle: _mono);
      expect(theme.codeTextStyle, _mono);
      expect(theme.copyWith().codeTextStyle, _mono);
    });
    test('equality', () {
      final a = OrgThemeData.light().copyWith(codeTextStyle: _mono);
      final b = OrgThemeData.light().copyWith(codeTextStyle: _mono);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == OrgThemeData.light(), isFalse);
    });
    test('lerp', () {
      final a = OrgThemeData.light().copyWith(
        codeTextStyle: const TextStyle(fontFamily: 'TestMono', fontSize: 10),
      );
      final b = OrgThemeData.light().copyWith(
        codeTextStyle: const TextStyle(fontFamily: 'TestMono', fontSize: 20),
      );
      expect(OrgThemeData.lerp(a, b, 0.5)?.codeTextStyle?.fontSize, 15);
    });
    test('lerp from null', () {
      final a = OrgThemeData.light();
      final b = OrgThemeData.light().copyWith(codeTextStyle: _mono);
      expect(OrgThemeData.lerp(a, b, 0)?.codeTextStyle?.fontFamily, isNull);
      expect(OrgThemeData.lerp(a, b, 1)?.codeTextStyle?.fontFamily, 'TestMono');
    });
    test('codeStyle merges codeTextStyle on top of codeColor', () {
      final theme = OrgThemeData.light().copyWith(codeTextStyle: _mono);
      final style = theme.codeStyle(const TextStyle(fontSize: 12));
      expect(style.fontFamily, 'TestMono');
      expect(style.fontSize, 12);
      expect(style.color, theme.codeColor);
    });
    test('codeStyle with a non-inheriting codeTextStyle', () {
      const code = TextStyle(inherit: false, fontFamily: 'TestMono');
      final theme = OrgThemeData.light().copyWith(codeTextStyle: code);
      final style = theme.codeStyle(const TextStyle(fontSize: 12));
      // Replaces the base style, but keeps codeColor
      expect(style.inherit, isFalse);
      expect(style.fontFamily, 'TestMono');
      expect(style.fontSize, isNull);
      expect(style.color, theme.codeColor);
      // Its own color wins
      const red = Color(0xffff0000);
      final themeRed = OrgThemeData.light().copyWith(
        codeTextStyle: code.copyWith(color: red),
      );
      expect(themeRed.codeStyle(const TextStyle()).color, red);
    });
    test('codeStyle without codeTextStyle only sets codeColor', () {
      const base = TextStyle(fontSize: 12, fontFamily: 'Body');
      final theme = OrgThemeData.light();
      expect(theme.codeStyle(base), base.copyWith(color: theme.codeColor));
    });
  });
}

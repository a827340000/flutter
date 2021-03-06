// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;
import 'package:path/path.dart' as path;

import 'package:platform/platform.dart' show FakePlatform;

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import 'package:snippets/configuration.dart';
import 'package:snippets/snippets.dart';

void main() {
  group('Generator', () {
    FakePlatform fakePlatform;
    Configuration configuration;
    SnippetGenerator generator;
    Directory tmpDir;
    File template;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('snippets_test');
      fakePlatform = FakePlatform(
          script: Uri.file(path.join(
              tmpDir.absolute.path, 'flutter', 'dev', 'snippets', 'lib', 'snippets_test.dart')));
      configuration = Configuration(platform: fakePlatform);
      configuration.createOutputDirectory();
      configuration.templatesDirectory.createSync(recursive: true);
      configuration.skeletonsDirectory.createSync(recursive: true);
      template = File(path.join(configuration.templatesDirectory.path, 'template.tmpl'));
      template.writeAsStringSync('''

{{description}}

{{code-preamble}}

main() {
  {{code}}
}
''');
      configuration.getHtmlSkeletonFile(SnippetType.application).writeAsStringSync('''
<div>HTML Bits</div>
{{description}}
<pre>{{code}}</pre>
<pre>{{app}}</pre>
<div>More HTML Bits</div>
''');
      configuration.getHtmlSkeletonFile(SnippetType.sample).writeAsStringSync('''
<div>HTML Bits</div>
{{description}}
<pre>{{code}}</pre>
<div>More HTML Bits</div>
''');
      generator = SnippetGenerator(configuration: configuration);
    });
    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('generates application snippets', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
A description of the snippet.

On several lines.

```dart preamble
const String name = 'snippet';
```

```dart
void main() {
  print('The actual \$name.');
}
```
''');

      final String html =
          generator.generate(inputFile, SnippetType.application, template: 'template', id: 'id');
      expect(html, contains('<div>HTML Bits</div>'));
      expect(html, contains('<div>More HTML Bits</div>'));
      expect(html, contains("print('The actual \$name.');"));
      expect(html, contains('A description of the snippet.\n'));
      expect(
          html,
          contains('// A description of the snippet.\n'
              '//\n'
              '// On several lines.\n'));
      expect(html, contains('void main() {'));
    });

    test('generates sample snippets', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
A description of the snippet.

On several lines.

```code
void main() {
  print('The actual \$name.');
}
```
''');

      final String html = generator.generate(inputFile, SnippetType.sample);
      expect(html, contains('<div>HTML Bits</div>'));
      expect(html, contains('<div>More HTML Bits</div>'));
      expect(html, contains("print('The actual \$name.');"));
      expect(html, contains('A description of the snippet.\n\nOn several lines.\n'));
      expect(html, contains('main() {'));
    });
  });
}

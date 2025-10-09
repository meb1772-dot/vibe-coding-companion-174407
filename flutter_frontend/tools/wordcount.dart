/*
Simple utility to count words across chapter JSON section bodies.

Usage:
  dart tools/wordcount.dart

Notes:
- Run this from the flutter_frontend directory so relative asset paths resolve.
- This is a dev helper and not used by the production app.
*/
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final dir = Directory('assets/content/chapters');
  if (!await dir.exists()) {
    stderr.writeln('Directory not found: assets/content/chapters');
    exit(1);
  }

  final indexFile = File('${dir.path}/index.json');
  if (!await indexFile.exists()) {
    stderr.writeln('Missing index.json in ${dir.path}');
    exit(1);
  }

  final index =
      jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
  final chapters = (index['chapters'] as List).cast<Map>();
  int totalWords = 0;

  for (final ch in chapters) {
    final filePath = ch['file']?.toString() ?? '';
    if (filePath.isEmpty) continue;
    final file = File(filePath);
    if (!await file.exists()) {
      stderr.writeln('Missing chapter file: $filePath');
      continue;
    }
    final parsed =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final sections = (parsed['sections'] as List?) ?? const [];
    int chapterWords = 0;
    for (final s in sections) {
      final body = (s as Map)['body']?.toString() ?? '';
      chapterWords += _wordCount(body);
    }
    totalWords += chapterWords;
    stdout.writeln('${ch['id']}: $chapterWords words');
  }

  stdout.writeln('TOTAL: $totalWords words');
}

int _wordCount(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return 0;
  // Split on whitespace
  return cleaned.split(RegExp(r'\\s+')).where((e) => e.isNotEmpty).length;
}

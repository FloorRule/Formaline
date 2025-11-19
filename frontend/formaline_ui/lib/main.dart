import 'package:flutter/material.dart';
import 'custom_keyboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: KeyboardDemo(),
    );
  }
}

class KeyboardDemo extends StatefulWidget {
  @override
  State<KeyboardDemo> createState() => _KeyboardDemoState();
}

class _KeyboardDemoState extends State<KeyboardDemo> {
  final TextEditingController _controller = TextEditingController();

  void insertText(String value) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0) return;

    if (start == 0) {
      if (value != 'BACKSPACE' && value != 'ENTER') {
        String prefix = text.isEmpty ? '${_bulletForLevel(0)}' : '';
        final newText = text.replaceRange(start, end, prefix + value);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + prefix.length + value.length),
        );
      }
      return;
    }

    setState(() {
      if (value == 'BACKSPACE') {
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        final currentLine = text.substring(lineStart, start);

        final indentMatch = RegExp(r'^(\s*)•.*$').firstMatch(currentLine);
        final isOnlyBulletLine = RegExp(r'^\s*•\s*$').hasMatch(currentLine);

        if (isOnlyBulletLine && currentLine.trim().length == 1) {
          if (currentLine.length == 1) {
            if (_controller.text.isNotEmpty) {
              _controller.text = _controller.text.substring(0, _controller.text.length - 1);
            }
          } else {
            final indentLength = (indentMatch?.group(1)?.length ?? 0);
            final newIndent = ' ' * (indentLength - 2).clamp(0, 100);
            final updatedLine = '$newIndent${_bulletForLevel(newIndent.length ~/ 2)}';

            final newText = text.replaceRange(lineStart, start, updatedLine);
            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: lineStart + updatedLine.length),
            );
          }
        } else if (start == end && start > 0) {
          final newText = text.replaceRange(start - 1, start, '');
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start - 1),
          );
        } else if (start != end) {
          final newText = text.replaceRange(start, end, '');
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start),
          );
        }
      } else if (value == 'CLEAR') {
        _controller.clear();
      } else if (value == 'ENTER') {
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        final currentLine = text.substring(lineStart, start);
        final indentMatch = RegExp(r'^\s*').firstMatch(currentLine);
        final baseIndent = indentMatch?.group(0) ?? '';

        final level = baseIndent.length ~/ 2;
        final needsExtraIndent = currentLine.trimRight().endsWith(':');
        final newLevel = needsExtraIndent ? level + 1 : level;

        final indent = ' ' * (newLevel * 2);
        final bullet = _bulletForLevel(newLevel);
        final insertText = '\n$indent$bullet';

        final newText = text.replaceRange(start, end, insertText);
        final newOffset = start + insertText.length;

        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      } else {
        String prefix = text.isEmpty ? '${_bulletForLevel(0)}' : '';
        final newText = text.replaceRange(start, end, prefix + value);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + prefix.length + value.length),
        );
      }
    });
  }

  String _bulletForLevel(int level) {
    const bullets = ['•', '•›', '•»', '•›››', '•»»»'];
    return bullets[level.clamp(0, bullets.length - 1)];
  }

  Future<void> sendProof() async {
    final lines = _controller.text.trim().split('\n');
    final List<Map<String, dynamic>> proofSteps = [];

    for (var line in lines) {
      final trimmed = line.trimLeft();
      final bulletMatch = RegExp(r'^•(›*)\s*').firstMatch(trimmed);
      final indentLevel = bulletMatch != null ? bulletMatch.group(1)!.length : 0;
      final content = trimmed.replaceFirst(RegExp(r'^•(›*)\s*'), '');

      proofSteps.add({
        'indent': indentLevel,
        'text': content,
      });
    }

    final url = Uri.parse('http://192.168.1.101:8000/compile-proof');
    final payload = {'proof': proofSteps};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final isSuccess = result['result']['success'];
        final explanations = (result['result']['explanations'] as List<dynamic>).join('\n');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess ? '✅ Proof succeeded!' : '❌ Proof failed:\n$explanations',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Request failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formaline'),
        backgroundColor: const Color.fromRGBO(255, 236, 213, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: sendProof,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],

      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: TextField(
                controller: _controller,
                readOnly: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Write your proof here...',
                ),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SymbolKeyboard(onKeyPressed: insertText),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

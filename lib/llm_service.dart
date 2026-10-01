import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';

class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  Fllama? _fllama;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  static const String _systemPrompt =
      'Ты — ChickAI 1.0, дружелюбный и немного дерзкий ассистент. '
      'Отвечай кратко, по делу, с лёгким юмором. '
      'Не упоминай Google, Gemini, OpenAI и другие компании. '
      'Ты — самостоятельный продукт.';

  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/gemma-3-1b-q4.gguf';
      final modelFile = File(modelPath);

      // Копируем модель из assets при первом запуске
      if (!await modelFile.exists()) {
        final data = await rootBundle.load('assets/gemma-3-1b-q4.gguf');
        await modelFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }

      _fllama = Fllama();
      await _fllama!.init(
        modelPath: modelPath,
        nCtx: 2048,
        nThreads: 4,
      );
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  Future<String> generate(String userMessage) async {
    if (!_isLoaded || _fllama == null) {
      throw Exception('Модель не загружена');
    }

    final fullPrompt =
        '$_systemPrompt\n\nПользователь: $userMessage\nChickAI:';

    final result = await _fllama!.generate(
      prompt: fullPrompt,
      maxTokens: 512,
      temperature: 0.7,
    );

    return result;
  }

  void dispose() {
    _fllama?.dispose();
    _fllama = null;
    _isLoaded = false;
  }
}

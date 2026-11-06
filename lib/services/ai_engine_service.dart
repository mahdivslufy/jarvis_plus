import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../models/chat_message.dart';

class AiEngineService {
  Llama? _llama;
  bool _isModelLoaded = false;
  String? _currentModelPath;

  bool get isModelLoaded => _isModelLoaded;
  String? get currentModelPath => _currentModelPath;

  /// مقداردهی اولیه و بارگذاری مدل محلی از حافظه داخلی گوشی
  Future<bool> loadModel(String modelPath, {int contextSize = 1024}) async {
    final file = File(modelPath);
    if (!await file.exists()) {
      debugPrint("خطا: فایل مدل در مسیر یافت نشد: $modelPath");
      return false;
    }

    try {
      if (_llama != null) {
        unloadModel();
      }

      // لود دستی کتابخانه‌های پایه ggml قبل از لود llama در حافظه پروسه Dart
      if (Platform.isAndroid) {
        try {
          DynamicLibrary.open("libomp.so");
        } catch (_) {}
        try {
          DynamicLibrary.open("libggml-base.so");
        } catch (_) {}
        try {
          DynamicLibrary.open("libggml-cpu.so");
        } catch (_) {}
        try {
          DynamicLibrary.open("libggml.so");
        } catch (_) {}
        try {
          DynamicLibrary.open("libllama.so");
        } catch (_) {}
      }

      // تعیین تعداد رشته‌های پردازشی بر اساس سخت‌افزار دستگاه (محتاطانه برای پایداری روی موبایل)
      final cpuCores = Platform.numberOfProcessors;
      final optimalThreads = cpuCores > 4 ? 4 : (cpuCores > 2 ? 2 : 1);

      // در اندروید باید GPU Offload حتماً 0 باشد چون کتابخانه برای پردازنده CPU (ARM Neon) کامپایل شده است
      final modelParams = ModelParams()
        ..nGpuLayers = 0
        ..useMemorymap = true
        ..useMemoryLock = false;

      final contextParams = ContextParams()
        ..nCtx = contextSize
        ..nBatch = 256
        ..nUbatch = 256
        ..offloadKqv = false
        ..nThreads = optimalThreads
        ..nThreadsBatch = optimalThreads
        ..nPredict = -1; // تولید بدون محدودیت توکن

      _llama = Llama(modelPath, modelParams, contextParams);
      _isModelLoaded = true;
      _currentModelPath = modelPath;

      debugPrint("مدل با موفقیت لود شد: $modelPath با $optimalThreads رشته پردازشی");
      return true;
    } catch (e, stack) {
      debugPrint("خطا در بارگذاری مدل آفلاین: $e\n$stack");
      _isModelLoaded = false;
      return false;
    }
  }

  /// قالب‌بندی پرامپت با فرمت استاندارد ChatML برای مدل‌های سری Qwen و Llama
  String formatChatMlPrompt(List<ChatMessage> history, String systemPrompt) {
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>system\n$systemPrompt<|im_end|>');

    for (final msg in history) {
      if (msg.role == MessageRole.user) {
        buffer.writeln('<|im_start|>user\n${msg.text}<|im_end|>');
      } else if (msg.role == MessageRole.assistant) {
        buffer.writeln('<|im_start|>assistant\n${msg.text}<|im_end|>');
      }
    }

    buffer.write('<|im_start|>assistant\n');
    return buffer.toString();
  }

  /// تولید جریان توکن‌های پاسخ به صورت استریمینگ کاملاً آفلاین روی پردازنده گوشی
  Stream<String> generateStream(
    List<ChatMessage> conversation, {
    String systemPrompt = "تو جارویس پلاس هستی، دستیار هوش مصنوعی هوشمند، مودب و سریع که کاملاً آفلاین روی گوشی کاربر کار می‌کنی و به زبان فارسی پاسخ می‌دهی.",
  }) async* {
    if (!_isModelLoaded || _llama == null) {
      yield "خطا: مدلی در حافظه لود نشده است. لطفاً ابتدا از بخش مدل‌ها، یک مدل را دانلود و انتخاب نمایید.";
      return;
    }

    final prompt = formatChatMlPrompt(conversation, systemPrompt);

    try {
      _llama!.setPrompt(prompt);
      await for (final token in _llama!.generateText()) {
        if (token.contains('<|im_end|>') || token.contains('<|endoftext|>')) {
          final cleanToken = token
              .replaceAll('<|im_end|>', '')
              .replaceAll('<|endoftext|>', '');
          if (cleanToken.isNotEmpty) yield cleanToken;
          break;
        }
        yield token;
      }
    } catch (e) {
      yield "\n[خطا در پردازش On-Device: $e]";
    }
  }

  /// آزادسازی حافظه رم گوشی در صورت بستن برنامه یا سوییچ مدل
  void unloadModel() {
    try {
      _llama?.dispose();
    } catch (_) {}
    _llama = null;
    _isModelLoaded = false;
    _currentModelPath = null;
  }
}

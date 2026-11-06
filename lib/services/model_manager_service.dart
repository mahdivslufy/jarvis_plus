import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AiModelInfo {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String downloadUrl;
  final int sizeInBytes;
  final String requiredRam;

  const AiModelInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeInBytes,
    required this.requiredRam,
  });

  String get sizeInMb => "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(0)} مگابایت";
}

class ModelManagerService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 60),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      },
    ),
  );
  CancelToken? _cancelToken;
  String? lastError;

  /// فهرست مدل‌های پیشنهادی که روی هاستینگ ۱۰۰٪ رایگان و بدون محدودیت پهنای باند Hugging Face قرار دارند
  static const List<AiModelInfo> catalog = [
    AiModelInfo(
      id: "qwen_05b",
      title: "جارویس لایت (Qwen 2.5 0.5B)",
      description: "فوق‌العاده سریع و سبک، مناسب برای تمام گوشی‌ها با رم ۳ گیگابایت به بالا. درک عالی فارسی.",
      fileName: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
      // لینک مستقیم مخزن رایگان هاگینگ‌فیس بدون یک ریال هزینه سرور
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
      sizeInBytes: 397000000,
      requiredRam: "۳ گیگابایت",
    ),
    AiModelInfo(
      id: "qwen_15b",
      title: "جارویس پرو (Qwen 2.5 1.5B)",
      description: "مدل هوشمند اصلی با تسلط کامل بر انشا، تحلیل، شعر و ترجمه دقیق فارسی.",
      fileName: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
      sizeInBytes: 986000000,
      requiredRam: "۴ تا ۶ گیگابایت",
    ),
    AiModelInfo(
      id: "deepseek_15b",
      title: "جارویس استدلال (DeepSeek-R1 1.5B)",
      description: "مدل حل مسائل ریاضی، منطق، کدنویسی و تفکر گام‌به‌گام به صورت آفلاین.",
      fileName: "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      downloadUrl: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      sizeInBytes: 1120000000,
      requiredRam: "۶ گیگابایت به بالا",
    ),
  ];

  /// دریافت مسیر پوشه ذخیره‌سازی محلی مدل‌ها روی دستگاه
  Future<String> getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'jarvis_models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  /// بررسی اینکه آیا مدل مشخص روی گوشی ذخیره شده است یا خیر
  Future<bool> isModelDownloaded(AiModelInfo model) async {
    final dir = await getModelsDirectory();
    final filePath = p.join(dir, model.fileName);
    final file = File(filePath);
    if (!await file.exists()) return false;
    final length = await file.length();
    // بررسی تطابق اندازه فایل برای جلوگیری از استفاده از فایل‌های ناقص
    return length >= (model.sizeInBytes * 0.95);
  }

  /// مسیر کامل فایل مدل روی حافظه
  Future<String> getLocalModelPath(AiModelInfo model) async {
    final dir = await getModelsDirectory();
    return p.join(dir, model.fileName);
  }

  /// دانلود مدل با پشتیبانی کامل از سرگیری (Resume) و صفر هزینه پهنای باند
  Future<bool> downloadModel(
    AiModelInfo model, {
    required void Function(double progress, String statusText) onProgress,
  }) async {
    try {
      final dir = await getModelsDirectory();
      final savePath = p.join(dir, model.fileName);
      final tempPath = "$savePath.download";

      final tempFile = File(tempPath);
      int downloadedBytes = 0;

      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
      }

      _cancelToken = CancelToken();

      final options = Options(
        responseType: ResponseType.stream,
        headers: downloadedBytes > 0 ? {'Range': 'bytes=$downloadedBytes-'} : null,
      );

      final response = await _dio.get<ResponseBody>(
        model.downloadUrl,
        options: options,
        cancelToken: _cancelToken,
      );

      final statusCode = response.statusCode ?? 0;
      final isPartial = statusCode == 206;
      final fileSink = tempFile.openWrite(
        mode: isPartial ? FileMode.append : FileMode.write,
      );

      final totalBytes = (response.data?.contentLength ?? 0) + (isPartial ? downloadedBytes : 0);
      int receivedBytes = downloadedBytes;

      await for (final chunk in response.data!.stream) {
        fileSink.add(chunk);
        receivedBytes += chunk.length;

        final percent = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
        final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

        onProgress(percent, "$mbReceived از $mbTotal مگابایت");
      }

      await fileSink.flush();
      await fileSink.close();

      // تغییر نام فایل پس از اتمام موفقیت‌آمیز
      if (await File(savePath).exists()) {
        await File(savePath).delete();
      }
      await tempFile.rename(savePath);

      onProgress(1.0, "دانلود تکمیل شد");
      return true;
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        debugPrint("دانلود توسط کاربر متوقف شد");
        lastError = "دانلود متوقف شد";
      } else {
        debugPrint("خطا در دانلود مدل: $e");
        lastError = e.toString();
      }
      return false;
    }
  }

  /// متوقف ساختن دانلود جاری
  void pauseDownload() {
    _cancelToken?.cancel("متوقف شد");
    _cancelToken = null;
  }

  /// حذف فایل مدل برای آزادسازی فضای گوشی
  Future<void> deleteModel(AiModelInfo model) async {
    final dir = await getModelsDirectory();
    final file = File(p.join(dir, model.fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

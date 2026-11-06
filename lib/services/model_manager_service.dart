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
  final String supportedDevices; // دستگاه‌های پیشنهادی و حداقل سخت‌افزار
  final String category; // دسته‌بندی مدل: فوق‌سبک، استاندارد، قدرتمند، استدلال سنگین

  const AiModelInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeInBytes,
    required this.requiredRam,
    required this.supportedDevices,
    required this.category,
  });

  String get sizeInMb {
    if (sizeInBytes >= 1024 * 1024 * 1024) {
      return "${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} گیگابایت";
    }
    return "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(0)} مگابایت";
  }
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

  /// فهرست جامع مدل‌های هوش مصنوعی کوانتیزه (GGUF Q4_K_M) به همراه مشخصات دیوایس
  static const List<AiModelInfo> catalog = [
    AiModelInfo(
      id: "qwen_05b",
      title: "جارویس لایت (Qwen 2.5 0.5B)",
      description: "فوق‌العاده سریع و کم‌مصرف. پاسخگویی آنی برای کارهای روزمره، چت و پیامک بدون داغ کردن گوشی.",
      fileName: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
      sizeInBytes: 397000000,
      requiredRam: "۲ تا ۳ گیگابایت",
      supportedDevices: "تمام گوشی‌های اقتصادی (Galaxy A04/A14، ردمی 9/10/12C و قدیمی‌تر)",
      category: "فوق‌سبک و اقتصادی",
    ),
    AiModelInfo(
      id: "llama_1b",
      title: "متا لاما لایت (Llama 3.2 1B)",
      description: "مدل مدرن متای آمریکا با درک منطقی بالا، خلاصه کردن متن‌های انگلیسی و نگارش سریع فارسی.",
      fileName: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      downloadUrl: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      sizeInBytes: 807694464,
      requiredRam: "۳ تا ۴ گیگابایت",
      supportedDevices: "گوشی‌های میان‌رده پایه (Galaxy A24/A34، ردمی نوت ۱۱/۱۲، پوکو M5)",
      category: "سبک و سریع",
    ),
    AiModelInfo(
      id: "qwen_15b",
      title: "جارویس پرو (Qwen 2.5 1.5B)",
      description: "تعادل طلایی سرعت و هوش؛ تسلط عالی بر ادبیات فارسی، انشا، بازنویسی، ترجمه و مقاله‌نویسی.",
      fileName: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
      sizeInBytes: 986000000,
      requiredRam: "۴ گیگابایت به بالا",
      supportedDevices: "میان‌رده‌های محبوب (Galaxy A54/A55، ردمی نوت ۱۲ پرو/۱۳، پوکو X5)",
      category: "استاندارد (پیشنهادی)",
    ),
    AiModelInfo(
      id: "deepseek_15b",
      title: "دیپ‌سیک استدلال (DeepSeek-R1 1.5B)",
      description: "دارای زنجیره تفکر عمیق (<think>)؛ حل مسائل ریاضی، منطق، کدنویسی پایتون و پاسخ‌های گام‌به‌گام.",
      fileName: "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      downloadUrl: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      sizeInBytes: 1120000000,
      requiredRam: "۴ تا ۶ گیگابایت",
      supportedDevices: "میان‌رده‌ها و بالارده‌ها (Galaxy A54/S21 FE، پوکو F4/X6، شیائومی 12T)",
      category: "استدلال و برنامه‌نویسی",
    ),
    AiModelInfo(
      id: "gemma_2b",
      title: "گوگل گما ۲ (Gemma 2 2B Instruct)",
      description: "شاهکار پردازش زبانی گوگل؛ معماری پیشرفته با کیفیت در حد مدل‌های بزرگ‌تر در درک مفاهیم علمی.",
      fileName: "gemma-2-2b-it-Q4_K_M.gguf",
      downloadUrl: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
      sizeInBytes: 1708582752,
      requiredRam: "۶ گیگابایت",
      supportedDevices: "میان‌رده‌های قوی (Galaxy A55، پوکو X6 Pro، ردمی نوت 13 پرو پلاس)",
      category: "گوگل و مفاهیم علمی",
    ),
    AiModelInfo(
      id: "qwen_3b",
      title: "جارویس مستر (Qwen 2.5 3B)",
      description: "بسیار قدرتمند و دقیق با غنای لغوی بالا؛ مناسب برای کارهای تخصصی، دانشگاهی و نگارش حرفه‌ای.",
      fileName: "qwen2.5-3b-instruct-q4_k_m.gguf",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
      sizeInBytes: 2104932768,
      requiredRam: "۶ تا ۸ گیگابایت",
      supportedDevices: "قاتل پرچمدار و پرچمداران (Galaxy S22/S23 FE، شیائومی 13T، پوکو F5/F6)",
      category: "فوق‌العاده قدرتمند",
    ),
    AiModelInfo(
      id: "deepseek_7b",
      title: "دیپ‌سیک اولترا (DeepSeek-R1 7B)",
      description: "نهایت قدرت هوش مصنوعی تفکر و استدلال روی موبایل. مناسب برای سنگین‌ترین مسائل علمی و برنامه‌نویسی.",
      fileName: "DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf",
      downloadUrl: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf",
      sizeInBytes: 4683073504,
      requiredRam: "۸ تا ۱۲ گیگابایت به بالا",
      supportedDevices: "پرچمداران قدرتمند (Galaxy S23/S24/S25 Ultra، شیائومی 13/14 Pro، پوکو F6 Pro)",
      category: "نهایت قدرت (پرچمدار)",
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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/ai_engine_service.dart';
import 'services/model_manager_service.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // گرفتن تمام خطاهای فلاتر و رندر صفحه خطا در صورت کرش
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error: ${details.exception}");
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⚠️ خطای اجرای رابط کاربری",
                    style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    details.exceptionAsString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    details.stack.toString(),
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  final aiEngine = AiEngineService();
  final modelManager = ModelManagerService();

  runApp(
    JarvisPlusApp(
      aiEngine: aiEngine,
      modelManager: modelManager,
    ),
  );
}

class JarvisPlusApp extends StatelessWidget {
  final AiEngineService aiEngine;
  final ModelManagerService modelManager;

  const JarvisPlusApp({
    super.key,
    required this.aiEngine,
    required this.modelManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جارویس پلاس',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF2563EB),
        fontFamily: 'Vazirmatn', // یا فونت پیش‌فرض سیستم اندروید
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: ChatScreen(
        aiEngine: aiEngine,
        modelManager: modelManager,
      ),
    );
  }
}

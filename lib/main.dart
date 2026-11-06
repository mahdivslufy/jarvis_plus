import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/ai_engine_service.dart';
import 'services/model_manager_service.dart';
import 'services/myket_billing_service.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final aiEngine = AiEngineService();
  final modelManager = ModelManagerService();
  final billingService = MyketBillingService();

  await billingService.initBilling();

  runApp(
    JarvisPlusApp(
      aiEngine: aiEngine,
      modelManager: modelManager,
      billingService: billingService,
    ),
  );
}

class JarvisPlusApp extends StatelessWidget {
  final AiEngineService aiEngine;
  final ModelManagerService modelManager;
  final MyketBillingService billingService;

  const JarvisPlusApp({
    super.key,
    required this.aiEngine,
    required this.modelManager,
    required this.billingService,
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
        billingService: billingService,
      ),
    );
  }
}

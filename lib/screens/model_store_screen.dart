import 'package:flutter/material.dart';
import '../services/ai_engine_service.dart';
import '../services/model_manager_service.dart';
import '../services/myket_billing_service.dart';

class ModelStoreScreen extends StatefulWidget {
  final ModelManagerService modelManager;
  final AiEngineService aiEngine;
  final MyketBillingService billingService;

  const ModelStoreScreen({
    super.key,
    required this.modelManager,
    required this.aiEngine,
    required this.billingService,
  });

  @override
  State<ModelStoreScreen> createState() => _ModelStoreScreenState();
}

class _ModelStoreScreenState extends State<ModelStoreScreen> {
  final Map<String, bool> _downloadedMap = {};
  final Map<String, double> _progressMap = {};
  final Map<String, String> _statusMap = {};
  String? _downloadingModelId;
  String? _activeModelPath;

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
    _activeModelPath = widget.aiEngine.currentModelPath;
  }

  Future<void> _checkDownloadedModels() async {
    for (final model in ModelManagerService.catalog) {
      final downloaded = await widget.modelManager.isModelDownloaded(model);
      setState(() {
        _downloadedMap[model.id] = downloaded;
      });
    }
  }

  void _startDownload(AiModelInfo model) async {
    if (model.isPremium && !widget.billingService.isPro) {
      _showUpgradeDialog(model);
      return;
    }

    setState(() {
      _downloadingModelId = model.id;
      _progressMap[model.id] = 0.0;
      _statusMap[model.id] = "در حال اتصال به مخزن...";
    });

    final success = await widget.modelManager.downloadModel(
      model,
      onProgress: (progress, status) {
        setState(() {
          _progressMap[model.id] = progress;
          _statusMap[model.id] = status;
        });
      },
    );

    setState(() {
      _downloadingModelId = null;
      _downloadedMap[model.id] = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("مدل ${model.title} با موفقیت دانلود شد و آماده استفاده است."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectModel(AiModelInfo model) async {
    final localPath = await widget.modelManager.getLocalModelPath(model);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("در حال بارگذاری مدل در رم گوشی..."),
              ],
            ),
          ),
        ),
      ),
    );

    final loaded = await widget.aiEngine.loadModel(localPath);
    Navigator.of(context).pop();

    if (loaded) {
      setState(() {
        _activeModelPath = localPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("مدل ${model.title} با موفقیت در حافظه فعال شد."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خطا در بارگذاری مدل. ممکن است حافظه رم گوشی پر باشد."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpgradeDialog(AiModelInfo model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      "ارتقا به نسخه جارویس طلایی",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "برای دسترسی به مدل پیشرفته «${model.title}»، حل مسائل تحلیلی و امکان چت نامحدود با بالاترین دقت، اشتراک ویژه مایکت را فعال نمایید.",
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text("اشتراک ماهانه جارویس پرو", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("دسترسی به تمام مدل‌های ۱.۵ میلیاردی و تحلیلی", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.billingService.launchPurchase(MyketBillingService.skuProMonthly);
                      setState(() {});
                    },
                    child: const Text("۴۹٬۰۰۰ تومان", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text("اشتراک مادام‌العمر طلایی", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("یک‌بار پرداخت، دسترسی همیشگی بدون انقضا", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.billingService.launchPurchase(MyketBillingService.skuProLifetime);
                      setState(() {});
                    },
                    child: const Text("۲۸۹٬۰۰۰ تومان", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("مخزن مدل‌های آفلاین", style: TextStyle(color: Colors.white, fontSize: 17)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ModelManagerService.catalog.length,
          itemBuilder: (context, index) {
            final model = ModelManagerService.catalog[index];
            final isDownloaded = _downloadedMap[model.id] ?? false;
            final isDownloading = _downloadingModelId == model.id;
            final progress = _progressMap[model.id] ?? 0.0;
            final status = _statusMap[model.id] ?? "";
            final isCurrentlyActive = _activeModelPath != null && _activeModelPath!.endsWith(model.fileName);

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isCurrentlyActive ? const Color(0xFF10B981) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (model.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber, width: 0.8),
                            ),
                            child: const Text(
                              "نسخه پرو",
                              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green, width: 0.8),
                            ),
                            child: const Text(
                              "رایگان",
                              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      model.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.sd_storage, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text("حجم: ${model.sizeInMb}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(width: 16),
                        const Icon(Icons.memory, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text("حداقل رم: ${model.requiredRam}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(status, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isDownloaded) ...[
                          if (isCurrentlyActive)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                              icon: const Icon(Icons.check, size: 16, color: Colors.white),
                              label: const Text("مدل فعال در حال حاضر", style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: null,
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                              icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                              label: const Text("فعال‌سازی در رم", style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () => _selectModel(model),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: "حذف مدل و آزادسازی حافظه",
                            onPressed: () async {
                              await widget.modelManager.deleteModel(model);
                              await _checkDownloadedModels();
                            },
                          ),
                        ] else ...[
                          if (isDownloading)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              icon: const Icon(Icons.pause, size: 16),
                              label: const Text("توقف دانلود", style: TextStyle(fontSize: 12)),
                              onPressed: () => widget.modelManager.pauseDownload(),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: model.isPremium && !widget.billingService.isPro ? Colors.amber.shade700 : const Color(0xFF2563EB),
                              ),
                              icon: Icon(
                                model.isPremium && !widget.billingService.isPro ? Icons.lock : Icons.download,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                model.isPremium && !widget.billingService.isPro ? "دریافت نسخه پرو" : "دانلود رایگان (${model.sizeInMb})",
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              onPressed: () => _startDownload(model),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

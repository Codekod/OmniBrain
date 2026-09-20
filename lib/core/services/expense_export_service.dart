import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';

class ExpenseExportService {
  static Future<void> exportToExcel({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> scanData,
  }) async {
    HapticFeedback.mediumImpact();

    // 1. PRO Gate Check: Exporting formatted Excel reports is a PRO feature
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      context.push(RoutePaths.paywall);
      return;
    }

    try {
      final merchant = (scanData['merchant'] ?? 'Masraf').toString().trim();
      final date = (scanData['date'] ?? DateFormat('dd.MM.yyyy').format(DateTime.now())).toString();
      final total = (scanData['total'] ?? '0').toString();
      final items = (scanData['items'] as List<dynamic>?) ?? [];

      // Generate Excel-compatible CSV with UTF-8 BOM
      final buffer = StringBuffer();
      buffer.write('\uFEFF'); // UTF-8 BOM for Excel / Numbers

      buffer.writeln('OMNIBRAIN AI - MUHASEBE MASRAF VE FIS RAPORU');
      buffer.writeln('Düzenleme Tarihi;${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('İşletme / Satıcı;$merchant');
      buffer.writeln('Fiş / Belge Tarihi;$date');
      buffer.writeln('Toplam Tutar;$total');
      buffer.writeln('');
      buffer.writeln('Sıra No;Harcama Kalemi;Kategori;KDV (%);Tutar (TL)');

      if (items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          final item = items[i].toString().replaceAll(';', ',');
          buffer.writeln('${i + 1};"$item";Genel Masraf;%20;-');
        }
      } else {
        buffer.writeln('1;"$merchant Harcaması";Masraf;%20;$total');
      }

      buffer.writeln('');
      buffer.writeln(';GENEL TOPLAM;;;$total');

      final tempDir = await getTemporaryDirectory();
      final safeName = merchant.replaceAll(RegExp(r'[^\w\s]+'), '_').replaceAll(' ', '_');
      final fileName = 'Masraf_Raporu_${safeName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      // Open iOS Share Sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'OmniBrain Masraf Raporu - $merchant',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor dışa aktarılamadı: $e')),
        );
      }
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/domain/entities/note.dart';

class MeetingExportService {
  /// Exports note or AI meeting transcript into a high-resolution, executive PDF report.
  static Future<void> exportToPdf({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String content,
    String category = 'Toplantı',
    DateTime? date,
    DateTime? eventDate,
    List<String> imagePaths = const [],
  }) async {
    HapticFeedback.mediumImpact();

    // 1. PRO Gate Check
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      context.push(RoutePaths.paywall);
      return;
    }

    try {
      final reportDate = date ?? DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(reportDate);
      final eventDateStr = eventDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(eventDate) : null;
      final pdfDoc = pw.Document(
        title: title,
        author: 'OmniBrain AI Executive Suite',
      );

      // Clean markdown symbols for raw display
      final lines = content.split('\n');

      final List<pw.MemoryImage> pdfImages = [];
      for (final p in imagePaths) {
        final f = File(p);
        if (f.existsSync()) {
          try {
            final bytes = f.readAsBytesSync();
            pdfImages.add(pw.MemoryImage(bytes));
          } catch (_) {}
        }
      }

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OMNIBRAIN AI',
                        style: pw.TextStyle(
                          color: PdfColors.indigo900,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        'Executive Meeting & Intelligence Report',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.indigo200),
                    ),
                    child: pw.Text(
                      'PRO BELGE',
                      style: pw.TextStyle(
                        color: PdfColors.indigo900,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Gizli & Kurumsal • OmniBrain AI ile oluşturuldu',
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                  ),
                  pw.Text(
                    'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // Title & Metadata Card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title.isNotEmpty ? title : 'Toplantı ve Görüşme Tutanağı',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (eventDateStr != null) ...[
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                'Toplantı / Ders: ',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                              ),
                              pw.Text(
                                eventDateStr,
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                              ),
                            ],
                          ),
                        ],
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'Kayıt Tarihi: ',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                            ),
                            pw.Text(
                              dateStr,
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'Kategori: ',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                            ),
                            pw.Text(
                              category,
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Formatted Content Lines
              ...lines.map((line) {
                final trimmed = line.trim();
                if (trimmed.isEmpty) {
                  return pw.SizedBox(height: 8);
                }

                // Header 1 / Title (# ...)
                if (trimmed.startsWith('# ')) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
                    child: pw.Text(
                      trimmed.substring(2),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                  );
                }

                // Header 2 / 3 (## ... or ### ...)
                if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
                  final text = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                    child: pw.Text(
                      text,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  );
                }

                // Checkbox / Action Item (- [ ] or - [x])
                if (trimmed.startsWith('- [ ]') || trimmed.startsWith('- [x]')) {
                  final isDone = trimmed.startsWith('- [x]');
                  final itemText = trimmed.substring(5).trim();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 12,
                          height: 12,
                          margin: const pw.EdgeInsets.only(top: 2, right: 8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.indigo700, width: 1.5),
                            borderRadius: pw.BorderRadius.circular(3),
                            color: isDone ? PdfColors.indigo700 : null,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            itemText,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: PdfColors.grey900,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Bullet point (- or * or •)
                if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
                  final itemText = trimmed.substring(2).trim();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          margin: const pw.EdgeInsets.only(top: 5, right: 8),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.indigo800,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            itemText,
                            style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey900),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Regular Paragraph
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    trimmed,
                    style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey800, lineSpacing: 2),
                  ),
                );
              }),

              // Ekli Fotoğraflar / Belgeler
              if (pdfImages.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1)),
                  ),
                  child: pw.Text(
                    'Ekli Belgeler ve Görseller (${pdfImages.length})',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: pdfImages.map((img) {
                    return pw.Container(
                      width: 150,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(img, fit: pw.BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ];
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final safeName = (title.isNotEmpty ? title : 'Toplanti_Notu')
          .replaceAll(RegExp(r'[^\w\s]+'), '_')
          .replaceAll(' ', '_');
      final fileName = 'OmniBrain_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(reportDate)}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdfDoc.save());

      // Open iOS Share Sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'OmniBrain Toplantı Raporu - $title',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturulamadı: $e')),
        );
      }
    }
  }

  /// Exports note into a formatted, styled Microsoft Word (.doc) document.
  static Future<void> exportToWord({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String content,
    String category = 'Toplantı',
    DateTime? date,
    DateTime? eventDate,
    List<String> imagePaths = const [],
  }) async {
    HapticFeedback.mediumImpact();

    // 1. PRO Gate Check
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      context.push(RoutePaths.paywall);
      return;
    }

    try {
      final reportDate = date ?? DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(reportDate);
      final eventDateStr = eventDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(eventDate) : null;
      final cleanTitle = title.isNotEmpty ? title : 'Toplantı ve Görüşme Tutanağı';

      // Convert content to HTML for MS Word
      final lines = content.split('\n');
      final bodyBuffer = StringBuffer();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          bodyBuffer.writeln('<p>&nbsp;</p>');
          continue;
        }

        if (trimmed.startsWith('# ')) {
          bodyBuffer.writeln('<h1 style="color: #1e3a8a; border-bottom: 2px solid #3b82f6; padding-bottom: 6px; margin-top: 18px;">${_escape(trimmed.substring(2))}</h1>');
        } else if (trimmed.startsWith('## ')) {
          bodyBuffer.writeln('<h2 style="color: #1e40af; margin-top: 14px; margin-bottom: 6px;">${_escape(trimmed.substring(3))}</h2>');
        } else if (trimmed.startsWith('### ')) {
          bodyBuffer.writeln('<h3 style="color: #374151; margin-top: 10px; margin-bottom: 4px;">${_escape(trimmed.substring(4))}</h3>');
        } else if (trimmed.startsWith('- [ ]')) {
          bodyBuffer.writeln('<div style="margin: 4px 0; font-size: 11pt;"><input type="checkbox" disabled /> <span>${_escape(trimmed.substring(5).trim())}</span></div>');
        } else if (trimmed.startsWith('- [x]')) {
          bodyBuffer.writeln('<div style="margin: 4px 0; font-size: 11pt;"><input type="checkbox" checked disabled /> <span style="text-decoration: line-through; color: #6b7280;">${_escape(trimmed.substring(5).trim())}</span></div>');
        } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
          bodyBuffer.writeln('<li style="margin: 4px 0; font-size: 11pt; color: #1f2937;">${_escape(trimmed.substring(2).trim())}</li>');
        } else {
          bodyBuffer.writeln('<p style="font-size: 11pt; line-height: 1.6; color: #374151; margin: 4px 0;">${_escape(trimmed)}</p>');
        }
      }

      if (imagePaths.isNotEmpty) {
        bodyBuffer.writeln('<div style="margin-top: 24pt; padding: 10pt; background-color: #f8fafc; border: 1pt solid #e2e8f0; border-radius: 6pt;">');
        bodyBuffer.writeln('<h3 style="color: #1e3a8a; margin: 0 0 8pt 0;">📎 Ekli Görseller & Belgeler (${imagePaths.length})</h3>');
        bodyBuffer.writeln('<p style="font-size: 9.5pt; color: #64748b; margin: 0;">Bu nota ${imagePaths.length} adet görsel/belge eklenmiştir. Yüksek çözünürlüklü fotoğraflar PDF raporunda tam sayfa olarak yer almaktadır.</p>');
        bodyBuffer.writeln('</div>');
      }

      // Word HTML template
      final wordHtml = '''
<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
<head>
<meta charset='utf-8'>
<title>$cleanTitle</title>
<!--[if gte mso 9]>
<xml>
 <w:WordDocument>
  <w:View>Print</w:View>
  <w:Zoom>100</w:Zoom>
  <w:DoNotOptimizeForBrowser/>
 </w:WordDocument>
</xml>
<![endif]-->
<style>
  body {
    font-family: 'Calibri', 'Segoe UI', Arial, sans-serif;
    margin: 36pt;
    color: #1f2937;
  }
  .header-table {
    width: 100%;
    border-bottom: 2pt solid #1e3a8a;
    padding-bottom: 12pt;
    margin-bottom: 20pt;
  }
  .meta-box {
    background-color: #f3f4f6;
    border-left: 4pt solid #3b82f6;
    padding: 12pt;
    margin-bottom: 20pt;
    font-size: 10pt;
  }
  .footer-notice {
    margin-top: 30pt;
    padding-top: 10pt;
    border-top: 1pt solid #e5e7eb;
    font-size: 8.5pt;
    color: #9ca3af;
    text-align: center;
  }
</style>
</head>
<body>
  <table class="header-table">
    <tr>
      <td>
        <h2 style="margin:0; color: #1e3a8a; letter-spacing: 1px;">OMNIBRAIN AI</h2>
        <span style="font-size: 9pt; color: #6b7280;">Kurumsal Toplantı ve Eylem Planı Çıktısı</span>
      </td>
      <td align="right">
        <span style="background-color: #dbeafe; color: #1e40af; font-size: 8.5pt; font-weight: bold; padding: 4pt 8pt; border-radius: 4pt;">PRO RAPOR</span>
      </td>
    </tr>
  </table>

  <div class="meta-box">
    <strong>Başlık:</strong> $cleanTitle<br/>
    ${eventDateStr != null ? '<strong>Toplantı / Ders Tarihi:</strong> $eventDateStr<br/>' : ''}
    <strong>Kayıt Tarihi:</strong> $dateStr &nbsp;|&nbsp; <strong>Kategori:</strong> $category &nbsp;|&nbsp; <strong>Oluşturan:</strong> OmniBrain AI Suite
  </div>

  ${bodyBuffer.toString()}

  <div class="footer-notice">
    Bu belge OmniBrain AI Asistanı tarafından otomatik olarak derlenmiştir. Gizlidir ve izinsiz paylaşılamaz.
  </div>
</body>
</html>
''';

      final tempDir = await getTemporaryDirectory();
      final safeName = cleanTitle.replaceAll(RegExp(r'[^\w\s]+'), '_').replaceAll(' ', '_');
      final fileName = 'OmniBrain_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(reportDate)}.doc';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(wordHtml, flush: true);

      // Open iOS Share Sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'OmniBrain Word Belgesi - $cleanTitle',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word belgesi oluşturulamadı: $e')),
        );
      }
    }
  }

  /// Shows the unified executive share sheet with AirDrop, WhatsApp, Mail, PDF, and Word.
  static Future<void> showComprehensiveShareSheet({
    required BuildContext context,
    required WidgetRef ref,
    required Note note,
  }) async {
    HapticFeedback.mediumImpact();
    final title = note.displayTitle;
    final content = note.displayBody;
    final dateStr = note.eventDate != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(note.eventDate!)
        : DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.neonPurple, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📅 $dateStr • ${note.category}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'DIŞA AKTARMA VE PAYLAŞIM SEÇENEKLERİ',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 12),

            // Option 1: PDF Export (AirDrop, WhatsApp, Mail, Print)
            _buildShareTile(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFE11D48),
              title: 'PDF Raporu Olarak Paylaş',
              subtitle: 'Kurumsal antetli, fotoğraflı • AirDrop & WhatsApp & Mail',
              onTap: () {
                Navigator.pop(ctx);
                exportToPdf(
                  context: context,
                  ref: ref,
                  title: title,
                  content: content,
                  category: note.category,
                  date: note.createdAt,
                  eventDate: note.eventDate,
                  imagePaths: note.imagePaths,
                );
              },
            ),

            const Divider(color: Colors.white10, height: 1),

            // Option 2: Word .doc
            _buildShareTile(
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Word (.doc) Belgesi Olarak Paylaş',
              subtitle: 'Düzenlenebilir Microsoft Word & Apple Pages dokümanı',
              onTap: () {
                Navigator.pop(ctx);
                exportToWord(
                  context: context,
                  ref: ref,
                  title: title,
                  content: content,
                  category: note.category,
                  date: note.createdAt,
                  eventDate: note.eventDate,
                  imagePaths: note.imagePaths,
                );
              },
            ),

            const Divider(color: Colors.white10, height: 1),

            // Option 3: WhatsApp & Messages (Native text share)
            _buildShareTile(
              icon: Icons.chat_bubble_rounded,
              iconColor: const Color(0xFF22C55E),
              title: 'WhatsApp & Mesajlar ile Paylaş',
              subtitle: 'Metin olarak anında kişilere veya gruplara ilet',
              onTap: () async {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                final buffer = StringBuffer();
                buffer.writeln('📌 *$title*');
                if (note.eventDate != null) {
                  buffer.writeln('📅 *Tarih:* ${DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(note.eventDate!)}');
                }
                buffer.writeln('🏷️ *Kategori:* ${note.category}');
                buffer.writeln('');
                buffer.writeln(content);
                buffer.writeln('');
                buffer.writeln('— OmniBrain AI ile paylaşıldı');

                await SharePlus.instance.share(
                  ShareParams(
                    text: buffer.toString(),
                    subject: title,
                  ),
                );
              },
            ),

            const Divider(color: Colors.white10, height: 1),

            // Option 4: Email Share
            _buildShareTile(
              icon: Icons.email_rounded,
              iconColor: AppColors.iceBlue,
              title: 'E-Posta Olarak Gönder',
              subtitle: 'Konu ve not içeriği otomatik hazır mail taslağı',
              onTap: () async {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                final buffer = StringBuffer();
                if (note.eventDate != null) {
                  buffer.writeln('Toplantı/Ders Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(note.eventDate!)}');
                  buffer.writeln('Kategori: ${note.category}\n');
                }
                buffer.writeln(content);
                buffer.writeln('\n---\nOmniBrain AI Akıllı Asistan');

                await SharePlus.instance.share(
                  ShareParams(
                    text: buffer.toString(),
                    subject: 'OmniBrain Notu: $title',
                  ),
                );
              },
            ),

            const Divider(color: Colors.white10, height: 1),

            // Option 5: Copy text
            _buildShareTile(
              icon: Icons.copy_rounded,
              iconColor: AppColors.amber,
              title: 'Metni Panoya Kopyala',
              subtitle: 'Tüm not içeriğini panoya kopyala',
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: '$title\n\n$content'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Not panoya kopyalandı!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildShareTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

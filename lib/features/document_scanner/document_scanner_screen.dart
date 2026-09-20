import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/omnibrain_camera_view.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';

class DocumentScannerScreen extends ConsumerStatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  ConsumerState<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends ConsumerState<DocumentScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCameraOpen = false;
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prompt camera open immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  void _openCamera() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCameraOpen = true;
      _errorMessage = null;
    });
  }

  void _closeCamera() {
    setState(() => _isCameraOpen = false);
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        _processScannedImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galeriden görsel seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _processScannedImage(String imagePath) async {
    _closeCamera();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scanResult = null;
    });

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final visionResult = await aiRepo.processImageCalculation(imagePath);
      final cleanResult = visionResult.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        final parsed = jsonDecode(cleanResult);
        if (parsed is Map<String, dynamic>) {
          setState(() {
            _scanResult = parsed;
            _isLoading = false;
          });
          HapticFeedback.mediumImpact();
        } else {
          setState(() {
            _errorMessage = cleanResult;
            _isLoading = false;
          });
        }
      } catch (_) {
        setState(() {
          _errorMessage = cleanResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Belge taranırken bir hata oluştu: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToNotes(Map<String, dynamic> data) async {
    HapticFeedback.mediumImpact();
    final merchant = data['merchant'] ?? 'Belge / Fiş';
    final total = data['total'] ?? '';
    final date = data['date'] ?? '';
    final items = (data['items'] as List<dynamic>?)?.map((e) => "- $e").join('\n') ?? '';

    final noteContent = "🧾 $merchant\n📅 Tarih: $date\n💰 Toplam: $total\n\nDetaylar:\n$items";

    await ref.read(notesProvider.notifier).addNote(
      noteContent,
      category: 'Finans',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$merchant" harcaması Finans notlarına kaydedildi!'),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraOpen) {
      return OmniBrainCameraView(
        onImageCaptured: _processScannedImage,
        onCancel: _closeCamera,
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Belge & Fiş Tarayıcı',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: AppColors.iceBlue),
              tooltip: 'Galeriden Seç',
              onPressed: _pickFromGallery,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.iceBlue),
              tooltip: 'Yeni Çekim',
              onPressed: _openCamera,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 3),
                        const SizedBox(height: 20),
                        Text(
                          'Gemini Multimodal Vision Belgeyi İnceliyor...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.iceBlue),
                        ),
                      ],
                    ),
                  )
                : _scanResult != null
                    ? _buildResultView(_scanResult!)
                    : _buildEmptyOrErrorView(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iceBlue.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.document_scanner_rounded, size: 56, color: AppColors.iceBlue),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage ?? "Taramaya Başlayın",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Market fişi, fatura veya sözleşme tara;\nkalemleri, KDV'yi ve tutarları saniyeler içinde analiz edelim.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _openCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPurple.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Kamera ile Tara',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_rounded, color: AppColors.iceBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Galeriden Seç',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(Map<String, dynamic> data) {
    final merchant = data['merchant']?.toString() ?? 'Bilinmeyen İşletme';
    final date = data['date']?.toString() ?? 'Tarih belirtilmemiş';
    final total = data['total']?.toString() ?? '0.00 TL';
    final tax = data['tax']?.toString() ?? '-';
    final items = (data['items'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.iceBlue.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'AI Onaylı',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.softGreen),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 28),
                if (items.isNotEmpty) ...[
                  Text(
                    'Kalemler & Harcamalar',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.iceBlue)),
                            Expanded(
                              child: Text(
                                it.toString(),
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(color: Colors.white12, height: 28),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hesaplanan KDV', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    Text(tax, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOPLAM', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      total,
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.iceBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
            label: const Text(
              'Notlarıma Kaydet (Finans)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            onPressed: () => _saveToNotes(data),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            label: const Text('Yeni Belge Tara', style: TextStyle(color: Colors.white70)),
            onPressed: _openCamera,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

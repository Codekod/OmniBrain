/// Centralised string constants for OmniBrain AI.
///
/// All user-facing text lives here so it can be swapped for l10n later.
abstract final class AppStrings {
  // ─── Branding ─────────────────────────────────────────────────────
  static const String appName = 'OmniBrain AI';
  static const String slogan = 'Yapay Zekâ ile Hayatı Kolaylaştır';
  static const String tagline = 'Her şey tek bir yerde.';

  // ─── Bottom Navigation Tabs ───────────────────────────────────────
  static const String tabDashboard = 'Ana Sayfa';
  static const String tabTools = 'Araçlar';
  static const String tabAiCommand = 'AI Komut';
  static const String tabNotes = 'Notlar';
  static const String tabProfile = 'Profil';

  // ─── Tool Names ───────────────────────────────────────────────────
  static const String toolCalculate = 'Hesapla';
  static const String toolScan = 'Tara';
  static const String toolPomodoro = 'Zamanla';
  static const String toolConvert = 'Çevir';
  static const String toolNote = 'Not Al';
  static const String toolReminder = 'Hatırlat';

  // ─── Tool Descriptions ────────────────────────────────────────────
  static const String toolCalculateDesc = 'Gelişmiş hesap makinesi';
  static const String toolScanDesc = 'OCR ile metin tara';
  static const String toolPomodoroDesc = 'Pomodoro zamanlayıcı';
  static const String toolConvertDesc = 'Birim & para çevirici';
  static const String toolNoteDesc = 'Akıllı not defteri';
  static const String toolReminderDesc = 'Hatırlatıcı kur';

  // ─── AI Command ───────────────────────────────────────────────────
  static const String aiCommandPlaceholder =
      'Ne yapmamı istersin? Bir komut yaz...';
  static const String aiCommandHint = 'Örn: "100 doları TL\'ye çevir"';
  static const String aiCommandTitle = 'AI Komut Merkezi';
  static const String aiThinking = 'Düşünüyorum...';
  static const String aiError = 'Bir hata oluştu. Tekrar deneyin.';

  // ─── Onboarding ───────────────────────────────────────────────────
  static const String onboardingTitle1 = 'OmniBrain AI\'ye Hoş Geldin';
  static const String onboardingBody1 =
      'Tüm günlük araçların yapay zekâ ile güçlendirilmiş halde.';
  static const String onboardingTitle2 = 'Akıllı Araçlar';
  static const String onboardingBody2 =
      'Hesapla, tara, çevir, zamanlayıcı ve daha fazlası.';
  static const String onboardingTitle3 = 'Tek Komutla Çalıştır';
  static const String onboardingBody3 =
      'AI komut satırına yaz, gerisini OmniBrain halleder.';
  static const String onboardingCta = 'Başlayalım';
  static const String onboardingSkip = 'Atla';

  // ─── Dashboard ────────────────────────────────────────────────────
  static const String dashboardGreeting = 'Merhaba';
  static const String dashboardQuickActions = 'Hızlı İşlemler';
  static const String dashboardRecent = 'Son Kullanılanlar';
  static const String dashboardFavorites = 'Favoriler';

  // ─── Notes ────────────────────────────────────────────────────────
  static const String notesTitle = 'Notlarım';
  static const String notesEmpty = 'Henüz not eklenmemiş.';
  static const String notesNewNote = 'Yeni Not';
  static const String notesSearch = 'Not ara...';

  // ─── Profile ──────────────────────────────────────────────────────
  static const String profileTitle = 'Profil';
  static const String profileSettings = 'Ayarlar';
  static const String profileAbout = 'Hakkında';
  static const String profileVersion = 'Sürüm';
  static const String profileLogout = 'Çıkış Yap';

  // ─── General ──────────────────────────────────────────────────────
  static const String cancel = 'İptal';
  static const String confirm = 'Onayla';
  static const String delete = 'Sil';
  static const String save = 'Kaydet';
  static const String edit = 'Düzenle';
  static const String close = 'Kapat';
  static const String retry = 'Tekrar Dene';
  static const String loading = 'Yükleniyor...';
  static const String noConnection = 'İnternet bağlantısı yok.';
  static const String unknownError = 'Bilinmeyen bir hata oluştu.';
}

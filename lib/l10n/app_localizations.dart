import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'OmniBrain AI'**
  String get appName;

  /// No description provided for @slogan.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zekâ ile Hayatı Kolaylaştır'**
  String get slogan;

  /// No description provided for @tagline.
  ///
  /// In tr, this message translates to:
  /// **'Her şey tek bir yerde.'**
  String get tagline;

  /// No description provided for @tabDashboard.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get tabDashboard;

  /// No description provided for @tabTools.
  ///
  /// In tr, this message translates to:
  /// **'Araçlar'**
  String get tabTools;

  /// No description provided for @tabAiCommand.
  ///
  /// In tr, this message translates to:
  /// **'AI Komut'**
  String get tabAiCommand;

  /// No description provided for @tabNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get tabNotes;

  /// No description provided for @tabProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @toolCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla'**
  String get toolCalculate;

  /// No description provided for @toolScan.
  ///
  /// In tr, this message translates to:
  /// **'Tara'**
  String get toolScan;

  /// No description provided for @toolPomodoro.
  ///
  /// In tr, this message translates to:
  /// **'Zamanla'**
  String get toolPomodoro;

  /// No description provided for @toolConvert.
  ///
  /// In tr, this message translates to:
  /// **'Çevir'**
  String get toolConvert;

  /// No description provided for @toolNote.
  ///
  /// In tr, this message translates to:
  /// **'Not Al'**
  String get toolNote;

  /// No description provided for @toolReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlat'**
  String get toolReminder;

  /// No description provided for @toolCalculateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş hesap makinesi'**
  String get toolCalculateDesc;

  /// No description provided for @toolScanDesc.
  ///
  /// In tr, this message translates to:
  /// **'OCR ile metin tara'**
  String get toolScanDesc;

  /// No description provided for @toolPomodoroDesc.
  ///
  /// In tr, this message translates to:
  /// **'Pomodoro zamanlayıcı'**
  String get toolPomodoroDesc;

  /// No description provided for @toolConvertDesc.
  ///
  /// In tr, this message translates to:
  /// **'Birim & para çevirici'**
  String get toolConvertDesc;

  /// No description provided for @toolNoteDesc.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı not defteri'**
  String get toolNoteDesc;

  /// No description provided for @toolReminderDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı kur'**
  String get toolReminderDesc;

  /// No description provided for @aiCommandPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Ne yapmamı istersin? Bir komut yaz...'**
  String get aiCommandPlaceholder;

  /// No description provided for @aiCommandHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: \"100 doları TL\'ye çevir\"'**
  String get aiCommandHint;

  /// No description provided for @aiCommandTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI Komut Merkezi'**
  String get aiCommandTitle;

  /// No description provided for @aiThinking.
  ///
  /// In tr, this message translates to:
  /// **'Düşünüyorum...'**
  String get aiThinking;

  /// No description provided for @aiError.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Tekrar deneyin.'**
  String get aiError;

  /// No description provided for @onboardingTitle1.
  ///
  /// In tr, this message translates to:
  /// **'OmniBrain AI\'ye Hoş Geldin'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In tr, this message translates to:
  /// **'Tüm günlük araçların yapay zekâ ile güçlendirilmiş halde.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Araçlar'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla, tara, çevir, zamanlayıcı ve daha fazlası.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In tr, this message translates to:
  /// **'Tek Komutla Çalıştır'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In tr, this message translates to:
  /// **'AI komut satırına yaz, gerisini OmniBrain halleder.'**
  String get onboardingBody3;

  /// No description provided for @onboardingCta.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onboardingCta;

  /// No description provided for @onboardingSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get onboardingNext;

  /// No description provided for @onboardingPurposeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senin İçin Özelleştirelim'**
  String get onboardingPurposeTitle;

  /// No description provided for @onboardingPurposeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'OmniBrain\'i en çok hangi amaçla kullanacaksın?'**
  String get onboardingPurposeSubtitle;

  /// No description provided for @onboardingPurposeWork.
  ///
  /// In tr, this message translates to:
  /// **'İş & Verimlilik'**
  String get onboardingPurposeWork;

  /// No description provided for @onboardingPurposeEducation.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim & Okul'**
  String get onboardingPurposeEducation;

  /// No description provided for @onboardingPurposeDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hayat & Finans'**
  String get onboardingPurposeDaily;

  /// No description provided for @onboardingPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Senin için hazırlanıyor...'**
  String get onboardingPreparing;

  /// No description provided for @dashboardGreeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba'**
  String get dashboardGreeting;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı İşlemler'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son Kullanılanlar'**
  String get dashboardRecent;

  /// No description provided for @dashboardFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get dashboardFavorites;

  /// No description provided for @notesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notlarım'**
  String get notesTitle;

  /// No description provided for @notesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz not eklenmemiş.'**
  String get notesEmpty;

  /// No description provided for @notesNewNote.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Not'**
  String get notesNewNote;

  /// No description provided for @notesSearch.
  ///
  /// In tr, this message translates to:
  /// **'Not ara...'**
  String get notesSearch;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get profileSettings;

  /// No description provided for @profileAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get profileAbout;

  /// No description provided for @profileVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get profileVersion;

  /// No description provided for @profileLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get profileLogout;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @noConnection.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok.'**
  String get noConnection;

  /// No description provided for @unknownError.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen bir hata oluştu.'**
  String get unknownError;

  /// No description provided for @paywallRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın Almaları Geri Yükle'**
  String get paywallRestore;

  /// No description provided for @paywallDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'İstediğiniz zaman iptal edebilirsiniz. Ödeme App Store hesabınızdan tahsil edilecektir.'**
  String get paywallDisclaimer;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz (notlar, hatırlatıcılar) sadece cihazınızda güvenli bir şekilde saklanır. Sunucularımızda hiçbir kişisel veriniz tutulmamaktadır.'**
  String get privacyPolicyContent;

  /// No description provided for @termsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları (EULA)'**
  String get termsOfUse;

  /// No description provided for @termsOfUseContent.
  ///
  /// In tr, this message translates to:
  /// **'OmniBrain AI uygulamasını kullanarak Apple Standart Lisans Sözleşmesi (EULA) koşullarını kabul etmiş olursunuz. Yapay zekanın ürettiği sonuçlar bilgi amaçlıdır.'**
  String get termsOfUseContent;

  /// No description provided for @paywallSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma başarılı! PRO özellikler aktif.'**
  String get paywallSuccess;

  /// No description provided for @paywallFailure.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı veya iptal edildi.'**
  String get paywallFailure;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar başarıyla geri yüklendi!'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreFailure.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenecek geçerli bir satın alma bulunamadı.'**
  String get paywallRestoreFailure;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Dili (Otomatik)'**
  String get systemLanguage;

  /// No description provided for @onboardingReplay.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Tanıtımını İzle'**
  String get onboardingReplay;

  /// No description provided for @onboardingFeature1Badge.
  ///
  /// In tr, this message translates to:
  /// **'OCR & MASRAF'**
  String get onboardingFeature1Badge;

  /// No description provided for @onboardingFeature1Title.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Fiş & Belge Tarayıcı'**
  String get onboardingFeature1Title;

  /// No description provided for @onboardingFeature1Desc.
  ///
  /// In tr, this message translates to:
  /// **'Fiş ve faturalarınızı saniyeler içinde tarayın, harcamalarınızı otomatik toplayıp Excel/Muhasebe raporuna dönüştürün.'**
  String get onboardingFeature1Desc;

  /// No description provided for @onboardingFeature2Badge.
  ///
  /// In tr, this message translates to:
  /// **'2. BEYİN & SES'**
  String get onboardingFeature2Badge;

  /// No description provided for @onboardingFeature2Title.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zekâ Sesli Asistan'**
  String get onboardingFeature2Title;

  /// No description provided for @onboardingFeature2Desc.
  ///
  /// In tr, this message translates to:
  /// **'Toplantılarınızı ve ses kayıtlarınızı tek tıkla özetleyin, akıllı notlara ve eylem planlarına dönüştürün.'**
  String get onboardingFeature2Desc;

  /// No description provided for @onboardingFeature3Badge.
  ///
  /// In tr, this message translates to:
  /// **'ODAK & ZAMANLAYICI'**
  String get onboardingFeature3Badge;

  /// No description provided for @onboardingFeature3Title.
  ///
  /// In tr, this message translates to:
  /// **'Dinamik Odak & Canlı Ada'**
  String get onboardingFeature3Title;

  /// No description provided for @onboardingFeature3Desc.
  ///
  /// In tr, this message translates to:
  /// **'Pomodoro seanslarınızı kilit ekranı ve canlı adada takip edin, doğa sesleri eşliğinde kesintisiz odaklanın.'**
  String get onboardingFeature3Desc;

  /// No description provided for @onboardingFeature4Badge.
  ///
  /// In tr, this message translates to:
  /// **'ÇOK YÖNLÜ ARAÇLAR'**
  String get onboardingFeature4Badge;

  /// No description provided for @onboardingFeature4Title.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Çeviri & Hesaplama'**
  String get onboardingFeature4Title;

  /// No description provided for @onboardingFeature4Desc.
  ///
  /// In tr, this message translates to:
  /// **'Canlı döviz kurları, çoklu birim çevirici ve yapay zeka destekli matematiksel problem çözücü.'**
  String get onboardingFeature4Desc;

  /// No description provided for @onboardingStartExploring.
  ///
  /// In tr, this message translates to:
  /// **'Keşfetmeye Başla'**
  String get onboardingStartExploring;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'pt',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

# OmniBrain AI — Mobil Uygulama Proje Dokümanı

**Uygulama Adı:** OmniBrain AI  
**Platform:** Android + iOS  
**Kategori:** Verimlilik / Araçlar / Utility Suite  
**Hedef Kitle:** 18–45 yaş arası profesyonel çalışanlar, öğrenciler, freelancerlar ve dijital göçebeler  
**Ana Teknoloji:** Flutter + Supabase + Google ML Kit + OpenAI/LangChain  
**Tasarım Yaklaşımı:** Premium, profesyonel, karanlık mod odaklı, AI destekli süper araç kutusu  

---

## 1. Proje Özeti

OmniBrain AI; klasik mobil araçları tek bir yerde toplayan, ancak her aracın içine yapay zeka zekası yerleştiren premium bir “Süper Araç Kutusu” uygulamasıdır.

Standart araç kutusu uygulamaları genellikle sadece hesap makinesi, zamanlayıcı, not defteri veya dönüştürücü gibi basit fonksiyonlar sunar. OmniBrain AI ise bu araçları pasif işlevlerden çıkarıp aktif çözüm üreten, bağlamı anlayan ve kullanıcı adına öneri sunan bir yapıya dönüştürür.

Uygulamanın temel amacı:

> Kullanıcının günlük küçük ama zaman alan işlerini en az dokunuşla, mümkün olduğunda otomatik şekilde çözmek.

---

## 2. Ürün Vizyonu

OmniBrain AI, kullanıcının telefonunda sürekli açık duran bir yardımcı beyin gibi çalışmalıdır.

Kullanıcı bir notun fotoğrafını çektiğinde hesaplama yapabilmeli, bir belgede tarih geçtiğinde otomatik hatırlatıcı önerebilmeli, kopyalanan bir metnin adres mi link mi para tutarı mı olduğunu anlayabilmeli ve buna göre aksiyon sunabilmelidir.

Uygulama yalnızca “araç” sunmaz; kullanıcının ne yapmak istediğini anlayarak “çözüm” sunar.

---

## 3. Benzersiz Değer Önerisi

### 3.1 Ana Fark

Rakip uygulamalar:

- Hesap makinesi sunar.
- Zamanlayıcı sunar.
- Birim çevirici sunar.
- Not defteri sunar.
- Reklam gösterir.
- Genellikle sabit liste mantığıyla çalışır.

OmniBrain AI:

- Kullanıcının belge, not, metin ve davranış bağlamını anlar.
- AI ile işlem önerir.
- Proaktif hatırlatıcı oluşturur.
- Araçları kişiselleştirilebilir widget mantığıyla sunar.
- Reklamsız, temiz ve premium deneyim hedefler.
- Lifetime satış modeliyle kullanıcıya güven verir.

---

## 4. Temel Özellikler

## 4.1 AI-OCR Hesap Makinesi

Kullanıcı bir notun, faturanın, el yazısı hesaplamanın veya tablo benzeri bir içeriğin fotoğrafını çeker.

Uygulama:

1. Görseli Google ML Kit OCR ile okur.
2. Metni satır satır analiz eder.
3. Sayıları, para birimlerini, tarihleri ve açıklamaları ayıklar.
4. Gerekirse OpenAI ile anlamlandırır.
5. Sonucu dijital tabloya dönüştürür.
6. Kullanıcı isterse toplam, ortalama, vergi, indirim veya kategori hesaplaması yapar.

### Örnek Kullanım

Kullanıcı bir el yazısı masraf listesini çeker:

```text
Market 580 TL
Yakıt 1250 TL
Kargo 190 TL
```

Uygulama otomatik olarak tablo oluşturur:

| Kalem | Tutar |
|---|---:|
| Market | 580 TL |
| Yakıt | 1250 TL |
| Kargo | 190 TL |
| Toplam | 2020 TL |

---

## 4.2 Zamanın Efendisi — AI Pomodoro

Klasik Pomodoro uygulamalarından farklı olarak OmniBrain AI, kullanıcının çalışma düzenine göre süreleri optimize eder.

Uygulama:

- Standart 25/5 Pomodoro sunar.
- Kullanıcının gün içindeki enerji seviyesine göre öneri verir.
- Yoğun iş günlerinde daha kısa seanslar önerir.
- Uzun odak gerektiren işlerde daha uzun çalışma blokları sunar.
- Kullanıcı alışkanlıklarına göre zaman içinde kişiselleşir.

### Örnek AI Önerisi

> “Bugün yoğun çalıştığını görüyorum. 25 dakika yerine 18 dakika çalışma + 6 dakika mola daha verimli olabilir.”

---

## 4.3 Bağlamsal Hatırlatıcı

Uygulama belgelerde, notlarda veya kopyalanan metinlerde geçen önemli tarihleri algılar.

Örneğin:

- Sözleşme bitiş tarihi
- Fatura son ödeme tarihi
- Randevu tarihi
- Evrak teslim süresi
- Garanti bitiş tarihi
- Abonelik yenileme tarihi

Uygulama kullanıcıya hatırlatıcı oluşturmayı önerir.

### Örnek

Belgede şu metin geçiyorsa:

```text
Son ödeme tarihi: 14.07.2026
```

OmniBrain AI şunu önerir:

> “Bu belgede 14 Temmuz 2026 son ödeme tarihi görünüyor. 3 gün öncesine hatırlatıcı kurmamı ister misin?”

---

## 4.4 Evrensel Çevirici

Uygulama para birimi ve ölçü birimi çevirilerini kullanıcı konumuna ve kullanım bağlamına göre akıllı şekilde sunar.

### Desteklenecek Dönüşümler

- Para birimi
- Uzunluk
- Ağırlık
- Sıcaklık
- Hacim
- Alan
- Zaman
- Veri boyutu
- Hız
- Yakıt tüketimi

### Akıllı Davranış

Kullanıcı Çin’deyse Yuan dönüşümü öne çıkar.  
Türkiye’deyse TL, kilogram, metre, litre gibi yerel ve yaygın birimler önceliklenir.  
ABD içeriği algılanırsa mil, pound, Fahrenheit gibi birimler otomatik önerilir.

---

## 4.5 Akıllı Panoya Kopyalama

Kullanıcı herhangi bir metni kopyaladığında OmniBrain AI bunu analiz eder.

### Algılanabilecek İçerikler

| Kopyalanan İçerik | Önerilen Aksiyon |
|---|---|
| Adres | Haritada aç |
| Link | Tarayıcıda aç / Notlara kaydet |
| Para tutarı | Çevir / Hesapla |
| Telefon numarası | Ara / Kişilere ekle |
| Tarih | Hatırlatıcı oluştur |
| Uzun metin | Özetle |
| Liste | Tabloya dönüştür |
| Ürün fiyatı | Karşılaştır / hesapla |

---

## 5. Ana Kullanıcı Deneyimi

OmniBrain AI’ın ana ekranı sabit bir araç listesi gibi değil, yaşayan bir kontrol paneli gibi hissettirmelidir.

Kullanıcı uygulamayı açtığında:

1. Üstte AI Command Bar görür.
2. Ortada en çok kullandığı araç widget’ları yer alır.
3. Altta Focus Zone bulunur.
4. Sistem son kopyalanan metin, belge tarihi veya devam eden zamanlayıcı gibi bağlamsal öneriler gösterir.

---

# 6. Ekran Tasarımları

## 6.1 Genel Tasarım Prensibi

Android ve iOS ekranları aynı marka dilini taşımalı, ancak platformların doğal kullanım alışkanlıklarına uyum sağlamalıdır.

### Ortak Tasarım Dili

- Premium görünüm
- Glassmorphism kartlar
- Karanlık mod öncelikli yapı
- Neon mor ve buz mavisi aksanlar
- Yumuşak gölgeler
- Mikro animasyonlar
- Dokunma sonrası haptic feedback
- Akıcı geçişler
- Sade ama güçlü dashboard yapısı

### Platform Farkları

| Alan | Android | iOS |
|---|---|---|
| Navigasyon | Material 3 tab bar / navigation rail | Cupertino tab bar / iOS benzeri geçişler |
| Haptic | Android vibration pattern | iOS haptic feedback |
| Kamera izinleri | Android permission dialog yapısına uygun | iOS privacy açıklamaları net |
| Bildirimler | Android notification channel | iOS notification permission flow |
| Görsel yoğunluk | Biraz daha kompakt | Biraz daha ferah ve yuvarlatılmış |

---

## 6.2 Ana Ekran — Dashboard

### Amaç

Kullanıcının tüm akıllı araçlara tek ekrandan ulaşmasını sağlamak.

### Bileşenler

1. **AI Command Bar**
   - “Ne yapmak istiyorsun?” alanı
   - Metin, ses veya fotoğraf ile komut alma
   - Örnek placeholder:
     > “Belgeyi hesapla, zamanı planla, notu özetle…”

2. **Smart Tool Widgets**
   - Hesapla
   - Tara
   - Zamanla
   - Çevir
   - Not al
   - Hatırlat

3. **Focus Zone**
   - Devam eden zamanlayıcı
   - Yaklaşan hatırlatıcı
   - AI önerileri
   - Kopyalanan içerik önerileri

4. **Bottom Navigation**
   - Home
   - Tools
   - Brain
   - Notes
   - Profile

### Premium Görsel Yönlendirme

- Arka plan: Derin gece mavisi degrade
- Kartlar: %12–18 opaklıkta cam efekt
- Ana aksan: Neon mor
- İkincil aksan: Buz mavisi
- Kart köşeleri: 24 px
- Sayfa padding: 20–24 px
- Kart aralığı: 14–18 px

---

## 6.3 AI Command Ekranı

### Amaç

Kullanıcının doğal dil ile işlem başlatmasını sağlamak.

### Örnek Komutlar

- “Bu faturayı hesapla.”
- “Bu nottaki tarihleri çıkar.”
- “Bugün 3 saatlik çalışma planı yap.”
- “Bu metni özetle.”
- “Şu adresi haritada aç.”
- “Bu tutarı dolara çevir.”
- “Bu belge için hatırlatıcı kur.”

### Ekran Yapısı

- Büyük komut alanı
- Sesle giriş butonu
- Kamera ile giriş butonu
- Son komutlar
- Önerilen hızlı aksiyonlar

---

## 6.4 OCR Hesap Makinesi Ekranı

### Amaç

Fotoğraf, belge veya el yazısından hesaplama yapmak.

### Akış

1. Kamera açılır.
2. Kullanıcı belgeyi çeker.
3. OCR metni çıkarır.
4. AI metni anlamlandırır.
5. Tablo ekranı gösterilir.
6. Kullanıcı sonucu düzenleyebilir.
7. CSV/PDF/Not olarak kaydedebilir.

### Ekran Bileşenleri

- Kamera alanı
- Belge kenar algılama
- OCR sonucu önizleme
- AI düzeltme önerisi
- Tablo sonucu
- Toplam / kategori / not alanı

---

## 6.5 AI Pomodoro Ekranı

### Amaç

Kullanıcının odak seanslarını AI ile optimize etmek.

### Bileşenler

- Büyük dairesel zamanlayıcı
- Odak modu seçimi
- AI önerilen süre
- Mola önerisi
- Günlük odak istatistikleri
- “Bugünkü enerji seviyem” seçimi

### Odak Modları

- Kısa Odak
- Derin Çalışma
- Ders Çalışma
- Yazılım Geliştirme
- Evrak / Ofis İşi
- Serbest Mod

---

## 6.6 Evrensel Çevirici Ekranı

### Amaç

Para, ölçü ve veri birimi dönüşümlerini hızlı yapmak.

### Bileşenler

- Kaynak değer alanı
- Hedef değer alanı
- Akıllı öneriler
- Lokasyona göre popüler dönüşümler
- Son kullanılan dönüşümler

### Örnek Akıllı Kart

> “Türkiye konumundasın. TL, kilogram, metre ve litre dönüşümleri öne çıkarıldı.”

---

## 6.7 Notlar ve Belge Hafızası Ekranı

### Amaç

Kullanıcının taradığı veya yazdığı içerikleri AI ile saklamak ve sorgulatmak.

### Bileşenler

- Not listesi
- Belge listesi
- Etiketler
- AI özet
- Tarih algılama
- Sorgulama alanı

### Örnek Sorgular

- “Geçen hafta çektiğim faturaları göster.”
- “İçinde son ödeme tarihi geçen belgeleri bul.”
- “Bu notları yapılacaklar listesine çevir.”
- “Mayıs ayındaki harcamaları hesapla.”

---

## 6.8 Profil ve Abonelik Ekranı

### Amaç

Kullanıcının hesap, dil, tema ve ödeme ayarlarını yönetmesi.

### Bileşenler

- Kullanıcı hesabı
- Ücretsiz plan
- Lifetime plan
- AI Premium plan
- Dil seçimi
- Tema seçimi
- Veri güvenliği ayarları
- Supabase hesap yönetimi

---

# 7. Widget-in-Widget Sistemi

OmniBrain AI’ın en ayırt edici özelliklerinden biri “Widget-in-Widget” yaklaşımıdır.

Ana ekrandaki her araç bir widget gibi çalışır. Kullanıcı uzun basarak widget’ı özelleştirebilir.

### Özelleştirme Seçenekleri

- Kart boyutu
- Kart rengi
- Kısayol aksiyonu
- AI davranışı
- Ana ekranda göster/gizle
- Öncelik sırası

### Örnek

Kullanıcı zamanlayıcı widget’ına uzun basar ve şunu yazar:

> “Bu zamanlayıcıyı iş saatlerime göre ayarla.”

AI, kullanıcının kullanım alışkanlıklarına göre çalışma/mola düzeni önerir.

---

# 8. Tasarım Dili

## 8.1 Renk Paleti

| Kullanım | Renk | Hex |
|---|---|---|
| Ana zemin | Derin Gece Mavisi | `#0A0E17` |
| İkincil zemin | Koyu Lacivert | `#111827` |
| Ana aksan | Neon Mor | `#8A2BE2` |
| İkincil aksan | Buz Mavisi | `#7DF9FF` |
| Başarı | Soft Yeşil | `#4ADE80` |
| Uyarı | Amber | `#FBBF24` |
| Hata | Mercan Kırmızı | `#FB7185` |
| Metin ana | Kirli Beyaz | `#F8FAFC` |
| Metin ikincil | Gri Mavi | `#94A3B8` |

---

## 8.2 Tipografi

Önerilen fontlar:

- Inter
- Montserrat
- SF Pro benzeri sistem fontu
- Android için Roboto destekli yapı

### Tipografi Hiyerarşisi

| Alan | Boyut |
|---|---:|
| Büyük başlık | 28–32 px |
| Sayfa başlığı | 22–26 px |
| Kart başlığı | 16–18 px |
| Açıklama | 13–15 px |
| Mikro metin | 11–12 px |

---

## 8.3 Kart Tasarımı

Kartlar:

- Glassmorphism efektli
- Yuvarlatılmış köşeli
- Hafif blur efektli
- İnce neon border detaylı
- Dokununca hafif büyüyen
- Haptic feedback destekli
- Uzun basınca özelleştirilebilir olmalı

### Kart Teknik Özellikleri

```text
Border Radius: 24 px
Blur: 16–24
Opacity: 0.12–0.18
Border: 1 px rgba(255,255,255,0.12)
Shadow: Soft, low opacity
```

---

# 9. Teknik Mimari

## 9.1 Frontend

**Framework:** Flutter  
**State Management:** Riverpod  
**Architecture:** Clean Architecture  
**Navigation:** GoRouter  
**Local Storage:** Hive veya Isar  
**Network:** Dio  
**UI:** Custom design system + reusable widgets  

---

## 9.2 Backend

**Backend/Database/Auth:** Supabase

Supabase kullanılacak alanlar:

- Kullanıcı kayıt/giriş
- Not ve belge kayıtları
- Hatırlatıcı verileri
- Kullanıcı plan bilgisi
- AI işlem geçmişi
- Kullanım limiti takibi
- RAG için embedding metadata

---

## 9.3 AI/ML Katmanı

### OCR

**Google ML Kit** kullanılacak.

Görevler:

- Görselden metin çıkarma
- Belge üzerindeki sayıları tanıma
- Tarih algılama için ham veri oluşturma
- El yazısı desteği için ileride genişletme

### OpenAI / LangChain

Görevler:

- Belge anlamlandırma
- RAG sorguları
- Özetleme
- Tarih ve görev çıkarımı
- Tablo oluşturma
- Akıllı öneriler
- Kullanıcının doğal dil komutlarını işleme

---

## 9.4 RAG Yapısı

Kullanıcının taradığı belgeler ve notlar parçalanarak saklanır.

### Önerilen Akış

1. Kullanıcı belgeyi tarar.
2. OCR metni çıkarır.
3. Metin temizlenir.
4. Chunk’lara ayrılır.
5. Embedding oluşturulur.
6. Supabase pgvector yapısında saklanır.
7. Kullanıcı belge hakkında soru sorabilir.
8. Sistem ilgili parçaları getirerek cevap üretir.

---

## 9.5 Güvenlik ve Gizlilik

Bu uygulama belge, not ve kişisel veri işleyebileceği için güvenlik en baştan tasarlanmalıdır.

### Temel Kurallar

- Kullanıcı izni olmadan belge işlenmemeli.
- Kamera ve pano izinleri açık anlatılmalı.
- Pano takibi tamamen kullanıcı kontrolünde olmalı.
- Hassas belgeler için silme seçeneği net olmalı.
- AI işlem geçmişi kapatılabilir olmalı.
- Kullanıcı verileri Supabase RLS ile korunmalı.
- AI servislerine gönderilen veriler minimum gerekli veri olmalı.

---

# 10. Gelir Modeli

## 10.1 Freemium

Ücretsiz kullanıcılar:

- Temel hesap makinesi
- Temel zamanlayıcı
- Temel birim çevirici
- Sınırlı not alma
- Günlük sınırlı OCR
- Sınırlı AI komutu

---

## 10.2 Lifetime Paket

Tek seferlik ödeme modeli.

Örnek fiyat:

```text
Lifetime Pro: $19.99
```

İçerik:

- Reklamsız kullanım
- Sınırsız temel araçlar
- Gelişmiş widget özelleştirme
- Daha yüksek OCR limiti
- Premium tema seçenekleri
- Yerel not arşivi

---

## 10.3 AI Premium Abonelik

Aylık abonelik modeli.

İçerik:

- Yüksek hacimli belge analizi
- Gelişmiş AI sorgulama
- RAG belge hafızası
- Uzun belge özetleme
- Gelişmiş hatırlatıcı çıkarımı
- Çoklu cihaz senkronizasyonu
- Öncelikli AI işlem limiti

---

## 10.4 Ödeme Altyapısı

Önerilen servis:

- RevenueCat

Kullanım amacı:

- App Store abonelikleri
- Google Play abonelikleri
- Lifetime satın alma
- Plan yönetimi
- Deneme süresi yönetimi

---

# 11. Çoklu Dil Stratejisi

İlk çıkış:

- Türkçe
- İngilizce

Genişleme:

- İspanyolca

### Neden İspanyolca?

Güney Amerika pazarına Lifetime paketlerle giriş için uygundur. Verimlilik ve yardımcı araç uygulamaları bu pazarda düşük fiyatlı tek seferlik ödeme modeliyle daha kolay test edilebilir.

---

# 12. MVP Yol Haritası

## Phase 1 — Temel Ürün

Hedef: Premium arayüzlü çalışır ilk sürüm.

### Özellikler

- Onboarding
- Ana dashboard
- AI Command Bar tasarımı
- Hesap makinesi
- Pomodoro timer
- Temel birim çevirici
- Basit not alma
- Profil ekranı

---

## Phase 2 — AI Layer

Hedef: OmniBrain AI’ın gerçek farkını ortaya çıkarmak.

### Özellikler

- Google ML Kit OCR
- Fotoğraftan metin çıkarma
- Belge analizi
- Tarih algılama
- AI özetleme
- AI tablo oluşturma
- Bağlamsal hatırlatıcı önerileri

---

## Phase 3 — RAG ve Hafıza

Hedef: Kullanıcının belgeleriyle konuşabilmesi.

### Özellikler

- Belge arşivi
- Embedding oluşturma
- Supabase pgvector
- RAG sorguları
- “Belgelerimde ara” özelliği
- Kişisel bilgi hafızası
- Akıllı belge klasörleme

---

## Phase 4 — Global ve Gelir

Hedef: Yayın ve gelir modeli.

### Özellikler

- RevenueCat entegrasyonu
- Lifetime paket
- AI Premium abonelik
- İngilizce arayüz
- İspanyolca arayüz
- App Store yayın hazırlığı
- Google Play yayın hazırlığı
- Store görselleri
- Tanıtım videosu

---

# 13. Uygulama Modülleri

## 13.1 Core Modüller

```text
lib/
  core/
    constants/
    theme/
    routing/
    errors/
    utils/
    widgets/
```

## 13.2 Feature Modülleri

```text
lib/
  features/
    dashboard/
    ai_command/
    ocr_calculator/
    pomodoro/
    converter/
    notes/
    reminders/
    profile/
    subscriptions/
```

## 13.3 Data Katmanı

```text
lib/
  data/
    datasources/
    repositories/
    models/
```

## 13.4 Domain Katmanı

```text
lib/
  domain/
    entities/
    repositories/
    usecases/
```

## 13.5 Presentation Katmanı

```text
lib/
  presentation/
    screens/
    widgets/
    providers/
```

---

# 14. Supabase Veri Modeli Taslağı

## 14.1 users_profile

| Alan | Tip |
|---|---|
| id | uuid |
| user_id | uuid |
| full_name | text |
| language | text |
| plan | text |
| created_at | timestamp |

---

## 14.2 notes

| Alan | Tip |
|---|---|
| id | uuid |
| user_id | uuid |
| title | text |
| content | text |
| tags | text[] |
| created_at | timestamp |
| updated_at | timestamp |

---

## 14.3 documents

| Alan | Tip |
|---|---|
| id | uuid |
| user_id | uuid |
| title | text |
| raw_text | text |
| summary | text |
| source_type | text |
| created_at | timestamp |

---

## 14.4 reminders

| Alan | Tip |
|---|---|
| id | uuid |
| user_id | uuid |
| title | text |
| description | text |
| due_date | timestamp |
| source_document_id | uuid |
| is_completed | boolean |

---

## 14.5 ai_actions

| Alan | Tip |
|---|---|
| id | uuid |
| user_id | uuid |
| action_type | text |
| input_text | text |
| output_text | text |
| token_usage | integer |
| created_at | timestamp |

---

## 14.6 document_chunks

| Alan | Tip |
|---|---|
| id | uuid |
| document_id | uuid |
| user_id | uuid |
| chunk_text | text |
| embedding | vector |
| metadata | jsonb |
| created_at | timestamp |

---

# 15. Antigravity IDE İçin Geliştirme Promptları

## 15.1 Proje Başlangıç Promptu

```text
Flutter ile Android ve iOS için geliştirilecek "OmniBrain AI" adlı premium bir verimlilik uygulaması başlat.

Clean Architecture kullan.
State management için Riverpod kullan.
Navigation için GoRouter kullan.
Tema sistemi dark mode odaklı olsun.
Supabase Auth ve Database entegrasyonu için temel servis katmanlarını hazırla.

Uygulama modülleri:
- Dashboard
- AI Command
- OCR Calculator
- Pomodoro
- Converter
- Notes
- Reminders
- Profile
- Subscriptions

Kod okunabilir, modüler, genişletilebilir ve production-ready yapıda olsun.
```

---

## 15.2 Ana Dashboard UI Promptu

```text
OmniBrain AI için premium, modern ve glassmorphism tarzında ana dashboard ekranı oluştur.

Tasarım dili:
- Derin gece mavisi arka plan: #0A0E17
- Neon mor aksan: #8A2BE2
- Buz mavisi aksan: #7DF9FF
- Cam efektli kartlar
- Yuvarlatılmış köşeler
- Soft gradient arka plan
- Minimal ve profesyonel görünüm

Ekran bölümleri:
1. Üstte AI Command Bar
2. Ortada Smart Tool Widget grid
3. Altta Focus Zone
4. Bottom Navigation

Kartlar dokunulduğunda hafif büyüme animasyonu ve haptic feedback olsun.
Android ve iOS üzerinde responsive çalışsın.
```

---

## 15.3 AI Command Bar Promptu

```text
OmniBrain AI için AI Command Bar bileşeni oluştur.

Bu bileşen:
- Kullanıcının doğal dil komutu yazmasını sağlamalı
- Kamera butonu içermeli
- Mikrofon butonu içermeli
- Placeholder metni: "Belgeyi hesapla, zamanı planla, notu özetle..."
- Glassmorphism tasarım diline uygun olmalı
- Focus olduğunda neon border animasyonu göstermeli
- Komut gönderildiğinde loading state göstermeli
- Riverpod ile state yönetimi yapılmalı
```

---

## 15.4 Widget-in-Widget Promptu

```text
OmniBrain AI ana ekranındaki araç kartlarını Widget-in-Widget mantığıyla geliştir.

Her araç kartı:
- Normal dokunmada ilgili aracı açmalı
- Uzun basıldığında özelleştirme paneli açmalı
- Kullanıcı kart rengini, boyutunu ve önceliğini değiştirebilmeli
- AI ayarı eklenebilmeli
- Kart düzeni local storage içinde saklanmalı

Özelleştirme paneli bottom sheet olarak açılsın.
Animasyonlar premium ve akıcı olsun.
```

---

## 15.5 OCR Hesap Makinesi Promptu

```text
OmniBrain AI için OCR Calculator modülünü oluştur.

Akış:
1. Kamera ile belge/fatura/not fotoğrafı çek
2. Google ML Kit ile OCR işle
3. Çıkan metni kullanıcıya önizleme olarak göster
4. Sayı, para birimi, tarih ve açıklamaları ayıkla
5. Sonucu düzenlenebilir tabloya çevir
6. Toplam hesapla
7. Sonucu notlara kaydetme seçeneği sun

Kod yapısı Clean Architecture'a uygun olsun.
OCR servis katmanı ayrı yazılsın.
AI analiz servisi ayrı yazılsın.
Hata durumları için kullanıcı dostu mesajlar gösterilsin.
```

---

## 15.6 AI Pomodoro Promptu

```text
OmniBrain AI için AI destekli Pomodoro ekranı oluştur.

Ekranda:
- Büyük dairesel zamanlayıcı
- Başlat/durdur/sıfırla butonları
- Çalışma modu seçimi
- AI önerilen süre kartı
- Günlük odak istatistikleri
- Mola önerileri yer alsın

Modlar:
- Kısa Odak
- Derin Çalışma
- Ders Çalışma
- Yazılım Geliştirme
- Evrak / Ofis İşi
- Serbest Mod

Zamanlayıcı animasyonları akıcı olsun.
Arka plan glassmorphism ve neon premium tasarıma uygun olsun.
```

---

## 15.7 Evrensel Çevirici Promptu

```text
OmniBrain AI için Universal Converter ekranı oluştur.

Dönüşüm kategorileri:
- Para birimi
- Uzunluk
- Ağırlık
- Sıcaklık
- Hacim
- Alan
- Zaman
- Veri boyutu
- Hız

Ekran:
- Kaynak değer alanı
- Hedef değer alanı
- Kategori seçimi
- Son kullanılan dönüşümler
- Lokasyona göre akıllı öneriler

UI premium, sade, hızlı ve tek elle kullanılabilir olsun.
```

---

## 15.8 Supabase Entegrasyon Promptu

```text
OmniBrain AI için Supabase servis katmanını oluştur.

Gereken servisler:
- AuthService
- NotesService
- DocumentsService
- RemindersService
- AiActionsService
- UserProfileService

Her servis async yapıda olsun.
Repository pattern kullan.
Hata yönetimini merkezi hale getir.
RLS kurallarına uygun veri erişimi planla.
Kullanıcı sadece kendi verilerine erişebilsin.
```

---

## 15.9 RAG ve Belge Hafızası Promptu

```text
OmniBrain AI için RAG tabanlı belge hafızası mimarisi tasarla.

Kullanıcı belgeleri:
- OCR ile metne çevrilecek
- Temizlenecek
- Chunk'lara ayrılacak
- Embedding oluşturulacak
- Supabase pgvector içinde saklanacak

Kullanıcı belge hakkında soru sorduğunda:
1. Soru embedding'e çevrilsin
2. En alakalı belge parçaları getirilsin
3. OpenAI ile yanıt oluşturulsun
4. Yanıtın hangi belgeden geldiği gösterilsin

Kod modüler, güvenli ve ölçeklenebilir olsun.
```

---

## 15.10 RevenueCat Promptu

```text
OmniBrain AI için RevenueCat ödeme entegrasyonu planla ve temel kod yapısını oluştur.

Planlar:
- Free
- Lifetime Pro
- AI Premium Monthly
- AI Premium Yearly

Özellik kilitleri:
- OCR günlük limit
- AI komut limiti
- RAG belge hafızası
- Premium tema
- Widget özelleştirme
- Gelişmiş belge analizi

Satın alma durumu uygulama genelinde Riverpod provider ile yönetilsin.
```

---

# 16. Yayın Öncesi Kontrol Listesi

## 16.1 Teknik

- Android build test edildi
- iOS build test edildi
- Supabase bağlantıları çalışıyor
- Auth akışı çalışıyor
- OCR izinleri doğru
- Kamera izinleri doğru
- Bildirim izinleri doğru
- RLS kuralları aktif
- Hata loglama kuruldu
- Offline senaryolar test edildi

---

## 16.2 Tasarım

- Dark mode kusursuz
- Light mode minimum destekli
- Kartlar tüm ekranlarda uyumlu
- iPhone küçük ekran test edildi
- iPhone büyük ekran test edildi
- Android küçük ekran test edildi
- Android büyük ekran test edildi
- Tablet görünümü temel seviyede test edildi
- Haptic feedback doğru çalışıyor
- Animasyonlar kasmıyor

---

## 16.3 Ürün

- Onboarding açık ve kısa
- İlk kullanıcı deneyimi basit
- Premium değer net anlatılıyor
- Free/Lifetime/Premium farkı anlaşılır
- AI özellikleri abartısız ve güven verici anlatılıyor
- Gizlilik metinleri hazır
- Store açıklamaları hazır
- Ekran görüntüleri hazır
- Tanıtım videosu hazır

---

# 17. İlk Sürüm İçin Net MVP Tavsiyesi

İlk sürümde tüm AI özellikleri aynı anda yapılmamalıdır.

Önerilen MVP:

1. Premium dashboard
2. Hesap makinesi
3. Pomodoro
4. Birim çevirici
5. Basit not defteri
6. OCR ile fotoğraftan metin çıkarma
7. AI Command Bar tasarımı
8. Lifetime satın alma altyapısı

RAG, gelişmiş belge hafızası ve proaktif hatırlatıcılar ikinci fazda eklenmelidir.

Bu yaklaşım daha hızlı yayına çıkmayı, kullanıcı tepkisini ölçmeyi ve gelir modelini erken test etmeyi sağlar.

---

# 18. Uygulama Sloganı Önerileri

- “Telefonundaki ikinci beyin.”
- “Araç değil, akıllı çözüm.”
- “Kopyala, tara, sor, çöz.”
- “Günlük işlerin için AI destekli süper araç kutusu.”
- “OmniBrain AI: Daha az tık, daha çok sonuç.”
- “Notunu okur, hesabını yapar, zamanını planlar.”
- “Karmaşık işleri basit hale getiren mobil beyin.”

---

# 19. Kısa Store Açıklaması

OmniBrain AI; hesap makinesi, zamanlayıcı, not defteri, birim çevirici ve belge analizini yapay zeka ile birleştiren premium bir süper araç kutusudur. Fotoğraf çek, metni okut, hesapla, özetle, hatırlatıcı oluştur ve günlük işlerini daha az dokunuşla çöz.

---

# 20. Uzun Store Açıklaması Taslağı

OmniBrain AI, klasik mobil araçları yapay zeka ile güçlendiren yeni nesil bir verimlilik uygulamasıdır.

Bir notun fotoğrafını çekerek hesaplama yapabilir, belgelerdeki önemli tarihleri yakalayabilir, odaklanmak için AI destekli Pomodoro kullanabilir, para ve ölçü birimlerini hızlıca çevirebilir, kopyaladığınız metne göre akıllı aksiyon önerileri alabilirsiniz.

OmniBrain AI sadece araç sunmaz; günlük işlerinizi anlamaya ve sizin yerinize daha hızlı çözmeye odaklanır.

Öne çıkan özellikler:

- AI destekli OCR hesap makinesi
- Akıllı Pomodoro zamanlayıcı
- Evrensel para ve birim çevirici
- Bağlamsal hatırlatıcı önerileri
- Akıllı pano aksiyonları
- Not ve belge hafızası
- Premium, reklamsız ve modern arayüz
- Lifetime ve AI Premium seçenekleri

OmniBrain AI ile telefonunuzdaki klasik araçlar artık pasif değil, akıllı bir asistana dönüşür.

---

# 21. Sonuç

OmniBrain AI, tek başına bir araç kutusu uygulaması değil; kullanıcının günlük dijital işlerini anlayan, sadeleştiren ve hızlandıran bir mobil yapay zeka merkezi olarak konumlandırılmalıdır.

Başarının anahtarı:

- Basit başlangıç
- Çok iyi tasarım
- Reklamsız premium his
- AI özelliklerini gerçekten faydalı kullanmak
- Lifetime satış modelini erken test etmek
- Kullanıcının günlük alışkanlıklarına yerleşmek

İlk hedef, tüm özellikleri bir anda yapmak değil; kullanıcıya ilk açılışta “bu uygulama kaliteli ve işe yarar” hissini vermektir.
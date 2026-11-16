# AxleBackdrop — Claude devir notu

Bu dosya, 2026-11-16 tarihinde Codex oturumunun bıraktığı uygulama, tasarım ve doğrulama durumunu aktarır. Kod ve asset’ler çalışma ağacında mevcut; değişiklikler henüz commit edilmedi. Kullanıcının hedefi native iOS uygulamasını TestFlight beta kalitesine taşımak. Türkçe ilerleme/iletişim, uygulama UI metinlerinde US English kullanılmalı.

## Hızlı başlangıç

1. `git status --short` ile mevcut kullanıcı değişikliklerini kontrol et. Bunlar bu çalışmanın beklenen değişiklikleridir; sıfırlama/checkout yapma.
2. Xcode projesini aç: `AxleBackdrop.xcodeproj`, scheme: `AxleBackdrop`.
3. Mevcut build/test komutları:

```sh
xcodebuild build -project AxleBackdrop.xcodeproj -scheme AxleBackdrop \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test -project AxleBackdrop.xcodeproj -scheme AxleBackdrop \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  -only-testing:AxleBackdropTests CODE_SIGNING_ALLOWED=NO

xcodebuild test -project AxleBackdrop.xcodeproj -scheme AxleBackdrop \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  -only-testing:AxleBackdropUITests CODE_SIGNING_ALLOWED=NO
```

CoreSimulator bu Mac’te arada LaunchServices takılması yaşadı. Bir temiz iOS 26.4.1 QA simülatörü çalıştı. Gerekirse mevcut simulator data’sını silmeden `killall -9 com.apple.CoreSimulator.CoreSimulatorService` ile servisi yeniden başlat; ardından boot/install işlemini tekrarla. Yeni temiz simülatör UDID’leri `xcrun simctl list devices` ile kontrol et.

## Ürün ve yapılandırma

- Uygulama: AxleBackdrop, yalnız iPhone, minimum deployment iOS 17.0.
- Bundle ID: `com.rdcorp.AxleBackdrop`.
- Team: `H455KBKF74`.
- Version/build: `1.0 (1)`; TestFlight öncesi build numarasını artır.
- Akış: Home/Drafts → New Listing → Vehicle Type → Photos → Scene → Processing → Review → Export.
- Car: dış ön sol ¾, dış arka sağ ¾, ön kabin, arka kabin, instrument cluster.
- Motorcycle: dış ön sol ¾, dış arka sağ ¾, tam sol profil, tam sağ profil, instrument cluster.
- Yalnız ilk iki slot seçili scene’e gönderilir. Üçüncü/dördüncü slotta hafif yerel düzeltme; beşinci slotta metadata temizleme hedeflenmiştir.
- İki yerleşik scene var: Indoor Garage ve Outdoor Scenic. App icon dahil üretim bilgisi `AxleBackdrop/Resources/Provenance/GENERATED_ASSETS.md` dosyasında.
- Light/Dark token’ları `AxleBackdrop/AppTheme.swift` içinde. System/Light/Dark tercihi AppStorage ile saklanıyor.
- Metinlerin kaynak kataloğu `AxleBackdrop/Localizable.xcstrings`.
- Basit beta/TestFlight metin taslağı `Release/TestFlightMetadata.md`; privacy policy, support URL ve doğrulanmış destek e-postası tamamlanmalı.

## Görsel sistem ve ekran davranışı

Token’ların gerçek Light/Dark RGB hex değerleri `AxleBackdrop/AppTheme.swift` içindedir:

| Token | Light | Dark | Kullanım |
|---|---:|---:|---|
| Canvas | `#F6F2EB` | `#111315` | App-owned ekran zemini |
| Surface | `#FFFFFF` | `#1B1E21` | Kartlar ve temel yüzeyler |
| Raised | `#FBF8F3` | `#25292D` | Yükseltilmiş/ikincil yüzey |
| Primary text | `#17191C` | `#F5F3EF` | Başlık ve ana metin |
| Secondary text | `#5D646B` | `#B7BDC4` | Yardımcı etiketler |
| Border | `#D9D3CA` | `#3C4248` | Kart/ayırıcı sınırları |
| Accent | `#B83D20` | `#FF7A50` | Ana eylem ve seçim |
| Success | `#16784A` | `#52D49A` | Başarı durumu |
| Warning | `#8A5600` | `#FFC15A` | Uyarı durumu |
| Error | `#B3261E` | `#FF8178` | Hata durumu |
| Photo canvas | `#E4E5E3` | `#202326` | Fotoğraf çevresindeki nötr zemin |

Birincil buton minimum 52 pt, ikincil 50 pt; kart köşesi 16 pt, buton köşesi 12 pt. Sistem fontu, SF Symbols, kart sınırları ve basılı durum opacity’si kullanılıyor. `AppearancePreference` System/Light/Dark değerlerini saklıyor. Ekranlar için pratik hiyerarşi: Home’da “New Listing”; vehicle type’ta iki eşdeğer araç kartı; Photos’ta beş slot + ilerleme + capture/import; Scene’de iki büyük seçim ve açı geçişi; Review’de geniş kapak ve Original/Edited kontrolü; Export’ta ayrı Save ve Share. Her kareyi gerçek araç ve Dynamic Type ile tekrar gözden geçir; token tanımları tek başına kontrast doğrulaması değildir.

## Kod haritası

| Dosya | Sorumluluk |
|---|---|
| `AxleBackdrop/AxleBackdropApp.swift` | SwiftData container ve app başlangıcı |
| `AxleBackdrop/ContentView.swift` | Home, draft list, navigation, vehicle type, DEBUG QA seed parametreleri |
| `AxleBackdrop/Models.swift` | VehicleType, PhotoSlot, PhotoRecord, SceneKind, Placement, ListingDraft, DealerTemplate |
| `AxleBackdrop/PhotosView.swift` | PhotosPicker, kamera wrapper, framing guide, 4:3 onay önizlemesi |
| `AxleBackdrop/SceneAndProcessingViews.swift` | Scene seçimi, dealer template import/editor, processing ekranı |
| `AxleBackdrop/ReviewExportSettingsViews.swift` | Original/Edited review, export ekranı, share sheet, Settings |
| `AxleBackdrop/PhotoFileStore.swift` | Orijinal/render/template yerel dosya yolu ve JPEG encode |
| `AxleBackdrop/ImageProcessingService.swift` | Vision foreground mask, Core Image composite/shadow, detay düzeltme, metadata-free encode |
| `AxleBackdrop/ExportService.swift` | Beş export JPEG’i sıraya koyma ve Photos’a add-only kaydetme |
| `AxleBackdrop/PrivacyInfo.xcprivacy` | Privacy manifest taslağı |
| `AxleBackdropTests/AxleBackdropTests.swift` | Model, slot, SwiftData ve export format testleri |
| `AxleBackdropUITests/AxleBackdropUITests.swift` | Motorcycle seçimi ve Photos’a geçiş UI testi |

Veri yolu: SwiftData draft/template metadata’sı; fotoğraf dosyaları `Application Support/AxleBackdrop/Drafts/<UUID>/{Originals,Rendered,Export}`; custom template’ler `Application Support/AxleBackdrop/Templates`.

## Çok önemli düzeltme önceliği

### 1. Gerçek kaynak fotoğraflarını koru

`PhotoFileStore.storeOriginal(data:projectID:slot:)` şu an `UIImage(data:)` ile açıyor, center crop yapıp 3000×2250 JPEG olarak yeniden encode ediyor ve bu dosyayı “original” diye saklıyor. Bu, kaynak piksel/metadata/orijinal oranını korumaz; 4:3 import crop’ı kullanıcı tarafından interaktif ayarlanmaz. Öncelikle byte-for-byte kaynak dosyasını app-owned Originals içine atomik kopyala. Orientation ve 4:3 crop’u render/export aşamasında ayrı, kullanıcı onaylı karar olarak uygula. Source ve derivative isimlerini/model durumunu açıkça ayır. Export testi de source’un değişmediğini kontrol et.

### 2. Vision/composite’i gerçek veriyle doğrula

`ImageProcessingService` mevcut Vision `VNGenerateForegroundInstanceMaskRequest` ile `allInstances` maskesini alıyor. Bu genel foreground segmentasyonudur; araç özelinde garanti vermez. Motosiklet telleri, aynalar, gidon, cam, egzoz ve şasi boşlukları; araç camları, parlak boya ve yoğun fon kritik örneklerdir. Scene ve placement ekranlarında şu an preview overlay/tint gösterimi var; gerçek segmentasyonlu sonuç yalnız processing’den sonra oluşuyor. Test korpusu kullanıcı tarafından sağlanacak: en az 10 otomobil + 10 motosiklet projesi, her projede iki dış açı. Sonuç başarısızsa app original seçeneğini sunmalı. Bu kalite kapısı geçmeden App Store subtitle’da “AI” kullanma.

### 3. Kamera/erişim akışlarını tamamla

`CameraPicker` çalışır kamera varsa açılır ve guide overlay gösterir. Kamera yoksa button şu anda disabled kalır; simulator’da Photos import yolu kullanılmalı. `PhotosPicker` permission-native picker davranışı verir. CropApproval ekranı şimdilik kırpma seçtirmiyor, sadece center crop sonucunu gösterip onaylıyor; gerçek crop editor geliştirilmeli. Kamera, library import, izin retleri, app interruption ve draft relaunch fiziksel cihazda doğrulanmalı.

### 4. İşleme ve bellek/iptal

Render actor’ları kullanıldı fakat tüm süreç için bounded decoded-pixel pipeline, concurrency limit, temp cleanup, disk-full kontrolü ve gerçek cancellation toparlanması henüz kanıtlanmadı. `ProcessingView` photo-level hata kaydeder ve original seçeneği verir. Offline durumda tüm pipeline cihaz içi olduğundan çalışmalı; bu henüz gerçek fotoğrafla test edilmedi. Bir slot hatası diğer slot sonuçlarını silmemeli.

## Doğrulama: ne geçti, ne geçmedi

Geçen kanıtlar:

- Xcode 27.2 ile generic iOS Simulator Debug build başarılı.
- Generic iOS device Release build başarılı.
- iPhone 17e simülatöründe (iOS 26.4.1, build 23E254a) 6/6 unit test geçti. Testler: beş slot/sıra, araç türü açı adları, record update, placement JSON round-trip, in-memory SwiftData, beş JPEG export sırası/3000×2250/GPS metadata yok.
- UI testi Motorcycle seçimini, “Full left-side profile” metnini ve Photos ekranına geçişi geçti.
- DEBUG simulator QA başlatma argümanları eklendi: `-QAHome` Home’u açar; `-QAStage photos|scene|review` beş fixture JPEG’li test draft üretir. Sadece `#if DEBUG` içine derlenir.
- Kompakt iPhone 17e (`1170×2532`) ve büyük iPhone 17 Pro Max (`1320×2868`) ekranlarında Home, Photos, Scene, Review Light/Dark screenshot seti `QA/Screenshots/` altında.
- iPhone 17e XXXL Review screenshot’ı Dynamic Type sorununu yakaladı. Başlık satırlanması, `ViewThatFits` export başlığı, image overlay label ölçeği ve multiline button ile düzeltildi; XXXL screenshot tekrar alındı.
- Scene seçimi, her iki açı tab’ı, standart scene cards ve placement preview ekran görüntüsü var. Review before/after kontrolü ve sıra şeridi görünür.
- `/tmp/AxleBackdrop.xcarchive` signed archive oluşturuldu. `codesign --verify --deep --strict --verbose=2` başarılı. Kimlik `Apple Development`, Team `H455KBKF74`, Bundle ID `com.rdcorp.AxleBackdrop`.

Geçmeyen/eksik kanıtlar:

- Fiziksel `iPhone-RD` önceki envanterde offline görünüyordu. Fiziksel cihaz testi yapılmadı.
- Kamera ile gerçek capture→export akışı yapılmadı.
- Gerçek araç fotoğraf korpusu yok; Vision maskesi kalite eşiği veya hız/bellek değerleri ölçülmedi.
- Büyük cihaz screenshot setinin tamamı alındı ve Review Light karelerinden biri görsel olarak incelendi; bütün kareler tek tek gözden geçirilmedi.
- Signed archive son UI/QA/test değişikliklerinden daha eski. Final kod için yeniden archive et ve yeniden `codesign --verify` yap.
- App Store Connect kaydı açılmadı, upload yapılmadı, TestFlight install veya Apple review durumu yok.
- Privacy URL, support URL ve destek adresi eksik.

## Screenshot envanteri

`QA/Screenshots/` şu an şunları içeriyor:

- iPhone 17e Light/Dark: Home, Photos, Scene, Review.
- iPhone 17 Pro Max Light/Dark: Home, Photos, Scene, Review.
- iPhone 17e’de seçilmiş araç ekranı ve Review XXXL screenshot’ı.

Bu fixture’larda gerçek araç yerine Outdoor Scenic fixture görüntüsü kullanılıyor; bunlar UI/layout kanıtıdır, segmentasyon veya kompozit görsel kalite kanıtı değildir.

## Release ve yetki sınırları

- Mevcut Xcode: 27.2; SDK 27.2. Apple upload şartını gerçek upload gününde tekrar kontrol et.
- Signing identity yerel makinede bulundu. Archive’in Team/ID bilgisi doğrulandı.
- App Store Connect app record ve upload bu oturumda yapılmadı. Kullanıcı ayrıca açıkça yetki vermeden açma/yükleme.
- Cloud provider/backend yok. İlk beta yerel işleme tasarımıdır. Koşullu cloud fallback düşünülürse backend’de proje başına hard limit iki billable operation, idempotency ve explicit photo consent olmadan yazılmamalı.
- App Store subtitle: gerçek segmentasyon akışı kaliteli ve release build’de mevcutsa “AI Car & Moto Listing Photos”; aksi halde “Car & Moto Listing Photos.”
- Digital Clean, accounts, dealer dashboard, marketplace integrations ve billing beta kapsamı dışında.

## İlk yapılacaklar

1. `PhotoFileStore.storeOriginal` kaynağı byte-exact saklayacak şekilde düzelt ve crop/normalize’ı derivative path’e taşı.
2. Aynı 6 unit test + UI testlerini yeniden çalıştır; source hash/metadata/original-dimensions testleri ekle.
3. Kullanıcıdan gerçek fotoğraf korpusunu alıp Vision örneklerini araç türü, boya, yansıma ve ince parça etiketleriyle incele; ölçümleri yazılı raporla.
4. Review Light iPhone 17 Pro Max dahil screenshot çiftlerini görsel incele; siyah araç Dark, beyaz araç Light gerçek inputlarla yeni screenshot al.
5. Fiziksel iPhone bağlantısını doğrula, cihaz/iOS sürümünü yaz ve iki araç türü için capture/import-to-five-JPEG akışını test et.
6. İzin retleri, relaunch, partial processing, failed export, düşük depolama, cancellation, taslak silme ve Photos save authorization senaryolarını ekle/test et.
7. Privacy/support bilgilerini tamamla; metadata/data-flow ve privacy manifest’i gerçek kodla eşleştir.
8. Son koddan yeni Release archive oluşturup imzayı doğrula. App Store Connect/TestFlight yalnız ayrıca yetkilendirilince.

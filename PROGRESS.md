# AxleBackdrop — İlerleme özeti

Son güncelleme: 2026-11-16. Bu çalışma ağacında native iOS beta prototipi ve görsel QA çıktıları var; değişiklikler commit edilmedi. Claude için ayrıntılı devir notu: [`CLAUDE_HANDOFF.md`](CLAUDE_HANDOFF.md).

## Tamamlananlar

- SwiftUI/SwiftData uygulama iskeleti ve Home → araç türü → Photos → Scene → Processing → Review/Export akışı eklendi.
- Car ve Motorcycle için beş fotoğraf yuvası, angle guide, Photos import/kamera arayüzü, iki yerleşik scene, custom dealer template ve iki açı placement preview eklendi.
- Vision foreground mask + Core Image kompozit, detay fotoğraflarında hafif düzeltme, metadata temizleme, Original/Edited karşılaştırma ve beş JPEG save/share akışı eklendi.
- System/Light/Dark görünüm, renk token’ları, String Catalog, privacy manifest taslağı ve uygulama ikon/scene asset’leri eklendi.
- Unit/UI testleri ve DEBUG screenshot seed argümanları eklendi.
- QA: iPhone 17e ve iPhone 17 Pro Max boyutlarında Home, Photos, Scene, Review Light/Dark screenshot’ları `QA/Screenshots/` altında. XXXL Review yerleşimi bir tur düzeltildi.
- Test kanıtı: iPhone 17e simülatöründe 6/6 unit test ve Motorcycle → Photos UI testi geçti. Generic Debug simulator build ve generic Release device build geçti.
- `/tmp/AxleBackdrop.xcarchive` imza doğrulaması geçmiş bir archive mevcut; son koddan önce üretildiği için release kanıtı sayılmamalı.

## Kritik açıklar

1. `PhotoFileStore.storeOriginal` kaynağı yeniden encode edip 4:3 center-crop ediyor. Önce byte-exact kaynak saklama ve ayrı derivative pipeline yapılmalı.
2. Segmentation gerçek araç fotoğraflarıyla doğrulanmadı; motor ayrıntıları ve otomobil cam/yansıma kenarlarında kalite riski var. “AI” store subtitle’ını kalite kapısı geçmeden kullanma.
3. Fiziksel iPhone testi yok; kamera, izin reddi, relaunch recovery, kesinti, düşük depolama, cancellation ve gerçek export uçtan uca kanıtlanmadı.
4. Privacy policy URL, Support URL ve doğrulanmış destek e-postası eksik. Yeni archive/TestFlight yüklemesi yapılmadı.

Öncelik ve komutlar için [`CLAUDE_HANDOFF.md`](CLAUDE_HANDOFF.md) içindeki “İlk yapılacaklar” ve “Hızlı başlangıç” bölümlerine bak. Generated assets ve taslak TestFlight metinleri sırasıyla `AxleBackdrop/Resources/Provenance/GENERATED_ASSETS.md` ve `Release/TestFlightMetadata.md` içinde.

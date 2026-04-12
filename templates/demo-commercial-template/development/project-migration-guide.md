# Project Migration Guide

Bu belge, mevcut tekil bir projeyi demo / commercial workspace yapisina donusturmek icin kullanilir.

## Hedef

Tek bir kod tabanindan:

- public paylasima uygun bir `demo` repo
- private ve tam kapsamli bir `commercial` repo
- local ve operasyon odakli bir `development` alani

uretmek.

## 1. Hazirlik

- Kaynak projeyi dondurun veya gecis sirasinda degisim kontrolu uygulayin
- Mevcut klasor yapisinin envanterini cikarın
- Ortak, demo-uygun ve commercial-ozel bolumleri etiketleyin

## 2. Siniflandirma

Her dosya veya klasor icin su sorulari yanitlayin:

- Public paylasima uygun mu?
- Musteri, lisans veya gizli bilgi iceriyor mu?
- Demo deneyimi icin gerekli mi?
- Commercial urun icin zorunlu mu?

Siniflandirma sonucu su karar tiplerinden biri verilmelidir:

- `demo + commercial`
- `commercial only`
- `development only`
- `archive / remove`

## 3. Workspace Kurulumu

1. Base template'i yeni workspace'e kopyalayin
2. Uygun stack overlay'ini secin
3. `demo/` ve `commercial/` icinde ayri git repo baslatin
4. Workspace koku git ile izlenecekse `development/` klasorunu ignore edin

## 4. Dosya Tasima Kurallari

### Demo
- Sadece gosterim icin gerekli kod ve varliklari tasiyin
- Ticari deger ureten ancak public olmamasi gereken modulleri tasimayin
- Ornek veri kullanin

### Commercial
- Tam yetenek setini koruyun
- Gizli konfigurasyonlari source control yerine guvenli dagitim kanali ile yonetin
- Musteri veya urun operasyon notlarini repo-ozel belgelerde tutun

### Development
- Gecis notlari
- kontrol listeleri
- manuel takip maddeleri
- karar kayitlari

## 5. Dogrulama

- Demo repo temiz ortamda calisiyor mu?
- Commercial repo kendi bagimliliklariyla calisiyor mu?
- Demo icinde gizli veya lisansli icerik kaldi mi?
- README ve docs ayrimi net mi?
- Iki repo da ayri release akisi ile yonetilebilir mi?

## 6. Cikis Kriterleri

Gecis tamamlanmis sayilmasi icin:

- `demo` publice hazir olmali
- `commercial` private teslime hazir olmali
- `development` operasyon notlariyla doldurulmus olmali
- ekip hangi dosyanin neden hangi repoda oldugunu acikca bilmeli
# ⚡ Hızlı Başvuru Kartı

## 🎯 3 Saniyede Anlat

**Kategori sistemi tamamlandı!**
- ✅ Kategori seçimi (Settings)
- ✅ Oyunda kategori filtrelemesi
- ✅ Kelime eklerken kategori seçimi
- ✅ Kategori yönetimi
- ✅ 0 derleme hatası

---

## 🚀 Hemen Başla

### 1. Dosyaları Kopyala
```
✓ settings_screen.dart (güncellendi)
✓ words_screen.dart (güncellendi)
✓ database_helper.dart (güncellendi)
✓ category_management_screen.dart (yeni)
```

### 2. Derle
```bash
flutter pub get
flutter run
```

### 3. Test Et
```
Ayarlar → Kategori Seçimi → Kategori seç → Kaydet
Kelimeler → [+] → Kategori seç → Ekle
Oyun → Seçli kategorilerden kelimeler gelir ✓
```

---

## 📝 API Cheatsheet

### Kategori Operasyonları
```dart
// Kategorileri al
final cats = await DatabaseHelper().getCategories();

// Sayıları al
final counts = await DatabaseHelper().getCategoryCounts();

// Seçli kategorilerden kelimeleri al
final words = await DatabaseHelper()
    .getActiveWordsByCategories(['Spor', 'Hayvan']);

// Kategorideki kelimeleri al
final sportWords = await DatabaseHelper()
    .getWordsInCategory('Spor');

// Kategori ismi değiştir
await DatabaseHelper()
    .updateCategoryName('Spor', 'Spor Aktiviteleri');

// Kategori ile kelime ekle
await DatabaseHelper().addWord(
  'FUTBOL',
  ['Futbol', 'Oyun', 'Top'],
  category: 'Spor'
);
```

### SharedPreferences
```dart
// Seçili kategorileri oku
final selected = await prefs.getStringList('selectedCategories') ?? [];

// Kaydet
await prefs.setStringList('selectedCategories', ['Spor', 'Hayvan']);

// Boş = Genel Karışık
if (selected.isEmpty) {
  // Tüm kategoriler
}
```

---

## 🧭 Navigasyon Haritası

```
Ana Ekran
├─ [⚙️ Ayarlar]
│  ├─ Kategori Seçimi
│  │  └─ [Kategori Yönetimi]
│  │     ├─ Kategorileri listele
│  │     ├─ Kelimeleri göster
│  │     └─ İsim değiştir
│  └─ Diğer ayarlar
├─ [📚 Kelimeler]
│  ├─ Kelimeler listesi (kategori gösterilir)
│  └─ [+] Yeni Kelime (kategori seç)
├─ [Oyun Başla]
│  └─ Seçili kategorilerden kelimeler
└─ Diğer menüler
```

---

## ✅ Kontrol Listesi

**Kurulum:**
- [ ] Dosyaları kopyaladın
- [ ] Flutter pub get yaptın
- [ ] Derlemede hata yok

**Test:**
- [ ] Kategori seç yapabiliyorsun
- [ ] Kelime eklerken kategori seçebiliyorsun
- [ ] Oyunda seçili kategorilerden kelimeler geliyor
- [ ] Kategori yönetimini açabiliyorsun

**Bitirme:**
- [ ] Excel import metodunu ekledin (isteğe bağlı)
- [ ] Test oyunu oynadın
- [ ] Bir konu var mı? Kontrol et!

---

## 🆘 Sorun Giderme

### Derlememe hatası
```
❌ Error: ... 
✅ Çözüm: flutter pub get && flutter clean && flutter pub get
```

### Kategoriler görünmüyor
```
❌ Problem: Settings'te kategori yok
✅ Çözüm: 
  1. Database'de kelime var mı? 
  2. category sütunu var mı?
  3. Kelimeler is_active=1 mi?
```

### Oyunda kelime gelmez
```
❌ Problem: Seçili kategoriler boşsa
✅ Çözüm:
  1. Ayarlar → Kategori Seçimi
  2. En az 1 kategori seç
  3. Kaydet ve çık
  4. Oyun başla
```

### Kategori ismi değişmiyor
```
❌ Problem: updateCategoryName çalışmıyor
✅ Çözüm:
  1. Kategori adını doğru yaz
  2. Boş kategori işlem yap
  3. DB'ye yazma izni var mı?
```

---

## 📊 Tek Bakışta Bilgiler

| Özellik | Durum | Dosya |
|---------|-------|-------|
| Kategori seçimi | ✅ | settings_screen.dart |
| Oyun filtrelemesi | ✅ | game_screen.dart |
| Yeni kelime + kategori | ✅ | words_screen.dart |
| Kategori yönetimi | ✅ | category_management_screen.dart |
| Database metodları | ✅ | database_helper.dart |
| Derleme hatası | ✅ 0 | - |

---

## 💡 Pro Tips

1. **Kategori isimleri:** Boşluk yoksa daha temiz görünür
   ```
   ✓ İyi: Spor, Hayvan, İçecek
   ✗ Kötü: Spor Türleri, Hayvan Adları
   ```

2. **Excel import:** Kategori sütununu mutlaka ekle
   ```
   word | forbidden_words | category
   FUTBOL | Futbol,Oyun | Spor
   ```

3. **Performance:** 1000+ kelime varsa index'i kontrol et
   ```sql
   CREATE INDEX idx_words_category_active 
     ON words(category, is_active);
   ```

4. **Debug:** SharedPreferences'ı kısaca kontrol et
   ```dart
   final prefs = await SharedPreferences.getInstance();
   print(prefs.getStringList('selectedCategories')); // [Spor, Hayvan]
   ```

---

## 🎯 Sonraki Adımlar (İsteğe Bağlı)

- [ ] Excel import'u ekle (kategori alanı)
- [ ] Kategori resimleri ekle
- [ ] Kategori istatistikleri göster
- [ ] Kategori başına rekoru tut
- [ ] Kategori zorluğu ayarla

---

## 📞 Önemli Sabitler

```dart
// SharedPreferences Key
const KEY_SELECTED_CATEGORIES = 'selectedCategories';

// Default Kategori
const DEFAULT_CATEGORY = 'Genel';

// Database Tablo Adı
const TABLE_WORDS = 'words';

// Kategori Sütunu
const COLUMN_CATEGORY = 'category';
```

---

## 🔗 İlgili Dosyalar

Tam dokümantasyon:
- [OKUMA_BENI.md](OKUMA_BENI.md) - Başlangıç
- [KOD_DEGISIKLIKLERI_OZETI.md](KOD_DEGISIKLIKLERI_OZETI.md) - Detaylar
- [KATEGORI_VE_KELIME_YONETIMI.md](KATEGORI_VE_KELIME_YONETIMI.md) - Tasarım
- [PAKET_OZETI.md](PAKET_OZETI.md) - Özet

---

## ✨ Hepsi Hazır!

```
⚙️  → Kategori seçimi
📚  → Yeni kelime (kategori seçli)
🎮  → Oyun (filtreli kelimeler)
⚙️  → Kategori yönetimi
✅  → 0 Hata
🚀  → Hazır kullanıma!
```

**İyi Eğlenceler! 🎉**


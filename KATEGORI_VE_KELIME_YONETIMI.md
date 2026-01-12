# 📚 Kategori ve Kelime Yönetimi Sistemi

## 🎯 Özet

Komplet kategori yönetim sistemi:
- ✅ **Kategori Seçimi** (Settings) - Ayarlardan kategorileri seç
- ✅ **Kategori Başına Kelime Sayısı** - Her kategoride kaç kelime olduğunu gör
- ✅ **Seçli Kategorilerden Kelime Çekme** - Oyunda seçili kategorilerden kelimeler gelir
- ✅ **Yeni Kelime Eklerken Kategori Belirleme** - Kelime eklerken kategori seç
- ✅ **Kategori Yönetimi** - Kategorileri düzenle, isim değiştir, kelimeleri gör

---

## 📂 Dosya Yapısı

### Mevcut Dosyalar (Güncellendi)
1. **[settings_screen.dart](lib/settings_screen.dart)** ✅
   - Kategori seçim UI
   - Genel Karışık toggle
   - Kategori başına kelime sayısı gösterimi
   - SharedPreferences'a kaydetme

2. **[game_screen.dart](lib/game_screen.dart)** ✅
   - SharedPreferences'tan kategori okuması
   - Seçli kategorilerden filtrelenmiş kelime çekme
   - fetchWordsFromDatabase() metodu güncellendi

3. **[words_screen.dart](lib/words_screen.dart)** ✅ GÜNCELLENDI
   - Yeni kelime eklerken kategori seçimi (Dropdown)
   - Kelimeler listesinde kategori görüntüleme
   - _showAddWordDialog() güncellendi
   - _addWord() metodu kategori parametresi alıyor

4. **[database_helper.dart](lib/database_helper.dart)** ✅ GÜNCELLENDI
   - `addWord(word, forbiddenWords, {category})` - Kategori parametresi
   - `updateWord(id, word, forbiddenWords, {category})`
   - `getCategories()` - Tüm kategorileri getir
   - `getCategoryCounts()` - Kategori başına kelime sayısı
   - `getActiveWordsByCategories()` - Filtreli kelime çekme
   - **YENİ:** `getWordsInCategory(categoryName)` - Kategorideki tüm kelimeleri getir
   - **YENİ:** `updateCategoryName(oldName, newName)` - Kategori ismi değiştir

### YENİ Dosyalar
1. **[category_management_screen.dart](lib/category_management_screen.dart)** ✨ YENİ
   - Tüm kategorileri listele
   - Kategori başına kelime sayısı göster
   - Kategorideki kelimeleri görüntüle
   - Kategori ismi değiştir

2. **[models/category.dart](lib/models/category.dart)** ✨ (Önceden oluşturulmuş)
   - Category model sınıfı

---

## 🔄 Veri Akışı

### 1. Kategori Seçimi (Settings Ekranı)
```
SettingsScreen → SharedPreferences.getStringList('selectedCategories')
    ↓
    Kategorileri listele (DB'den getCategories())
    ↓
    Kullanıcı seçim yap (SwitchListTile + FilterChip)
    ↓
    SharedPreferences.setStringList('selectedCategories', selectedList)
```

### 2. Oyun Başlama (Game Ekranı)
```
GameScreen.initState() → fetchWordsFromDatabase()
    ↓
    SharedPreferences'tan selectedCategories oku
    ↓
    getActiveWordsByCategories(selectedCategories) → DB sorgula
    ↓
    Filtrelenmiş kelimeler gelir → shuffle → setState
```

### 3. Yeni Kelime Ekleme (Words Ekranı)
```
WordsScreen → _showAddWordDialog()
    ↓
    Kategori Dropdown (getCategories() ile doldur)
    ↓
    Kullanıcı: Kelime + Yasaklılar + KATEGORİ gir
    ↓
    _addWord(word, forbiddenWords, category)
    ↓
    DatabaseHelper.addWord(word, forbiddenWords, category: category)
```

### 4. Kategori Yönetimi (Category Management Ekranı)
```
CategoryManagementScreen → _loadCategories()
    ↓
    getCategoryCounts() → Map<String, int> al
    ↓
    ListTile listesi: [Kategori Adı] [Kelime Sayısı] [Butorlar]
    ↓
    Kelimeleri Göster → getWordsInCategory(categoryName)
    ↓
    Kategori İsmini Değiştir → updateCategoryName(old, new)
```

---

## 🧪 Test Senaryoları

### Senaryo 1: Genel Karışık Seçimi
```
1. Settings → Kategori Seçimi
2. "Genel Karışık" toggle ON
3. Oyun başla
✓ Sonuç: TÜM kategorilerden kelimeler gelir (karışık)
```

### Senaryo 2: 1 Kategori Seçimi
```
1. Settings → Kategori Seçimi
2. "Genel Karışık" toggle OFF
3. Sadece "Spor" seç
4. Oyun başla
✓ Sonuç: Sadece Spor kategorisinden kelimeler gelir
```

### Senaryo 3: Çok Kategori Seçimi
```
1. Settings → Kategori Seçimi
2. "Genel Karışık" toggle OFF
3. "Spor", "Hayvan", "İçecek" seç
4. Oyun başla
✓ Sonuç: 3 kategorinin karışık kelimeleri gelir
```

### Senaryo 4: Yeni Kelime Ekleme
```
1. Words Screen → + (Add)
2. Kelime: "AYAKKABI"
3. Yasaklı: "Ayakkabı", "Giyim", "Giydirme"
4. Kategori: "Giyim" seç
5. Ekle
✓ Sonuç: Kelime "Giyim" kategorisine eklenir
✓ Kelimeler listesinde kategori gösterilir
```

### Senaryo 5: Kategori Yönetimi
```
1. Settings → Kategori Yönetimi (ekle gerekirse)
2. Tüm kategorileri gör + kelime sayıları
3. "Spor" kategorisini tıkla → Kelimeleri gör
4. "Spor" ismi değiştir → "Spor Aktiviteleri"
✓ Sonuç: Kategorinin ismi değişir, tüm kelimeler yeni isimle taşınır
```

---

## 📊 Database Schema

```sql
CREATE TABLE words (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT UNIQUE NOT NULL,
  forbidden_words TEXT,
  category TEXT DEFAULT 'Genel',  ← KATEGORİ ALANI
  is_active INTEGER DEFAULT 1,
  created_by TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- İndeks: Kategori alanında hızlı sorgu
CREATE INDEX idx_words_category_active 
  ON words(category, is_active);
```

---

## 🔌 API Referansı

### DatabaseHelper Metodları

#### `getCategories()` → List<String>
```dart
final categories = await DatabaseHelper().getCategories();
// ['Spor', 'Hayvan', 'İçecek', ...]
```

#### `getCategoryCounts()` → Map<String, int>
```dart
final counts = await DatabaseHelper().getCategoryCounts();
// {'Spor': 45, 'Hayvan': 32, 'İçecek': 28, ...}
```

#### `getActiveWordsByCategories(List<String>? categories)` → List<Map>
```dart
// Tüm kategoriler
final allWords = await DatabaseHelper()
    .getActiveWordsByCategories(null);

// Seçli kategoriler
final selectedWords = await DatabaseHelper()
    .getActiveWordsByCategories(['Spor', 'Hayvan']);
```

#### `getWordsInCategory(String categoryName)` → List<Map>
```dart
final sportWords = await DatabaseHelper()
    .getWordsInCategory('Spor');
```

#### `updateCategoryName(String oldName, String newName)` → void
```dart
await DatabaseHelper()
    .updateCategoryName('Spor', 'Spor Aktiviteleri');
```

#### `addWord(String word, List<String> forbiddenWords, {String category})`
```dart
await DatabaseHelper().addWord(
  'FUTBOL',
  ['Futbol', 'Oyun', 'Top'],
  category: 'Spor',
);
```

---

## 🎨 UI Bileşenleri

### Settings Ekranında Kategori Seçimi
```
┌─────────────────────────────────┐
│ KATEGORİ SEÇİMİ                │
├─────────────────────────────────┤
│ ☑ Genel Karışık                │
│                                 │
│ Aktif Kategoriler:              │
│ [Spor (45)] [Hayvan (32)]      │
│ [İçecek (28)] [Ülke (50)]      │
│                                 │
│           [KAYDET]             │
└─────────────────────────────────┘
```

### Words Ekranında Kelime Ekleme
```
Yeni Kelime Ekle
├─ Kelime: [AYAKKABI]
├─ Kategori: [Giyim ▼]
├─ Yasaklı Kelime 1: [Ayakkabı]
├─ Yasaklı Kelime 2: [Giyim]
├─ Yasaklı Kelime 3: [Giydirme]
└─ [İPTAL] [EKLE]
```

### Kelimeler Listesinde Kategori Gösterimi
```
┌─────────────────────────────────┐
│ 1  FUTBOL                       │
│    Yasaklı: Futbol, Oyun, Top  │
│    Kategori: Spor               │ ← Eklenmiş
└─────────────────────────────────┘
```

### Kategori Yönetim Ekranı
```
┌─────────────────────────────────┐
│ 1  Spor                         │
│    45 kelime                    │
│    [👁] [✏️]                    │
├─────────────────────────────────┤
│ 2  Hayvan                       │
│    32 kelime                    │
│    [👁] [✏️]                    │
└─────────────────────────────────┘
```

---

## 🔑 SharedPreferences Keys

```dart
// Kategori Seçimi
'selectedCategories' → List<String>

// Örnek:
[] // Boş = Genel Karışık
['Spor'] // 1 kategori
['Spor', 'Hayvan'] // Çok kategori
```

---

## ⚡ Hızlı Başlangıç

### 1. Settings'te Kategori Seç
```
Ana Menü → Ayarlar → Kategori Seçimi
→ Istediğin kategorileri seç
→ KAYDET
```

### 2. Kelime Ekle
```
Ana Menü → Kelimeler → + 
→ Kelime gir
→ Kategori seç (Dropdown'dan)
→ Yasaklıları gir
→ EKLE
```

### 3. Kategori Yönet
```
Ana Menü → Ayarlar → Kategori Yönetimi
→ Kategorileri gör
→ İsim değiştir / Kelimeleri gör
```

### 4. Oyun Oyna
```
Ana Menü → Oyun Başla
→ Seçili kategorilerden kelimeler gelir ✓
```

---

## 🛠️ Teknik Detaylar

### Kategori Normalizasyonu
- Boş kategoriler → 'Genel' dönüştürülür
- Baştaki/sondaki boşluklar → TRIM ile temizlenir
- COLLATE NOCASE → Case-insensitive sıralama

### Performance
- Database indexi: `category, is_active`
- GROUP BY queries optimize edilmiş
- DISTINCT queries SELECT DISTINCT TRIM(category) ile

### Hata Handling
- Null kategori → 'Genel' atanır
- Boş liste → tüm kategoriler kullanılır
- DB hatası → UI'da SnackBar ile gösterilir

---

## ✅ Kontrol Listesi

- [x] Kategori seçim UI (Settings)
- [x] Kategori başına kelime sayısı
- [x] Oyunda kategori filtreleme
- [x] Yeni kelime eklerken kategori
- [x] Kelimeleri listede kategori gösterme
- [x] Kategori yönetim ekranı
- [x] Kategori ismi değiştirme
- [x] Kategorideki kelimeleri listeleme
- [x] Database metodları
- [x] Error handling
- [x] Hatasız derleme

---

## 📞 Önemli Notlar

1. **Excel Import** - Kullanıcı ekleyecek (kategori alanı eksik)
2. **Default Kategori** - 'Genel' veya diğerleri olabilir
3. **Backward Compat** - Eski veriler 'Genel' kategorisine atanır
4. **SharedPreferences** - selectedCategories boş = tüm kategoriler


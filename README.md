# ბტკ საველე აპლიკაცია · BTC Field App

<div align="center">

**ივანე ჯავახიშვილის სახ. თბილისის სახელმწიფო უნივერსიტეტი**  
**ალ. ასლანიკაშვილის სახ. საქართველოს კარტოგრაფთა ასოციაცია**

[![Deploy Web](https://github.com/Georgian-Cartographers-Association/btk-field-app/actions/workflows/pages.yml/badge.svg)](https://github.com/Georgian-Cartographers-Association/btk-field-app/actions/workflows/pages.yml)
[![Release APK](https://github.com/Georgian-Cartographers-Association/btk-field-app/actions/workflows/release.yml/badge.svg)](https://github.com/Georgian-Cartographers-Association/btk-field-app/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.7-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

🌐 **[btc.qgis.ge](https://btc.qgis.ge)** · 📱 [ჩამოტვირთვა (APK)](https://github.com/Georgian-Cartographers-Association/btk-field-app/releases)

</div>

---

## 🔬 რა არის ბტკ?

> **ბტკ = ბუნებრივ-ტერიტორიული კომპლექსი**  
> **BTC = Balanced Territorial Complex** *(ასევე: Biogeophysical Territorial Complex / Background Territorial Complex — კონკრეტული სამეცნიერო სკოლის მიხედვით)*

ლანდშაფტურ-გეოფიზიკურ კვლევაში **ბუნებრივ-ტერიტორიული კომპლექსი** წარმოადგენს ბუნებრივი გარემოს ფუნდამენტურ სტრუქტურულ ერთეულს — ტერიტორიის ის ნაწილი, სადაც **რელიეფი, ნიადაგი, მცენარეულობა, ჰიდროლოგია და მიკროკლიმატი** ერთიან, ურთიერთდაკავშირებულ სისტემას ქმნიან.

**ბტკ საველე აპლიკაცია** — პროგრამა, რომელიც გამიზნულია **უშუალოდ მინდორზე (ველზე)**:

| 🗺️ | ბუნებრივ-ტერიტორიული კომპლექსების კომპონენტების **დასაფიქსირებლად** |
|---|---|
| 📡 | გეოფიზიკური გაზომვების **დასაკავშირებლად** |
| 📐 | ლანდშაფტური პროფილების **ასაგებად** |
| 📋 | საველე ბლანკების **შევსებისა და გაგზავნისთვის** |

---

## ✨ ფუნქციები

<table>
<tr>
<td width="50%">

### 🗺️ ინტერაქტიული რუკა
- **OpenStreetMap** — საბაზისო
- **OpenTopoMap** — ტოპოგრაფიული overlay
- **საქართველოს ჩარჩო** — GeoJSON საზღვარი
- შრეების ჩართვა/გამორთვა

### 📍 საველე წერტილები
- GPS-ით ან ხელით კოორდინატები
- უნიკალური ID ყოველ წერტილს
- ჩანაწერების სია და ფილტრაცია

### 🛰️ ლოკალური რასტრული რუკები
- ნიადაგის, ლანდშაფტის, რელიეფის
- Bounding Box კოორდინატებით
- გამჭვირვალობის მართვა

</td>
<td width="50%">

### 📋 ბტკ ბლანკი (6 სექცია)
1. **ძირითადი** — ID, თარიღი, კოორდ.
2. **ფიზ.გეოგ.** — გეოლ., რელიეფი, მიგრ.
3. **მცენარეულობა** — იარუსი, სახეობა
4. **ნიადაგი** — ტიპი, ჰორიზონტები
5. **გეომასა** — პედო/ლითო/ჰიდრო/ფიტო
6. **ვ.სტრუქტურა** — ვერტ. პროფილი

### 📄 მეთოდური მითითება
- ჩაშენებული PDF viewer (164 გვ.)
- გვერდის პოზიციის დამახსოვრება
- კოპირება + ბლანკში ჩასმა

### 📤 ექსპორტი & გაგზავნა
- **CSV** — Excel/Google Sheets
- **PDF** — ქართული ფონტით (Noto Sans)
- **ელ-ფოსტა** — mailto + copy-paste

</td>
</tr>
</table>

### 🌓 ღია / მუქი ფონი &nbsp;·&nbsp; 🇬🇪 ქართული / 🇬🇧 English

---

## 🚀 გაშვება

### ვებ (ბრაუზერი)
**[btc.qgis.ge](https://btc.qgis.ge)** — ინსტალაციის გარეშე

### Android APK
1. [Releases](https://github.com/Georgian-Cartographers-Association/btk-field-app/releases)-დან ჩამოტვირთეთ `app-release.apk`
2. Settings → Install unknown apps → ჩართეთ
3. APK გაუშვით

### Development
```bash
git clone https://github.com/Georgian-Cartographers-Association/btk-field-app.git
cd btk-field-app
flutter pub get
flutter gen-l10n
flutter run
```

#### Build
```bash
flutter build apk --release          # Android
flutter build windows --release      # Windows Desktop
flutter build web --release          # Web
```

---

## 🏗️ არქიტექტურა

```
lib/
├── main.dart + app.dart             # Entry point, MaterialApp, theming
├── core/constants.dart              # Tile URLs, Georgia center, pref keys
├── models/
│   ├── btk_record.dart              # სრული ბტკ data model (JSON)
│   └── raster_layer.dart            # ლოკალური რასტრი + bounding box
├── providers/                       # Riverpod state
│   ├── btk_provider.dart            # ბტკ CRUD
│   ├── map_provider.dart            # Layer toggles
│   ├── raster_provider.dart         # Raster overlay management
│   └── settings_provider.dart      # Theme, locale, email, PDF page
├── screens/
│   ├── map/                         # OSM+Topo+Raster map, BTC markers
│   ├── form/                        # 6-tab BTC form + PDF split view
│   ├── pdf/                         # Syncfusion PDF viewer
│   ├── raster/                      # Local raster manager
│   ├── records/                     # Saved records + export
│   └── settings/                   # Theme, language, email settings
├── services/
│   └── export_service.dart          # CSV + PDF generation
└── l10n/                            # ARB localizations (ka/en)
```

---

## 🛠️ Tech Stack

| Package | მიზანი |
|---------|--------|
| `flutter_map` | OSM / OpenTopoMap tile rendering |
| `flutter_riverpod` | State management |
| `syncfusion_flutter_pdfviewer` | PDF viewing (164-page methodology) |
| `geolocator` | GPS coordinates |
| `file_picker` | Local raster image import |
| `pdf` + `printing` | PDF export with Noto Sans Georgian |
| `share_plus` | Share CSV/PDF (mobile, web, desktop) |
| `shared_preferences` | Local JSON storage |
| `google_fonts` | Noto Sans Georgian UI font |
| `flex_color_scheme` | Material 3 theming |
| `url_launcher` | Email via mailto |

---

## ⚙️ CI/CD

| Workflow | Trigger | Output |
|----------|---------|--------|
| **Release APK** | `git tag v*` | APK → GitHub Releases |
| **Deploy Web** | push to `main` | Flutter web → GitHub Pages |

```bash
# APK release
git tag v1.0.0 && git push origin v1.0.0
```

---

## 📚 ლიტერატურა

- ბერუჩაშვილი ნ. *საველე ლანდშაფტურ-გეოფიზიკური კვლევა და ლანდშაფტური კარტოგრაფირება.* თბ., 2024
- ბერუჩაშვილი ნ. *ბუნებრივ-ტერიტორიული კომპლექსების ლანდშაფტურ-გეოფიზიკური კვლევისა და მდგომარეობათა კარტოგრაფირების მეთოდიკა.* თბ., 1983
- გორდეზიანი თ. *ლანდშაფტური კარტოგრაფიის თეორიული საფუძვლები.* თბ., 2014

---

<div align="center">

გამოქვეყნდა [Georgian Cartographers Association](https://github.com/Georgian-Cartographers-Association) · 2024–2025

</div>

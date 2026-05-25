# BTC Field App — ბტკ საველე აპლიკაცია

**ივანე ჯავახიშვილის სახ. თბილისის სახელმწიფო უნივერსიტეტი**  
**ალ. ასლანიკაშვილის სახ. საქართველოს კარტოგრაფთა ასოციაცია**

Flutter-ზე დაფუძნებული მობილური/desktop/web აპლიკაცია საველე ლანდშაფტურ-გეოფიზიკური კვლევისთვის (ბუნებრივ-ტერიტორიული კომპლექსების კვლევა).

---

## ფუნქციები

- 🗺️ **ინტერაქტიული რუკა** — OSM + OpenTopoMap, საქართველოს ჩარჩო
- 📍 **ბტკ წერტილები** — GPS-ის ან ხელით კოორდინატებით, უნიკალური ID
- 📋 **ბტკ ბლანკი** — სრული საველე ბლანკის შევსება (6 სექცია)
- 📄 **PDF მეთოდიკა** — ჩაშენებული PDF viewer გვ. დამახსოვრებით, კოპირება
- 📧 **გაგზავნა** — შევსებული ბლანკის ელ-ფოსტით გაგზავნა
- 🌓 **ღია/მუქი ფონი** — ნაგულისხმევი ღია
- 🇬🇪🇬🇧 **ქართული/ინგლისური** — ნაგულისხმევი ქართული

## შრეები

| შრე | აღწერა |
|-----|--------|
| OpenStreetMap | საბაზისო |
| OpenTopoMap | ტოპოგრაფიული (overlay) |
| საქართველოს საზღვარი | GeoJSON polygon |
| ბტკ წერტილები | შენახული ჩანაწერები |

## ბტკ ბლანკის სექციები

1. **ძირითადი** — ID, თარიღი, ადგილმდებარეობა, კოორდინატები
2. **ფიზ.გეოგ.** — გეოლ. ფორმაცია, რელიეფი, მიგრ. რეჟიმი, დატენიანება
3. **მცენარეულობა** — ცხრილი (იარუსი, სიმ., სახეობა)
4. **ნიადაგი** — ტიპი, პროფილი, გენეტ. ჰორიზონტები
5. **გეომასა** — პედო-, ლითო-, ჰიდრო-, ფიტომასა + ხე-მც. ფიტომასა
6. **ვ.სტრ.** — ბტკ ვერტიკალური სტრუქტურა

## Build

```bash
# Android APK
flutter build apk --release

# Windows Desktop
flutter build windows --release

# Web
flutter build web --release
```

## Development Setup

```bash
git clone https://github.com/Georgian-Cartographers-Association/btk-field-app
cd btk-field-app
flutter pub get
flutter gen-l10n
flutter run
```

## Assets

- `assets/pdf/methodology.pdf` — „საველე ლანდშაფტურ-გეოფიზიკური კვლევა და ლანდშაფტური კარტოგრაფირება" (ნ. ბერუჩაშვილი, 2024)
- `assets/geojson/georgia.geojson` — საქართველოს საზღვარი

## Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_map` | OSM/OpenTopo tile map |
| `flutter_riverpod` | State management |
| `syncfusion_flutter_pdfviewer` | PDF viewing |
| `geolocator` | GPS coordinates |
| `shared_preferences` | Local storage (JSON) |
| `google_fonts` | Noto Sans Georgian font |
| `flex_color_scheme` | Material 3 theming |
| `url_launcher` | Email sending via mailto |

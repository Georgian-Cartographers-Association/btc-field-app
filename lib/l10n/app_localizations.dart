import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';

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
    Locale('en'),
    Locale('ka'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ საველე აპლიკაცია'**
  String get appTitle;

  /// No description provided for @mapTitle.
  ///
  /// In ka, this message translates to:
  /// **'რუკა'**
  String get mapTitle;

  /// No description provided for @addPoint.
  ///
  /// In ka, this message translates to:
  /// **'წერტილის დამატება'**
  String get addPoint;

  /// No description provided for @myLocation.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი მდებარეობა'**
  String get myLocation;

  /// No description provided for @layers.
  ///
  /// In ka, this message translates to:
  /// **'შრეები'**
  String get layers;

  /// No description provided for @methodology.
  ///
  /// In ka, this message translates to:
  /// **'მეთოდური მითითება'**
  String get methodology;

  /// No description provided for @records.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები'**
  String get records;

  /// No description provided for @settings.
  ///
  /// In ka, this message translates to:
  /// **'პარამეტრები'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In ka, this message translates to:
  /// **'შენახვა'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get delete;

  /// No description provided for @send.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნა'**
  String get send;

  /// No description provided for @email.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტა'**
  String get email;

  /// No description provided for @sendByEmail.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტით გაგზავნა'**
  String get sendByEmail;

  /// No description provided for @emailAddress.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტის მისამართი'**
  String get emailAddress;

  /// No description provided for @emailSent.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილია'**
  String get emailSent;

  /// No description provided for @copyToClipboard.
  ///
  /// In ka, this message translates to:
  /// **'კოპირება'**
  String get copyToClipboard;

  /// No description provided for @paste.
  ///
  /// In ka, this message translates to:
  /// **'ჩასმა'**
  String get paste;

  /// No description provided for @language.
  ///
  /// In ka, this message translates to:
  /// **'ენა'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ka, this message translates to:
  /// **'ფონი'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In ka, this message translates to:
  /// **'ღია'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ka, this message translates to:
  /// **'მუქი'**
  String get darkTheme;

  /// No description provided for @layerOsm.
  ///
  /// In ka, this message translates to:
  /// **'OpenStreetMap'**
  String get layerOsm;

  /// No description provided for @layerTopo.
  ///
  /// In ka, this message translates to:
  /// **'OpenTopoMap'**
  String get layerTopo;

  /// No description provided for @layerBoundary.
  ///
  /// In ka, this message translates to:
  /// **'საქართველოს საზღვარი'**
  String get layerBoundary;

  /// No description provided for @layerPoints.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ წერტილები'**
  String get layerPoints;

  /// No description provided for @btkFormTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ-ის აღწერა'**
  String get btkFormTitle;

  /// No description provided for @btkId.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ID'**
  String get btkId;

  /// No description provided for @date.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი'**
  String get date;

  /// No description provided for @location.
  ///
  /// In ka, this message translates to:
  /// **'ადგილმდებარეობა'**
  String get location;

  /// No description provided for @coordinates.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები'**
  String get coordinates;

  /// No description provided for @latitude.
  ///
  /// In ka, this message translates to:
  /// **'განედი (lat)'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In ka, this message translates to:
  /// **'გრძედი (lon)'**
  String get longitude;

  /// No description provided for @useGps.
  ///
  /// In ka, this message translates to:
  /// **'GPS-ით დადგენა'**
  String get useGps;

  /// No description provided for @enterManually.
  ///
  /// In ka, this message translates to:
  /// **'ხელით შეყვანა'**
  String get enterManually;

  /// No description provided for @physGeoDesc.
  ///
  /// In ka, this message translates to:
  /// **'ფიზიკურ-გეოგრაფიული დახასიათება'**
  String get physGeoDesc;

  /// No description provided for @geologicalFormation.
  ///
  /// In ka, this message translates to:
  /// **'გეოლოგიური ფორმაცია'**
  String get geologicalFormation;

  /// No description provided for @reliefType.
  ///
  /// In ka, this message translates to:
  /// **'რელიეფის ტიპი'**
  String get reliefType;

  /// No description provided for @morphologicalDesc.
  ///
  /// In ka, this message translates to:
  /// **'მორფოლოგიური დახასიათება'**
  String get morphologicalDesc;

  /// No description provided for @geomorphProcesses.
  ///
  /// In ka, this message translates to:
  /// **'თანამედროვე გეომორფოლოგიური პროცესები'**
  String get geomorphProcesses;

  /// No description provided for @migrationRegime.
  ///
  /// In ka, this message translates to:
  /// **'მიგრაციის რეჟიმი'**
  String get migrationRegime;

  /// No description provided for @moistureDegree.
  ///
  /// In ka, this message translates to:
  /// **'დატენიანების ხარისხი'**
  String get moistureDegree;

  /// No description provided for @vegetation.
  ///
  /// In ka, this message translates to:
  /// **'მცენარეულობა'**
  String get vegetation;

  /// No description provided for @vegTier.
  ///
  /// In ka, this message translates to:
  /// **'იარუსი'**
  String get vegTier;

  /// No description provided for @vegHeight.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლე'**
  String get vegHeight;

  /// No description provided for @vegDensity.
  ///
  /// In ka, this message translates to:
  /// **'სიმძლ.'**
  String get vegDensity;

  /// No description provided for @vegPhenophase.
  ///
  /// In ka, this message translates to:
  /// **'ფენოფაზა'**
  String get vegPhenophase;

  /// No description provided for @vegSpecies.
  ///
  /// In ka, this message translates to:
  /// **'სახეობა'**
  String get vegSpecies;

  /// No description provided for @addRow.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქონის დამატება'**
  String get addRow;

  /// No description provided for @removeRow.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქონის წაშლა'**
  String get removeRow;

  /// No description provided for @soil.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგი'**
  String get soil;

  /// No description provided for @soilTypeName.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის ტიპის სახელწოდება'**
  String get soilTypeName;

  /// No description provided for @soilProfileDesc.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის პროფილის მორფოლოგიური დახასიათება'**
  String get soilProfileDesc;

  /// No description provided for @soilHorizons.
  ///
  /// In ka, this message translates to:
  /// **'გენეტიკური ჰორიზონტები'**
  String get soilHorizons;

  /// No description provided for @soilHorizonName.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტი'**
  String get soilHorizonName;

  /// No description provided for @soilHorizonDesc.
  ///
  /// In ka, this message translates to:
  /// **'დახასიათება (ფ., მ.შ., სტ., ფ., სმ., ახ., ხ., ფ., ტ., ჰ., ქ.საზ.)'**
  String get soilHorizonDesc;

  /// No description provided for @geohorizonIndex.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰორიზონტის ინდექსი'**
  String get geohorizonIndex;

  /// No description provided for @soilSurfaceFormation.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგ ზედაპირული ფორმაციის ტიპი'**
  String get soilSurfaceFormation;

  /// No description provided for @geomasses.
  ///
  /// In ka, this message translates to:
  /// **'გეომასების კვლევა'**
  String get geomasses;

  /// No description provided for @geomassSection.
  ///
  /// In ka, this message translates to:
  /// **'სექცია'**
  String get geomassSection;

  /// No description provided for @geomassDepth.
  ///
  /// In ka, this message translates to:
  /// **'სიღრმე (სმ)'**
  String get geomassDepth;

  /// No description provided for @pedomass.
  ///
  /// In ka, this message translates to:
  /// **'პედომასა'**
  String get pedomass;

  /// No description provided for @lithomass.
  ///
  /// In ka, this message translates to:
  /// **'ლითომასა'**
  String get lithomass;

  /// No description provided for @hydromass.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდრომასა'**
  String get hydromass;

  /// No description provided for @phytomass.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა'**
  String get phytomass;

  /// No description provided for @bulkDensity.
  ///
  /// In ka, this message translates to:
  /// **'მოც.წ.'**
  String get bulkDensity;

  /// No description provided for @quantity.
  ///
  /// In ka, this message translates to:
  /// **'რაოდ.'**
  String get quantity;

  /// No description provided for @density.
  ///
  /// In ka, this message translates to:
  /// **'სიმკვ.'**
  String get density;

  /// No description provided for @moisture.
  ///
  /// In ka, this message translates to:
  /// **'სინოტ.'**
  String get moisture;

  /// No description provided for @wet.
  ///
  /// In ka, this message translates to:
  /// **'სველი'**
  String get wet;

  /// No description provided for @dry.
  ///
  /// In ka, this message translates to:
  /// **'მშრალი'**
  String get dry;

  /// No description provided for @treeVegTaxation.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეულობის ტაქსაცია'**
  String get treeVegTaxation;

  /// No description provided for @experimentPlotSize.
  ///
  /// In ka, this message translates to:
  /// **'ექსპ. ნაკვ. ზომა'**
  String get experimentPlotSize;

  /// No description provided for @species.
  ///
  /// In ka, this message translates to:
  /// **'სახეობა'**
  String get species;

  /// No description provided for @volume.
  ///
  /// In ka, this message translates to:
  /// **'მოცულობა'**
  String get volume;

  /// No description provided for @treePhytomass.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეების ფიტომასა'**
  String get treePhytomass;

  /// No description provided for @wood.
  ///
  /// In ka, this message translates to:
  /// **'მერქ.'**
  String get wood;

  /// No description provided for @leaves.
  ///
  /// In ka, this message translates to:
  /// **'ფოთლ.'**
  String get leaves;

  /// No description provided for @branches.
  ///
  /// In ka, this message translates to:
  /// **'ტოტ.'**
  String get branches;

  /// No description provided for @roots.
  ///
  /// In ka, this message translates to:
  /// **'ფესვ.'**
  String get roots;

  /// No description provided for @total.
  ///
  /// In ka, this message translates to:
  /// **'ჯამი'**
  String get total;

  /// No description provided for @verticalStructure.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ-ის ვერტიკალური სტრუქტურა'**
  String get verticalStructure;

  /// No description provided for @vertStructTypeName.
  ///
  /// In ka, this message translates to:
  /// **'ვ.ს. ტიპის სახელწოდება'**
  String get vertStructTypeName;

  /// No description provided for @vertStructIndex.
  ///
  /// In ka, this message translates to:
  /// **'ინდექსი'**
  String get vertStructIndex;

  /// No description provided for @vertStructHeight.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლე'**
  String get vertStructHeight;

  /// No description provided for @vertStructDesc.
  ///
  /// In ka, this message translates to:
  /// **'ვ.პ. მიწისზედა ნ. დამოკიდებულება მიწისქვედა ნ.თ.'**
  String get vertStructDesc;

  /// No description provided for @geohorizons.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰორიზონტები'**
  String get geohorizons;

  /// No description provided for @geohorizonRow.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰ. ინდ.'**
  String get geohorizonRow;

  /// No description provided for @noRecords.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები არ მოიძებნა'**
  String get noRecords;

  /// No description provided for @deleteConfirm.
  ///
  /// In ka, this message translates to:
  /// **'დარწმუნებული ხართ წაშლაში?'**
  String get deleteConfirm;

  /// No description provided for @yes.
  ///
  /// In ka, this message translates to:
  /// **'კი'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ka, this message translates to:
  /// **'არა'**
  String get no;

  /// No description provided for @recordDetails.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერის დეტალები'**
  String get recordDetails;

  /// No description provided for @editRecord.
  ///
  /// In ka, this message translates to:
  /// **'რედაქტირება'**
  String get editRecord;

  /// No description provided for @pdfViewer.
  ///
  /// In ka, this message translates to:
  /// **'PDF ნახვა'**
  String get pdfViewer;

  /// No description provided for @pdfScrollRemembered.
  ///
  /// In ka, this message translates to:
  /// **'PDF გახსნის ადგილი დამახსოვრდა'**
  String get pdfScrollRemembered;

  /// No description provided for @defaultEmail.
  ///
  /// In ka, this message translates to:
  /// **'ნაგულისხმევი ელ-ფოსტა'**
  String get defaultEmail;

  /// No description provided for @defaultEmailHint.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტის მისამართი...'**
  String get defaultEmailHint;

  /// No description provided for @aboutApp.
  ///
  /// In ka, this message translates to:
  /// **'აპლიკაციის შესახებ'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ka, this message translates to:
  /// **'ვერსია'**
  String get version;

  /// No description provided for @organization.
  ///
  /// In ka, this message translates to:
  /// **'ალ. ასლანიკაშვილის სახ. საქართველოს კარტოგრაფთა ასოციაცია'**
  String get organization;

  /// No description provided for @locationDetecting.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების დადგენა...'**
  String get locationDetecting;

  /// No description provided for @locationError.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების დადგენა ვერ მოხდა'**
  String get locationError;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ka, this message translates to:
  /// **'ლოკაციის ნებართვა არ არის'**
  String get locationPermissionDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ka':
      return AppLocalizationsKa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

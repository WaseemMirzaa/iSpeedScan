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
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
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
/// import 'gen_l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('ja'),
    Locale('ar'),
    Locale('hi'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('he')
  ];

  /// No description provided for @iSpeedScan.
  ///
  /// In en, this message translates to:
  /// **'iSpeedScan'**
  String get iSpeedScan;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode: '**
  String get mode;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @pdfQuality.
  ///
  /// In en, this message translates to:
  /// **'PDF Quality'**
  String get pdfQuality;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @howToUseISpeedScan.
  ///
  /// In en, this message translates to:
  /// **'How to Use iSpeedScan'**
  String get howToUseISpeedScan;

  /// No description provided for @simplicityAndEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Simplicity and Efficiency'**
  String get simplicityAndEfficiency;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Security'**
  String get privacyAndSecurity;

  /// No description provided for @moreAppsByTevinEighDesigns.
  ///
  /// In en, this message translates to:
  /// **'More Apps By Tevin Eigh Designs'**
  String get moreAppsByTevinEighDesigns;

  /// No description provided for @aboutTevinEighDesigns.
  ///
  /// In en, this message translates to:
  /// **'About Tevin Eigh Designs'**
  String get aboutTevinEighDesigns;

  /// No description provided for @lifeTimeSubsciption.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Subscription = '**
  String get lifeTimeSubsciption;

  /// No description provided for @viewPurchaseDetails.
  ///
  /// In en, this message translates to:
  /// **'View Purchase Details'**
  String get viewPurchaseDetails;

  /// No description provided for @checkYourPhotoGalaryForYourSavedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Check your Photo Gallery for your Saved Photo(s)'**
  String get checkYourPhotoGalaryForYourSavedPhotos;

  /// No description provided for @languageAndTranslation.
  ///
  /// In en, this message translates to:
  /// **'Language & Translation'**
  String get languageAndTranslation;

  /// No description provided for @howToUSeiSpeed.
  ///
  /// In en, this message translates to:
  /// **'How to Use iSpeedScan : Step-by-Step Guide'**
  String get howToUSeiSpeed;

  /// No description provided for @startScanningAndItesDetails.
  ///
  /// In en, this message translates to:
  /// **'1. Start Scanning \n-Open iSpeedScan, On the start screen, use the Picture/PDF slider to select your preferred mode\n*For convenience, after a few moments the app automatically opens in the last mode you used unless you change it before scanning'**
  String get startScanningAndItesDetails;

  /// No description provided for @selectYourModeAndItsDetails.
  ///
  /// In en, this message translates to:
  /// **'2. Select Your Mode\n-Scan as Picture: Opens immediately, allowing you to scan and save images directly to your gallery\n-Scan as PDF: Opens a PDF Scanner where you can scan multiple pages before finalizing and saving them as a single PDF'**
  String get selectYourModeAndItsDetails;

  /// No description provided for @captureADocumentAndItsDetails.
  ///
  /// In en, this message translates to:
  /// **'3. Capture a Document (either mode)\n-Hover your device over the document, and the scanner will automatically detect and scan it\n-A manual capture option is also available for more control\n-Scan multiple documents quickly and effortlessly\n*You can edit individual pages before saving by tapping the thumbnails in the bottom left, which opens your device’s native tools for basic editing (edits can also be made later after saving)'**
  String get captureADocumentAndItsDetails;

  /// No description provided for @saveAndOrganizeAndItsDetails.
  ///
  /// In en, this message translates to:
  /// **'4. Save & Organize\n-Scan as Picture: Saves each scan directly to your device’s gallery\n-Scan as PDF: After scanning, you’ll be taken to the next screen where you can share, save, upload, message, or email your PDF'**
  String get saveAndOrganizeAndItsDetails;

  /// No description provided for @viewShareAndManageAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'5. View, Share & Manage\n-Share your scans via email, messaging, cloud storage, uploads, or social media using your device’s native share options\n-Once saved, you can use your standard operating system tools to edit, share, save, upload, message, or email your PDF as needed'**
  String get viewShareAndManageAndOtherDetails;

  /// No description provided for @mainMenuAndModeSelectionAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'*Main Menu & Mode Selection\n-Need to switch modes? Tap Cancel during scanning to return to the main menu, where you can select Scan as Image or Scan as PDF before resuming\n-For convenience, the app automatically opens in the last mode you used unless you change it before scanning'**
  String get mainMenuAndModeSelectionAndOtherDetails;

  /// No description provided for @privacyAndSecurityAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'*Privacy & Security: Your documents are securely stored in your device’s gallery\n-iSpeedScan does not store your files, ensuring complete privacy'**
  String get privacyAndSecurityAndOtherDetails;

  /// No description provided for @ourMissionAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'*Our Mission: We focus on simplicity, efficiency, and privacy—providing the tools you need without unnecessary extras'**
  String get ourMissionAndOtherDetails;

  /// No description provided for @ourPhilosophySimplicityAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'Our Philosophy\n-Simplicity: Our apps are designed to be intuitive and straightforward, making them easy to use for everyone.\n-Security: By keeping all processing on the client side, we ensure your data remains private and secure.\n-Efficiency: We continually refine our apps to remove unnecessary steps while preserving their core functionality.'**
  String get ourPhilosophySimplicityAndOtherDetails;

  /// No description provided for @weBelieveInProvidingJustDetails.
  ///
  /// In en, this message translates to:
  /// **'We believe in providing just what you need, nothing more, nothing less. As we evolve, our commitment remains to enhance efficiency without compromising on the primary purpose of our applications.'**
  String get weBelieveInProvidingJustDetails;

  /// No description provided for @exploreOurRangOfClientAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'Explore our range of client-side apps and experience the difference simplicity, efficiency, and security can make in your daily tasks.'**
  String get exploreOurRangOfClientAndOtherDetails;

  /// No description provided for @atISpeedScanWePrioritizAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'At iSpeedScan, we prioritize your privacy and the security of your information. This Privacy and Security Policy outlines how we handle data when you use iSpeedScan. Our goal is to provide a straightforward, secure experience while keeping your information protected.\n\n'**
  String get atISpeedScanWePrioritizAndOtherDetails;

  /// No description provided for @informationCollectionAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'1. Information Collection and Utilization\niSpeedScan is built to function without collecting or storing personal data for its core features, such as document scanning and storage. All data processed by the app stays on your device, with the exception of minimal information needed for subscription processing. Here’s what we access and why:\n\n•Camera Access: We need access to your device’s camera to scan documents. All images are processed locally and never sent elsewhere.\n\n•Photo Gallery Access: We request permission to save scanned documents to your photo gallery. This is only for your convenience, and we don’t touch your existing photos.•Storage of PDFs in Files: If you opt to save scans as PDFs, we’ll ask for storage permissions. These files remain under your control on your device.\n\n•Document Management: Users have full control over their PDFs and can choose to share, email, save, or upload them as they prefer.\n\n•Subscription Processing: To unlock full features, a one-time subscription fee is processed securely through a third-party service. We don’t collect or store your payment details—everything is handled safely by that service.'**
  String get informationCollectionAndOtherDetails;

  /// No description provided for @dataTransmissionPracticeAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'2. Data Transmission Practices\nFor its main functions—like scanning and saving documents — iSpeedScan doesn’t send any data to external servers or third parties. Everything happens locally on your device. The only data transmitted is related to your life time subscription, which is securely managed by a payment service'**
  String get dataTransmissionPracticeAndOtherDetails;

  /// No description provided for @absenceOfAdvertismentsAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'3. Absence of Advertisements\niSpeedScan offers a clean, ad-free experience. Once you pay the one-time subscription fee you get full access to all features—no hidden costs or interruptions.'**
  String get absenceOfAdvertismentsAndOtherDetails;

  /// No description provided for @ourDedicationToYourPrivacyAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'4. Our Dedication to Your Privacy\nWe’re committed to upholding the highest privacy and security standards for our users. If you have any questions or want more details about this policy, please don’t hesitate to reach out to use.'**
  String get ourDedicationToYourPrivacyAndOtherDetails;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @atTevinEighDesignsAndOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'At Tevin Eigh Designs, we specialize in creating client-side apps that solve daily problems with simplicity, efficiency, and security. Our focus is on delivering the core functionality you need with the fewest steps and clicks possible, ensuring you can concentrate on your main tasks without distractions.\n\nOur Philosophy\n-Simplicity: Our apps are designed to be intuitive and straithforward, making them easy to use for everyone.\n-Security: By keeping all processing on the client side, we ensure your data remains private and secure.\n-Efficiency: We continually refine our apps to remove unnecessary steps while preserving their core functionality.\n\nWe Believe in providing just what you need, nothing more, nothing less. As we evolve, our commitment remains to enhance efficiency without compromising on the primary purpose of our applications.\n\nExplore our range of client-side apps and experience the difference simplicity, efficiency, and security can make in your daily tasks.\n\n'**
  String get atTevinEighDesignsAndOtherDetails;

  /// No description provided for @currentPlanFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Current Plan : Full Access'**
  String get currentPlanFullAccess;

  /// No description provided for @currentPlanFreeTrail.
  ///
  /// In en, this message translates to:
  /// **'Current Plan : Free Trial'**
  String get currentPlanFreeTrail;

  /// No description provided for @freeTailOneWeekUnlimitedUse.
  ///
  /// In en, this message translates to:
  /// **'FREE TRIAL – 1 Week – Unlimited Use\n\n'**
  String get freeTailOneWeekUnlimitedUse;

  /// No description provided for @freeVersionAfterTrailExpires.
  ///
  /// In en, this message translates to:
  /// **'FREE VERSION – After Trial Expires\n\n'**
  String get freeVersionAfterTrailExpires;

  /// No description provided for @fourMinutesOfFreeScanningWeekly.
  ///
  /// In en, this message translates to:
  /// **'✔ 3 minutes of FREE scanning weekly\n\n'**
  String get fourMinutesOfFreeScanningWeekly;

  /// No description provided for @oneTimePurchaseUnlockFullAccess.
  ///
  /// In en, this message translates to:
  /// **'One Time Purchase (Unlock Full Access)'**
  String get oneTimePurchaseUnlockFullAccess;

  /// No description provided for @unlimitedScansLifetimeAccess.
  ///
  /// In en, this message translates to:
  /// **'\n\n ✔ Unlimited Scans, lifetime access'**
  String get unlimitedScansLifetimeAccess;

  /// No description provided for @getLifetimeAccessAndOtherDecs.
  ///
  /// In en, this message translates to:
  /// **'\n\nGet lifetime access to iSpeedScan with a one-time purchase & unlock its full power today'**
  String get getLifetimeAccessAndOtherDecs;

  /// No description provided for @purchaseNow.
  ///
  /// In en, this message translates to:
  /// **'Purchase Now'**
  String get purchaseNow;

  /// No description provided for @checkingActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'Checking Active Purchase'**
  String get checkingActivePurchases;

  /// No description provided for @alreadyPuchasedRestoreHere.
  ///
  /// In en, this message translates to:
  /// **'Already Purchased? Restore Here'**
  String get alreadyPuchasedRestoreHere;

  /// No description provided for @yourPurchaseHasBeenSuccessfullyRestored.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been successfully restored!'**
  String get yourPurchaseHasBeenSuccessfullyRestored;

  /// No description provided for @noPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No Purchases Found'**
  String get noPurchasesFound;

  /// No description provided for @weCouldntFindAnyPurchasesToRestore.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any previous purchases to restore.'**
  String get weCouldntFindAnyPurchasesToRestore;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @faildToRestorePurchasesPlzTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore purchases. Please try again later.'**
  String get faildToRestorePurchasesPlzTryAgainLater;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @creatingPDF.
  ///
  /// In en, this message translates to:
  /// **'Creating PDF...'**
  String get creatingPDF;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @yourPurchaseSuccessfullyRestored.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been successfully restored!'**
  String get yourPurchaseSuccessfullyRestored;

  /// No description provided for @creatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Creating PDF...'**
  String get creatingPdf;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @selectYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Preferred Language'**
  String get selectYourPreferredLanguage;

  /// No description provided for @chooseTheLanguageYouWant.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you want to use in the app'**
  String get chooseTheLanguageYouWant;

  /// No description provided for @languageInformation.
  ///
  /// In en, this message translates to:
  /// **'Language Information'**
  String get languageInformation;

  /// No description provided for @iSpeedScanSupportsMultipleLanuages.
  ///
  /// In en, this message translates to:
  /// **'iSpeedScan supports multiple languages to make the app accessible to users worldwide. If your preferred language is not available, more languages will be added in future updates.'**
  String get iSpeedScanSupportsMultipleLanuages;

  /// No description provided for @rateThisApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateThisApp;

  /// No description provided for @ifYouUsingEnjoyThisApp.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy using this app, we’d really appreciate it if you could take a minute to leave a review! Your feedback helps us improve and won’t take more than a minute of your time.'**
  String get ifYouUsingEnjoyThisApp;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'RATE'**
  String get rate;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'NO THANKS'**
  String get noThanks;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'MAYBE LATER'**
  String get maybeLater;

  /// No description provided for @stillEnjoyingIt.
  ///
  /// In en, this message translates to:
  /// **'Still Enjoying It?'**
  String get stillEnjoyingIt;

  /// No description provided for @stillEnjoyingItMessage.
  ///
  /// In en, this message translates to:
  /// **'Still enjoying it? Upgrade now and keep access forever with our lifetime plan — one payment, no subscriptions, unlimited usage for life!'**
  String get stillEnjoyingItMessage;

  /// No description provided for @subscriptionTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Subscription Time Remaining'**
  String get subscriptionTimeRemaining;

  /// No description provided for @freeTrialTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Free Trial Time Remaining'**
  String get freeTrialTimeRemaining;

  /// No description provided for @trialTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Trial Time Remaining'**
  String get trialTimeRemaining;

  /// No description provided for @almostOutOfFreeTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost Out of Free Time'**
  String get almostOutOfFreeTimeTitle;

  /// No description provided for @almostOutOfFreeTimeWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost out of free time this month! Upgrade to our lifetime plan with a single one-time payment — no recurring charges, no subscriptions. Get unlimited usage forever.'**
  String get almostOutOfFreeTimeWarningMessage;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @resetTimer.
  ///
  /// In en, this message translates to:
  /// **'Reset Timer'**
  String get resetTimer;

  /// No description provided for @freeTimeExpired.
  ///
  /// In en, this message translates to:
  /// **'Free Time Expired'**
  String get freeTimeExpired;

  /// No description provided for @freeTimeWillResetNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Your free 3 minutes will reset next month. Get unlimited scanning now!'**
  String get freeTimeWillResetNextMonth;

  /// No description provided for @premiumForever.
  ///
  /// In en, this message translates to:
  /// **'Premium Forever - \$4.99'**
  String get premiumForever;

  /// No description provided for @unlimitedScanning.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited scanning\n✓ No time limits\n✓ Premium features\n✓ One-time payment'**
  String get unlimitedScanning;

  /// No description provided for @privacyAndSecurityDetailFive.
  ///
  /// In en, this message translates to:
  /// **'5. Privacy Policy - Our apps use Google Firebase for App Store Optimization (ASO) and Search Engine Optimization (SEO) purposes only. We do not collect, sell, or use this information for any other purposes.\n\nFor more information about Google Firebase’s data practices, please refer to their Privacy Policy:'**
  String get privacyAndSecurityDetailFive;

  /// No description provided for @readyToUnlockUnlimitedPower.
  ///
  /// In en, this message translates to:
  /// **'🚀 Ready to Unlock Unlimited Power?'**
  String get readyToUnlockUnlimitedPower;

  /// No description provided for @timesUpButYourJourneyContinues.
  ///
  /// In en, this message translates to:
  /// **'⏰ Time\'s Up! But Your Journey Continues...'**
  String get timesUpButYourJourneyContinues;

  /// No description provided for @upgradeToUnlimitedScanning.
  ///
  /// In en, this message translates to:
  /// **'🌟 Upgrade to Premium and scan without limits! Join thousands of users who\'ve unlocked their full potential.'**
  String get upgradeToUnlimitedScanning;

  /// No description provided for @finalCountdown.
  ///
  /// In en, this message translates to:
  /// **'⚡ Final Countdown!'**
  String get finalCountdown;

  /// No description provided for @dontLetProductivityStop.
  ///
  /// In en, this message translates to:
  /// **'🚀 Don\'t let your productivity stop here! Upgrade now for unlimited scanning power.'**
  String get dontLetProductivityStop;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @trialStatusDebug.
  ///
  /// In en, this message translates to:
  /// **'Trial Status Debug'**
  String get trialStatusDebug;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get status;

  /// No description provided for @logic.
  ///
  /// In en, this message translates to:
  /// **'Logic:'**
  String get logic;

  /// No description provided for @freeTrialExpiredOrExhausted.
  ///
  /// In en, this message translates to:
  /// **'FREE TRIAL EXPIRED or FREE FEATURES EXHAUSTED'**
  String get freeTrialExpiredOrExhausted;

  /// No description provided for @subscribed.
  ///
  /// In en, this message translates to:
  /// **'✅ SUBSCRIBED'**
  String get subscribed;

  /// No description provided for @freeTrialActive.
  ///
  /// In en, this message translates to:
  /// **'🆓 FREE TRIAL ACTIVE'**
  String get freeTrialActive;

  /// No description provided for @monthlyAllowance.
  ///
  /// In en, this message translates to:
  /// **'⏰ MONTHLY ALLOWANCE'**
  String get monthlyAllowance;

  /// No description provided for @trialExpired.
  ///
  /// In en, this message translates to:
  /// **'❌ TRIAL EXPIRED'**
  String get trialExpired;

  /// No description provided for @scanningBlocked.
  ///
  /// In en, this message translates to:
  /// **'Scanning blocked'**
  String get scanningBlocked;

  /// No description provided for @unlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access'**
  String get unlimitedAccess;

  /// No description provided for @unlimitedScanningAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scanning'**
  String get unlimitedScanningAccess;

  /// No description provided for @scanningAvailable.
  ///
  /// In en, this message translates to:
  /// **'Scanning available'**
  String get scanningAvailable;

  /// No description provided for @navigationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Navigation blocked - trial expired!'**
  String get navigationBlocked;

  /// No description provided for @navigationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Navigation allowed'**
  String get navigationAllowed;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED'**
  String get blocked;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'ALLOWED'**
  String get allowed;

  /// No description provided for @freeTrialExpiredOrFeaturesExhausted.
  ///
  /// In en, this message translates to:
  /// **'FREE TRIAL EXPIRED or FREE FEATURES EXHAUSTED'**
  String get freeTrialExpiredOrFeaturesExhausted;

  /// No description provided for @freeFeaturesRenewEvery30Days.
  ///
  /// In en, this message translates to:
  /// **'FREE FEATURES RENEW EVERY 30 DAYS'**
  String get freeFeaturesRenewEvery30Days;

  /// No description provided for @upgradeNowWithOneTimePurchase.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE NOW WITH A ONE TIME PURCHASE & UNLOCK THE FULL POWER OF iSpeedScan 🚀.'**
  String get upgradeNowWithOneTimePurchase;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'he', 'hi', 'it', 'ja', 'ko', 'pt', 'ru', 'th', 'tr', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'he': return AppLocalizationsHe();
    case 'hi': return AppLocalizationsHi();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'th': return AppLocalizationsTh();
    case 'tr': return AppLocalizationsTr();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

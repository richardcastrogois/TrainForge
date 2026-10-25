import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('pt', 'PT'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the interface language on this device.'**
  String get languageIntro;

  /// No description provided for @languageScope.
  ///
  /// In en, this message translates to:
  /// **'This choice does not change your account, original foods or records.'**
  String get languageScope;

  /// No description provided for @contentOriginal.
  ///
  /// In en, this message translates to:
  /// **'Source names and text stay in their original language when no reviewed translation is available.'**
  String get contentOriginal;

  /// No description provided for @languageProgress.
  ///
  /// In en, this message translates to:
  /// **'Translation of the remaining screens is in progress.'**
  String get languageProgress;

  /// No description provided for @followDevice.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get followDevice;

  /// No description provided for @languageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Language settings are unavailable here.'**
  String get languageUnavailable;

  /// No description provided for @languageFallback.
  ///
  /// In en, this message translates to:
  /// **'The preference could not be read. The device language is being used.'**
  String get languageFallback;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The language could not be saved. Try again.'**
  String get languageSaveFailed;

  /// No description provided for @languageSaveUncertain.
  ///
  /// In en, this message translates to:
  /// **'The language was applied, but saving was not confirmed. Try saving again.'**
  String get languageSaveUncertain;

  /// No description provided for @savingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Saving language'**
  String get savingLanguage;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Try saving again'**
  String get retrySave;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pace, your theme.'**
  String get appearanceTitle;

  /// No description provided for @appearanceIntro.
  ///
  /// In en, this message translates to:
  /// **'This choice stays on this device after you close the app. Your account data is unchanged.'**
  String get appearanceIntro;

  /// No description provided for @appearanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Appearance settings are unavailable here.'**
  String get appearanceUnavailable;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device theme'**
  String get themeSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Follows the light or dark system theme.'**
  String get themeSystemHint;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightHint.
  ///
  /// In en, this message translates to:
  /// **'The original identity on light surfaces.'**
  String get lightHint;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @darkHint.
  ///
  /// In en, this message translates to:
  /// **'Dark surfaces with adapted contrast.'**
  String get darkHint;

  /// No description provided for @savingAppearance.
  ///
  /// In en, this message translates to:
  /// **'Saving appearance'**
  String get savingAppearance;

  /// No description provided for @accessibilityDevice.
  ///
  /// In en, this message translates to:
  /// **'Text size and reduced motion follow your device accessibility settings.'**
  String get accessibilityDevice;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Good to have you here.'**
  String get welcome;

  /// No description provided for @welcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your routine.'**
  String get welcomeHint;

  /// No description provided for @waitingGoogle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Google confirmation'**
  String get waitingGoogle;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account yet?'**
  String get noAccount;

  /// No description provided for @createGoogle.
  ///
  /// In en, this message translates to:
  /// **'Create an account with Google'**
  String get createGoogle;

  /// No description provided for @googleOnly.
  ///
  /// In en, this message translates to:
  /// **'This version uses Google sign-in. Email and Apple sign-in are not available yet.'**
  String get googleOnly;

  /// No description provided for @firstAccess.
  ///
  /// In en, this message translates to:
  /// **'First access and setup'**
  String get firstAccess;

  /// No description provided for @exploreFirst.
  ///
  /// In en, this message translates to:
  /// **'Explore before signing in'**
  String get exploreFirst;

  /// No description provided for @publicCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse the library without signing in'**
  String get publicCatalog;

  /// No description provided for @publicFood.
  ///
  /// In en, this message translates to:
  /// **'Browse foods without recording intake'**
  String get publicFood;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get privacy;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing TrainForge'**
  String get preparing;

  /// No description provided for @restoringSession.
  ///
  /// In en, this message translates to:
  /// **'Confirming your session'**
  String get restoringSession;

  /// No description provided for @confirmingSession.
  ///
  /// In en, this message translates to:
  /// **'Confirming session'**
  String get confirmingSession;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @evolution.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get evolution;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yourSpace.
  ///
  /// In en, this message translates to:
  /// **'Your space.'**
  String get yourSpace;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get connected;

  /// No description provided for @accountData.
  ///
  /// In en, this message translates to:
  /// **'Account and personal data'**
  String get accountData;

  /// No description provided for @identityHint.
  ///
  /// In en, this message translates to:
  /// **'Google identity, export and deletion'**
  String get identityHint;

  /// No description provided for @goalsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Goals and routine'**
  String get goalsRoutine;

  /// No description provided for @equipmentDays.
  ///
  /// In en, this message translates to:
  /// **'Equipment, days and activities'**
  String get equipmentDays;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Appearance and device accessibility'**
  String get preferenceHint;

  /// No description provided for @devicesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Devices and permissions'**
  String get devicesPermissions;

  /// No description provided for @devicesHint.
  ///
  /// In en, this message translates to:
  /// **'Health Connect, location and camera'**
  String get devicesHint;

  /// No description provided for @privacyHint.
  ///
  /// In en, this message translates to:
  /// **'Export, deletion and current policy'**
  String get privacyHint;

  /// No description provided for @helpEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Help and evaluation terms'**
  String get helpEvaluation;

  /// No description provided for @helpHint.
  ///
  /// In en, this message translates to:
  /// **'Questions, sources and available features'**
  String get helpHint;

  /// No description provided for @confirmConnection.
  ///
  /// In en, this message translates to:
  /// **'Confirm connection'**
  String get confirmConnection;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this session'**
  String get signOut;

  /// No description provided for @languageNames.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Portuguese, European Portuguese, English and Spanish'**
  String get languageNames;

  /// No description provided for @sessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Session confirmation took longer than expected. Your session was preserved; retry or browse the library without signing in.'**
  String get sessionTimeout;

  /// No description provided for @googleConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured in this environment. Check the evaluation guide.'**
  String get googleConfiguration;

  /// No description provided for @authConfiguration.
  ///
  /// In en, this message translates to:
  /// **'The authentication environment needs configuration. Check the evaluation guide.'**
  String get authConfiguration;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'The session expired or was revoked. Sign in with Google again.'**
  String get sessionExpired;

  /// No description provided for @rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get rateLimited;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The authentication service is unavailable. Try again later.'**
  String get authUnavailable;

  /// No description provided for @signOutUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sign-out was not confirmed. Connect to the internet and try signing out again.'**
  String get signOutUnconfirmed;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your connection and try again.'**
  String get signInFailed;

  /// No description provided for @sessionOffline.
  ///
  /// In en, this message translates to:
  /// **'The connection could not be confirmed. Your session was preserved; try again.'**
  String get sessionOffline;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'This action could not be completed. Try again.'**
  String get actionFailed;

  /// No description provided for @appearanceInvalid.
  ///
  /// In en, this message translates to:
  /// **'The previous preference could not be used. The device theme is being used.'**
  String get appearanceInvalid;

  /// No description provided for @appearanceReadFailed.
  ///
  /// In en, this message translates to:
  /// **'The saved appearance could not be read. The device theme is being used.'**
  String get appearanceReadFailed;

  /// No description provided for @appearanceSaveUncertain.
  ///
  /// In en, this message translates to:
  /// **'The appearance was applied, but saving was not confirmed. Try again.'**
  String get appearanceSaveUncertain;

  /// No description provided for @appearanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The appearance could not be saved. Try again.'**
  String get appearanceSaveFailed;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

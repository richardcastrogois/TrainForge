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

  /// No description provided for @moveNow.
  ///
  /// In en, this message translates to:
  /// **'Let\'s move!'**
  String get moveNow;

  /// No description provided for @moveWithName.
  ///
  /// In en, this message translates to:
  /// **'Let\'s move, {name}!'**
  String moveWithName(String name);

  /// No description provided for @dailyRhythm.
  ///
  /// In en, this message translates to:
  /// **'Your pace, every day'**
  String get dailyRhythm;

  /// No description provided for @strongerDaily.
  ///
  /// In en, this message translates to:
  /// **'A LITTLE STRONGER, EVERY DAY'**
  String get strongerDaily;

  /// No description provided for @nextMovement.
  ///
  /// In en, this message translates to:
  /// **'Your next movement'**
  String get nextMovement;

  /// No description provided for @libraryReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Reference library. Guided practice is not available yet.'**
  String get libraryReadOnly;

  /// No description provided for @yourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get yourWeek;

  /// No description provided for @diaryByDate.
  ///
  /// In en, this message translates to:
  /// **'Browse the food diary by date.'**
  String get diaryByDate;

  /// No description provided for @yourDay.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get yourDay;

  /// No description provided for @loadingDayData.
  ///
  /// In en, this message translates to:
  /// **'Loading your recorded day data'**
  String get loadingDayData;

  /// No description provided for @loadingDayRecords.
  ///
  /// In en, this message translates to:
  /// **'Loading day records'**
  String get loadingDayRecords;

  /// No description provided for @dayUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The day could not be updated.'**
  String get dayUpdateFailed;

  /// No description provided for @dayUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The data was not confirmed. This query does not create or delete intake records.'**
  String get dayUnconfirmed;

  /// No description provided for @retryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Try updating again'**
  String get retryUpdate;

  /// No description provided for @energyNoSubtotal.
  ///
  /// In en, this message translates to:
  /// **'energy without a confirmed single subtotal'**
  String get energyNoSubtotal;

  /// No description provided for @energySourceMethod.
  ///
  /// In en, this message translates to:
  /// **'kcal · one source method'**
  String get energySourceMethod;

  /// No description provided for @activityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'activity not available yet'**
  String get activityUnavailable;

  /// No description provided for @summaryLimit.
  ///
  /// In en, this message translates to:
  /// **'The summary limit was exceeded. Check the history; no partial total is presented as complete.'**
  String get summaryLimit;

  /// No description provided for @quantityEvidenceCounts.
  ///
  /// In en, this message translates to:
  /// **'{measured, plural, =1{1 measured quantity} other{{measured} measured quantities}} · {estimated, plural, =1{1 estimated quantity} other{{estimated} estimated quantities}}'**
  String quantityEvidenceCounts(int measured, int estimated);

  /// No description provided for @originMethodDiary.
  ///
  /// In en, this message translates to:
  /// **'Source and method in the diary.'**
  String get originMethodDiary;

  /// No description provided for @myNutrition.
  ///
  /// In en, this message translates to:
  /// **'My nutrition'**
  String get myNutrition;

  /// No description provided for @loadingRecords.
  ///
  /// In en, this message translates to:
  /// **'Loading records…'**
  String get loadingRecords;

  /// No description provided for @openHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Open history and try updating'**
  String get openHistoryRetry;

  /// No description provided for @noConfirmedToday.
  ///
  /// In en, this message translates to:
  /// **'No confirmed intake for this day'**
  String get noConfirmedToday;

  /// No description provided for @viewRecordsOrigin.
  ///
  /// In en, this message translates to:
  /// **'View records and sources'**
  String get viewRecordsOrigin;

  /// No description provided for @confirmedDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No confirmed intake for this day} =1{1 confirmed intake for this day · view source} other{{count} confirmed intakes for this day · view sources}}'**
  String confirmedDayCount(int count);

  /// No description provided for @whatToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like today?'**
  String get whatToday;

  /// No description provided for @exploreActivities.
  ///
  /// In en, this message translates to:
  /// **'Walk, run, explore another activity'**
  String get exploreActivities;

  /// No description provided for @updateDay.
  ///
  /// In en, this message translates to:
  /// **'Refresh the day'**
  String get updateDay;

  /// No description provided for @viewFoodDay.
  ///
  /// In en, this message translates to:
  /// **'View intake for {date}'**
  String viewFoodDay(String date);

  /// No description provided for @findMovement.
  ///
  /// In en, this message translates to:
  /// **'Find your movement.'**
  String get findMovement;

  /// No description provided for @atYourPace.
  ///
  /// In en, this message translates to:
  /// **'With guidance, at your pace.'**
  String get atYourPace;

  /// No description provided for @searchUpper.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get searchUpper;

  /// No description provided for @movementSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Movement, activity or source'**
  String get movementSearchHint;

  /// No description provided for @loadingPrograms.
  ///
  /// In en, this message translates to:
  /// **'Loading available programs'**
  String get loadingPrograms;

  /// No description provided for @programsUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Programs could not be loaded. Availability was not confirmed.'**
  String get programsUnconfirmed;

  /// No description provided for @programsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Programs not available yet'**
  String get programsUnavailable;

  /// No description provided for @browsePrograms.
  ///
  /// In en, this message translates to:
  /// **'Browse programs'**
  String get browsePrograms;

  /// No description provided for @noPracticeProgram.
  ///
  /// In en, this message translates to:
  /// **'No program has been approved for practice. Browse the available references.'**
  String get noPracticeProgram;

  /// No description provided for @viewRequirements.
  ///
  /// In en, this message translates to:
  /// **'View sources, requirements and availability'**
  String get viewRequirements;

  /// No description provided for @exploreModalities.
  ///
  /// In en, this message translates to:
  /// **'Explore activities'**
  String get exploreModalities;

  /// No description provided for @referenceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Reference library · read only'**
  String get referenceLibrary;

  /// No description provided for @createMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Create my plan'**
  String get createMyPlan;

  /// No description provided for @organizeWeek.
  ///
  /// In en, this message translates to:
  /// **'Choose exercises and organize the week'**
  String get organizeWeek;

  /// No description provided for @compositionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Composition unavailable'**
  String get compositionUnavailable;

  /// No description provided for @helpStart.
  ///
  /// In en, this message translates to:
  /// **'Help me get started'**
  String get helpStart;

  /// No description provided for @audiencesEnvironments.
  ///
  /// In en, this message translates to:
  /// **'Home, park, gym, older adults and caregivers'**
  String get audiencesEnvironments;

  /// No description provided for @eatSimply.
  ///
  /// In en, this message translates to:
  /// **'Eating well, made simple.'**
  String get eatSimply;

  /// No description provided for @foodDiaryUpper.
  ///
  /// In en, this message translates to:
  /// **'FOOD DIARY'**
  String get foodDiaryUpper;

  /// No description provided for @loadingQuery.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingQuery;

  /// No description provided for @queryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Query unavailable'**
  String get queryUnavailable;

  /// No description provided for @sourceSubtotals.
  ///
  /// In en, this message translates to:
  /// **'View subtotals for each source method.'**
  String get sourceSubtotals;

  /// No description provided for @recordedEnergy.
  ///
  /// In en, this message translates to:
  /// **'RECORDED ENERGY'**
  String get recordedEnergy;

  /// No description provided for @energyMethodSubtotal.
  ///
  /// In en, this message translates to:
  /// **'kcal · subtotal for one source method'**
  String get energyMethodSubtotal;

  /// No description provided for @updateDayRecords.
  ///
  /// In en, this message translates to:
  /// **'Refresh day records'**
  String get updateDayRecords;

  /// No description provided for @myRecords.
  ///
  /// In en, this message translates to:
  /// **'My records'**
  String get myRecords;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFood;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @waterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Water tracking is not available yet'**
  String get waterUnavailable;

  /// No description provided for @waterNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Water tracking is not implemented yet. No quantity was filled automatically.'**
  String get waterNotImplemented;

  /// No description provided for @planLearn.
  ///
  /// In en, this message translates to:
  /// **'Plan and learn'**
  String get planLearn;

  /// No description provided for @foodGuidanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Food guidance is not approved yet'**
  String get foodGuidanceUnavailable;

  /// No description provided for @planningLearning.
  ///
  /// In en, this message translates to:
  /// **'Planning and learning'**
  String get planningLearning;

  /// No description provided for @foodPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Meal plans and guidance are not available yet. Sources and their nutrients can still be browsed through the diary.'**
  String get foodPlansUnavailable;

  /// No description provided for @outdoorsCounts.
  ///
  /// In en, this message translates to:
  /// **'Outdoors counts too.'**
  String get outdoorsCounts;

  /// No description provided for @activityIntro.
  ///
  /// In en, this message translates to:
  /// **'Walk, run or record your activity.'**
  String get activityIntro;

  /// No description provided for @routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Routes are not available yet. No location is being collected.'**
  String get routeUnavailable;

  /// No description provided for @noWalkKm.
  ///
  /// In en, this message translates to:
  /// **'km · no walking record'**
  String get noWalkKm;

  /// No description provided for @noActivityMinutes.
  ///
  /// In en, this message translates to:
  /// **'activity minutes unavailable'**
  String get noActivityMinutes;

  /// No description provided for @startActivity.
  ///
  /// In en, this message translates to:
  /// **'Start activity'**
  String get startActivity;

  /// No description provided for @quickRecord.
  ///
  /// In en, this message translates to:
  /// **'Quick entry'**
  String get quickRecord;

  /// No description provided for @quickUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Manual and image entries are not available yet'**
  String get quickUnavailable;

  /// No description provided for @myDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get myDevices;

  /// No description provided for @permissionsSync.
  ///
  /// In en, this message translates to:
  /// **'Permissions, sources and sync'**
  String get permissionsSync;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Look at your progress.'**
  String get yourProgress;

  /// No description provided for @historyWithSource.
  ///
  /// In en, this message translates to:
  /// **'YOUR HISTORY, WITH SOURCES'**
  String get historyWithSource;

  /// No description provided for @chartUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Activity progress is not available yet. The chart will appear when records and calculations are implemented.'**
  String get chartUnavailable;

  /// No description provided for @workoutsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'workouts not available yet'**
  String get workoutsUnavailable;

  /// No description provided for @walkingKmUnavailable.
  ///
  /// In en, this message translates to:
  /// **'walking km unavailable'**
  String get walkingKmUnavailable;

  /// No description provided for @eachRecordCounts.
  ///
  /// In en, this message translates to:
  /// **'Every record counts'**
  String get eachRecordCounts;

  /// No description provided for @historyCorrect.
  ///
  /// In en, this message translates to:
  /// **'View history and correct an intake'**
  String get historyCorrect;

  /// No description provided for @measurementsGoals.
  ///
  /// In en, this message translates to:
  /// **'Measurements and goals'**
  String get measurementsGoals;

  /// No description provided for @configurationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Setup not available yet'**
  String get configurationUnavailable;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @foodReferences.
  ///
  /// In en, this message translates to:
  /// **'FOOD REFERENCES'**
  String get foodReferences;

  /// No description provided for @searchFor.
  ///
  /// In en, this message translates to:
  /// **'SEARCH · {query}'**
  String searchFor(String query);

  /// No description provided for @searchOriginal.
  ///
  /// In en, this message translates to:
  /// **'Search by original name'**
  String get searchOriginal;

  /// No description provided for @foodPreparation.
  ///
  /// In en, this message translates to:
  /// **'Food or preparation'**
  String get foodPreparation;

  /// No description provided for @originalNamesHint.
  ///
  /// In en, this message translates to:
  /// **'Names are in French or English, as provided by the source.'**
  String get originalNamesHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @foodCoverage.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 reference} other{{total} references}} · {unknown} without a confirmed basis.'**
  String foodCoverage(int total, int unknown);

  /// No description provided for @allSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @originalFoodNotice.
  ///
  /// In en, this message translates to:
  /// **'Preparation and language stay in the original name. Missing values, traces and limits are not zero. Each detail includes its source and license.'**
  String get originalFoodNotice;

  /// No description provided for @readOnlyFood.
  ///
  /// In en, this message translates to:
  /// **'Read-only reference without dietary prescription or intake recording.'**
  String get readOnlyFood;

  /// No description provided for @loadingFood.
  ///
  /// In en, this message translates to:
  /// **'Loading foods'**
  String get loadingFood;

  /// No description provided for @noFoodResults.
  ///
  /// In en, this message translates to:
  /// **'No food matches this search. Try a term in its original language or another source.'**
  String get noFoodResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @moreFood.
  ///
  /// In en, this message translates to:
  /// **'Load more foods'**
  String get moreFood;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search and source'**
  String get clearSearch;

  /// No description provided for @loadingComposition.
  ///
  /// In en, this message translates to:
  /// **'Loading composition'**
  String get loadingComposition;

  /// No description provided for @sourceComposition.
  ///
  /// In en, this message translates to:
  /// **'Source composition'**
  String get sourceComposition;

  /// No description provided for @referenceFood.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE FOOD'**
  String get referenceFood;

  /// No description provided for @foodVersionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This food is unavailable. The connection may have failed or the version may have been withdrawn.'**
  String get foodVersionUnavailable;

  /// No description provided for @originalFoodVersion.
  ///
  /// In en, this message translates to:
  /// **'FOOD · ORIGINAL VERSION'**
  String get originalFoodVersion;

  /// No description provided for @foodQueryNotice.
  ///
  /// In en, this message translates to:
  /// **'Source composition reference without dietary prescription. Original names and methods are preserved; missing does not mean zero. This query does not calculate portions or record intake.'**
  String get foodQueryNotice;

  /// No description provided for @refreshComposition.
  ///
  /// In en, this message translates to:
  /// **'Refresh composition'**
  String get refreshComposition;

  /// No description provided for @useFoodVersion.
  ///
  /// In en, this message translates to:
  /// **'Use this version to record intake'**
  String get useFoodVersion;

  /// No description provided for @sourceLicense.
  ///
  /// In en, this message translates to:
  /// **'Source and license'**
  String get sourceLicense;

  /// No description provided for @publication.
  ///
  /// In en, this message translates to:
  /// **'Publication'**
  String get publication;

  /// No description provided for @provenanceConditions.
  ///
  /// In en, this message translates to:
  /// **'Provenance and conditions'**
  String get provenanceConditions;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @originalNutrients.
  ///
  /// In en, this message translates to:
  /// **'Original nutrients and values'**
  String get originalNutrients;

  /// No description provided for @nutrientMethodsNotice.
  ///
  /// In en, this message translates to:
  /// **'Different methods and columns remain separate. Each value shows its own basis; no portion is calculated.'**
  String get nutrientMethodsNotice;

  /// No description provided for @originalCell.
  ///
  /// In en, this message translates to:
  /// **'Original cell'**
  String get originalCell;

  /// No description provided for @basisUnknown.
  ///
  /// In en, this message translates to:
  /// **'Composition basis unknown'**
  String get basisUnknown;

  /// No description provided for @sourceBasis.
  ///
  /// In en, this message translates to:
  /// **'Source basis: {quantity} {unit}'**
  String sourceBasis(String quantity, String unit);

  /// No description provided for @perQuantity.
  ///
  /// In en, this message translates to:
  /// **'Per {quantity} {unit}'**
  String perQuantity(String quantity, String unit);

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @valueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Value unavailable'**
  String get valueUnavailable;

  /// No description provided for @limitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Limit unavailable'**
  String get limitUnavailable;

  /// No description provided for @lessThanValue.
  ///
  /// In en, this message translates to:
  /// **'< {value}{unit} (limit; no exact value)'**
  String lessThanValue(String value, String unit);

  /// No description provided for @traceValue.
  ///
  /// In en, this message translates to:
  /// **'Trace (no exact quantity)'**
  String get traceValue;

  /// No description provided for @notInformed.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notInformed;

  /// No description provided for @presentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Present; quantity unknown'**
  String get presentUnknown;

  /// No description provided for @unparsedValue.
  ///
  /// In en, this message translates to:
  /// **'Original value not interpreted: {value}'**
  String unparsedValue(String value);

  /// No description provided for @basisUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Basis not confirmed for this value'**
  String get basisUnconfirmed;

  /// No description provided for @columnDeclares.
  ///
  /// In en, this message translates to:
  /// **'Column declares'**
  String get columnDeclares;

  /// No description provided for @foodSearchTooLong.
  ///
  /// In en, this message translates to:
  /// **'The search is too long. Use part of the original name.'**
  String get foodSearchTooLong;

  /// No description provided for @foodQueryFailed.
  ///
  /// In en, this message translates to:
  /// **'Foods could not be loaded. Check your connection and try again.'**
  String get foodQueryFailed;

  /// No description provided for @foodMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'More foods could not be loaded. Try again.'**
  String get foodMoreFailed;

  /// No description provided for @catalogQueryFailed.
  ///
  /// In en, this message translates to:
  /// **'The library could not be loaded. Check your connection and try again.'**
  String get catalogQueryFailed;

  /// No description provided for @catalogMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The next page could not be loaded. Try again.'**
  String get catalogMoreFailed;

  /// No description provided for @allKnownValues.
  ///
  /// In en, this message translates to:
  /// **'All provided values'**
  String get allKnownValues;

  /// No description provided for @sourceFilters.
  ///
  /// In en, this message translates to:
  /// **'Source filters'**
  String get sourceFilters;

  /// No description provided for @unknownNotAssumed.
  ///
  /// In en, this message translates to:
  /// **'Missing values are not adapted or classified by assumption.'**
  String get unknownNotAssumed;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @modality.
  ///
  /// In en, this message translates to:
  /// **'Activity type'**
  String get modality;

  /// No description provided for @unknownEnvironment.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record without an environment.} other{{count} records without an environment.}}'**
  String unknownEnvironment(int count);

  /// No description provided for @unknownAudience.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record without an audience.} other{{count} records without an audience.}}'**
  String unknownAudience(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'MOVEMENT · SOURCE · AVAILABILITY'**
  String get librarySubtitle;

  /// No description provided for @metadataOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only. These records are not instructions or programs approved for practice.'**
  String get metadataOnly;

  /// No description provided for @movements.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get movements;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @loadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading library'**
  String get loadingLibrary;

  /// No description provided for @noProgramsBatch.
  ///
  /// In en, this message translates to:
  /// **'No authorized program in this batch.'**
  String get noProgramsBatch;

  /// No description provided for @noMetadataFilters.
  ///
  /// In en, this message translates to:
  /// **'No metadata matches these filters.'**
  String get noMetadataFilters;

  /// No description provided for @audienceScope.
  ///
  /// In en, this message translates to:
  /// **'Older adults, caregivers, home, parks and gyms remain in scope. The source must provide requirements and permission for each use.'**
  String get audienceScope;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @titleNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Title not provided by the source'**
  String get titleNotProvided;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Modular collection'**
  String get collection;

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @languageNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Language not provided'**
  String get languageNotProvided;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @licenseNotProvided.
  ///
  /// In en, this message translates to:
  /// **'License not provided'**
  String get licenseNotProvided;

  /// No description provided for @sourceInDetail.
  ///
  /// In en, this message translates to:
  /// **'Source and license in details · Read only'**
  String get sourceInDetail;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened. You can copy the URL below.'**
  String get linkFailed;

  /// No description provided for @loadingDetail.
  ///
  /// In en, this message translates to:
  /// **'Loading details'**
  String get loadingDetail;

  /// No description provided for @originAvailability.
  ///
  /// In en, this message translates to:
  /// **'Source and availability'**
  String get originAvailability;

  /// No description provided for @libraryUpper.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY'**
  String get libraryUpper;

  /// No description provided for @referenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reference unavailable'**
  String get referenceUnavailable;

  /// No description provided for @recordWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'This record is unavailable or has been withdrawn. Return to the library.'**
  String get recordWithdrawn;

  /// No description provided for @recordUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'This record could not be confirmed. Connect and try again.'**
  String get recordUnconfirmed;

  /// No description provided for @backLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to library'**
  String get backLibrary;

  /// No description provided for @notProvidedSource.
  ///
  /// In en, this message translates to:
  /// **'Not provided by the source'**
  String get notProvidedSource;

  /// No description provided for @libraryReadOnlyUpper.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY · READ ONLY'**
  String get libraryReadOnlyUpper;

  /// No description provided for @referenceMovement.
  ///
  /// In en, this message translates to:
  /// **'Reference movement'**
  String get referenceMovement;

  /// No description provided for @sourceProgram.
  ///
  /// In en, this message translates to:
  /// **'Source program'**
  String get sourceProgram;

  /// No description provided for @noPracticeContent.
  ///
  /// In en, this message translates to:
  /// **'Read only. Instructions, doses and media are not approved for use in the app.'**
  String get noPracticeContent;

  /// No description provided for @authorship.
  ///
  /// In en, this message translates to:
  /// **'Authorship and contribution'**
  String get authorship;

  /// No description provided for @authorsProvided.
  ///
  /// In en, this message translates to:
  /// **'Provided authors'**
  String get authorsProvided;

  /// No description provided for @sourceCredits.
  ///
  /// In en, this message translates to:
  /// **'Source credits'**
  String get sourceCredits;

  /// No description provided for @attribution.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get attribution;

  /// No description provided for @openOriginalSource.
  ///
  /// In en, this message translates to:
  /// **'Open original source'**
  String get openOriginalSource;

  /// No description provided for @openLicense.
  ///
  /// In en, this message translates to:
  /// **'Open license'**
  String get openLicense;

  /// No description provided for @noticeNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Notice not provided'**
  String get noticeNotProvided;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @audienceSupport.
  ///
  /// In en, this message translates to:
  /// **'Audience, environment and support'**
  String get audienceSupport;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportRequired.
  ///
  /// In en, this message translates to:
  /// **'Required by the source'**
  String get supportRequired;

  /// No description provided for @supportNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Not required according to the source'**
  String get supportNotRequired;

  /// No description provided for @supportReference.
  ///
  /// In en, this message translates to:
  /// **'Support reference'**
  String get supportReference;

  /// No description provided for @providedRequirements.
  ///
  /// In en, this message translates to:
  /// **'Provided requirements'**
  String get providedRequirements;

  /// No description provided for @titleCredits.
  ///
  /// In en, this message translates to:
  /// **'Original title credits'**
  String get titleCredits;

  /// No description provided for @titleLicense.
  ///
  /// In en, this message translates to:
  /// **'Title license'**
  String get titleLicense;

  /// No description provided for @declaredChanges.
  ///
  /// In en, this message translates to:
  /// **'Declared changes'**
  String get declaredChanges;

  /// No description provided for @deliveryConditions.
  ///
  /// In en, this message translates to:
  /// **'Delivery conditions'**
  String get deliveryConditions;

  /// No description provided for @queriedVersion.
  ///
  /// In en, this message translates to:
  /// **'Queried version'**
  String get queriedVersion;

  /// No description provided for @versionHash.
  ///
  /// In en, this message translates to:
  /// **'Imported version hash:'**
  String get versionHash;

  /// No description provided for @publishedVersion.
  ///
  /// In en, this message translates to:
  /// **'Version published by the source'**
  String get publishedVersion;

  /// No description provided for @originalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Original language'**
  String get originalLanguage;
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

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
  /// **'Available flows use the selected language. New features will be localized as they are implemented.'**
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

  /// No description provided for @portionYours.
  ///
  /// In en, this message translates to:
  /// **'Your portion.'**
  String get portionYours;

  /// No description provided for @correctIntake.
  ///
  /// In en, this message translates to:
  /// **'Correct intake'**
  String get correctIntake;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @consumedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity consumed'**
  String get consumedQuantity;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity'**
  String get enterQuantity;

  /// No description provided for @positiveQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity greater than zero, with up to 6 decimal places.'**
  String get positiveQuantity;

  /// No description provided for @quantityUnit.
  ///
  /// In en, this message translates to:
  /// **'Quantity unit'**
  String get quantityUnit;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'Grams (g)'**
  String get grams;

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'Milliliters (ml)'**
  String get milliliters;

  /// No description provided for @quantityHow.
  ///
  /// In en, this message translates to:
  /// **'How did you get the quantity?'**
  String get quantityHow;

  /// No description provided for @measuredChoice.
  ///
  /// In en, this message translates to:
  /// **'I measured it with a scale or container'**
  String get measuredChoice;

  /// No description provided for @estimatedChoice.
  ///
  /// In en, this message translates to:
  /// **'I estimated it'**
  String get estimatedChoice;

  /// No description provided for @chooseEvidence.
  ///
  /// In en, this message translates to:
  /// **'Choose measured or estimated.'**
  String get chooseEvidence;

  /// No description provided for @portionComposition.
  ///
  /// In en, this message translates to:
  /// **'Portion composition'**
  String get portionComposition;

  /// No description provided for @calculationOnSave.
  ///
  /// In en, this message translates to:
  /// **'The API confirms the calculation when saving. Unknown values do not become zero; different methods and units are not added together.'**
  String get calculationOnSave;

  /// No description provided for @originPreparation.
  ///
  /// In en, this message translates to:
  /// **'Source and preparation'**
  String get originPreparation;

  /// No description provided for @sourceVersion.
  ///
  /// In en, this message translates to:
  /// **'Source and version'**
  String get sourceVersion;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get origin;

  /// No description provided for @observedPreparation.
  ///
  /// In en, this message translates to:
  /// **'Observed preparation (optional)'**
  String get observedPreparation;

  /// No description provided for @preparationNote.
  ///
  /// In en, this message translates to:
  /// **'Preparation is your note and does not change the source composition. Grams are not converted to milliliters without a verified density.'**
  String get preparationNote;

  /// No description provided for @deviceDateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Device date and time, confirmed by you.'**
  String get deviceDateConfirmed;

  /// No description provided for @intakeConfirmationNotice.
  ///
  /// In en, this message translates to:
  /// **'Confirm only what you consumed. No diet is prescribed and no exercise compensation is applied. Estimated quantities will be marked as estimated.'**
  String get intakeConfirmationNotice;

  /// No description provided for @intakeUncertain.
  ///
  /// In en, this message translates to:
  /// **'The response has not been confirmed. Retry with the same data or return to check the history.'**
  String get intakeUncertain;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get confirming;

  /// No description provided for @retryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Retry confirmation'**
  String get retryConfirmation;

  /// No description provided for @confirmIntake.
  ///
  /// In en, this message translates to:
  /// **'Confirm intake'**
  String get confirmIntake;

  /// No description provided for @confirmCorrection.
  ///
  /// In en, this message translates to:
  /// **'Confirm correction'**
  String get confirmCorrection;

  /// No description provided for @createOwnFood.
  ///
  /// In en, this message translates to:
  /// **'Create a private food'**
  String get createOwnFood;

  /// No description provided for @ownDataUpper.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE · DATA PROVIDED BY YOU'**
  String get ownDataUpper;

  /// No description provided for @foodIdentity.
  ///
  /// In en, this message translates to:
  /// **'Food identity'**
  String get foodIdentity;

  /// No description provided for @ownFoodNotice.
  ///
  /// In en, this message translates to:
  /// **'A private record, separate from the public catalog. Creating this food does not record intake or imply editorial or clinical review.'**
  String get ownFoodNotice;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get foodName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter the name.'**
  String get enterName;

  /// No description provided for @declaredPreparation.
  ///
  /// In en, this message translates to:
  /// **'Declared preparation (optional)'**
  String get declaredPreparation;

  /// No description provided for @compositionBasis.
  ///
  /// In en, this message translates to:
  /// **'Composition basis'**
  String get compositionBasis;

  /// No description provided for @basisNotice.
  ///
  /// In en, this message translates to:
  /// **'If known, enter the basis the nutrients refer to. Leave unknown values blank. Missing does not mean zero.'**
  String get basisNotice;

  /// No description provided for @optionalBasisQuantity.
  ///
  /// In en, this message translates to:
  /// **'Basis quantity (optional)'**
  String get optionalBasisQuantity;

  /// No description provided for @positiveBasis.
  ///
  /// In en, this message translates to:
  /// **'The basis must be greater than zero.'**
  String get positiveBasis;

  /// No description provided for @basisUnit.
  ///
  /// In en, this message translates to:
  /// **'Basis unit'**
  String get basisUnit;

  /// No description provided for @declaredNutrients.
  ///
  /// In en, this message translates to:
  /// **'Declared nutrients'**
  String get declaredNutrients;

  /// No description provided for @noAssumedNutrients.
  ///
  /// In en, this message translates to:
  /// **'Do not guess values. An empty field keeps the value unknown; entering 0 declares zero.'**
  String get noAssumedNutrients;

  /// No description provided for @nutrientName.
  ///
  /// In en, this message translates to:
  /// **'Nutrient name'**
  String get nutrientName;

  /// No description provided for @enterNutrientName.
  ///
  /// In en, this message translates to:
  /// **'Enter the nutrient name.'**
  String get enterNutrientName;

  /// No description provided for @optionalBasisValue.
  ///
  /// In en, this message translates to:
  /// **'Value for the basis (optional)'**
  String get optionalBasisValue;

  /// No description provided for @decimalOrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Enter a decimal or leave it unknown.'**
  String get decimalOrUnknown;

  /// No description provided for @nutrientUnit.
  ///
  /// In en, this message translates to:
  /// **'Nutrient unit'**
  String get nutrientUnit;

  /// No description provided for @removeField.
  ///
  /// In en, this message translates to:
  /// **'Remove this field'**
  String get removeField;

  /// No description provided for @addNutrient.
  ///
  /// In en, this message translates to:
  /// **'Add a known or unknown nutrient'**
  String get addNutrient;

  /// No description provided for @ownFoodUncertain.
  ///
  /// In en, this message translates to:
  /// **'Response not confirmed. Retry with the same data to avoid duplication.'**
  String get ownFoodUncertain;

  /// No description provided for @saveFoodOnly.
  ///
  /// In en, this message translates to:
  /// **'Save the food only'**
  String get saveFoodOnly;

  /// No description provided for @ownFoodSaved.
  ///
  /// In en, this message translates to:
  /// **'Private food saved. No intake was recorded.'**
  String get ownFoodSaved;

  /// No description provided for @intake.
  ///
  /// In en, this message translates to:
  /// **'Intake'**
  String get intake;

  /// No description provided for @myFoods.
  ///
  /// In en, this message translates to:
  /// **'My foods'**
  String get myFoods;

  /// No description provided for @confirmedDiaryUpper.
  ///
  /// In en, this message translates to:
  /// **'DIARY · RECORDS CONFIRMED BY YOU'**
  String get confirmedDiaryUpper;

  /// No description provided for @searchRecordFood.
  ///
  /// In en, this message translates to:
  /// **'Search for food and record intake'**
  String get searchRecordFood;

  /// No description provided for @diaryNoPrescription.
  ///
  /// In en, this message translates to:
  /// **'Records confirmed by you. No diet, target or exercise compensation is created.'**
  String get diaryNoPrescription;

  /// No description provided for @loadingNutrition.
  ///
  /// In en, this message translates to:
  /// **'Loading nutrition'**
  String get loadingNutrition;

  /// No description provided for @noIntakeDay.
  ///
  /// In en, this message translates to:
  /// **'No intake recorded for this day.'**
  String get noIntakeDay;

  /// No description provided for @noIntakeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose another date or search for food to record what you consumed. No record does not mean zero intake.'**
  String get noIntakeHint;

  /// No description provided for @measuredShort.
  ///
  /// In en, this message translates to:
  /// **'measured'**
  String get measuredShort;

  /// No description provided for @estimatedShort.
  ///
  /// In en, this message translates to:
  /// **'estimated'**
  String get estimatedShort;

  /// No description provided for @moreRecords.
  ///
  /// In en, this message translates to:
  /// **'Load more records'**
  String get moreRecords;

  /// No description provided for @subtotalLimit.
  ///
  /// In en, this message translates to:
  /// **'Subtotal limit exceeded'**
  String get subtotalLimit;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// No description provided for @column.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get column;

  /// No description provided for @privateFoodsUpper.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE FOODS · NOT PUBLISHED'**
  String get privateFoodsUpper;

  /// No description provided for @privateFoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Only your private foods. Creating a food does not record intake or publish it in the catalog.'**
  String get privateFoodsHint;

  /// No description provided for @searchMyFoods.
  ///
  /// In en, this message translates to:
  /// **'Search my foods'**
  String get searchMyFoods;

  /// No description provided for @loadingPrivateFoods.
  ///
  /// In en, this message translates to:
  /// **'Loading private foods'**
  String get loadingPrivateFoods;

  /// No description provided for @noPrivateResults.
  ///
  /// In en, this message translates to:
  /// **'No private food matches this search.'**
  String get noPrivateResults;

  /// No description provided for @noPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Search another name or create a private food. Enter only known data; do not guess nutrients.'**
  String get noPrivateHint;

  /// No description provided for @privatePortionHint.
  ///
  /// In en, this message translates to:
  /// **'Private · tap to enter a portion'**
  String get privatePortionHint;

  /// No description provided for @morePrivateFoods.
  ///
  /// In en, this message translates to:
  /// **'Load more private foods'**
  String get morePrivateFoods;

  /// No description provided for @deleteIntakeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this intake?'**
  String get deleteIntakeQuestion;

  /// No description provided for @deleteIntakeNotice.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from subtotals and active history. The record and its corrections remain private in exports until account deletion. The food remains saved.'**
  String get deleteIntakeNotice;

  /// No description provided for @deleteIntake.
  ///
  /// In en, this message translates to:
  /// **'Delete intake'**
  String get deleteIntake;

  /// No description provided for @intakeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Intake confirmed'**
  String get intakeConfirmed;

  /// No description provided for @privateDiaryUpper.
  ///
  /// In en, this message translates to:
  /// **'DIARY · PRIVATE RECORD'**
  String get privateDiaryUpper;

  /// No description provided for @quantityMeasured.
  ///
  /// In en, this message translates to:
  /// **'Measured quantity'**
  String get quantityMeasured;

  /// No description provided for @quantityEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated quantity'**
  String get quantityEstimated;

  /// No description provided for @deviceTime.
  ///
  /// In en, this message translates to:
  /// **'Time on this device'**
  String get deviceTime;

  /// No description provided for @recordedZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone provided in the record'**
  String get recordedZone;

  /// No description provided for @notedPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation note'**
  String get notedPreparation;

  /// No description provided for @compositionOrigin.
  ///
  /// In en, this message translates to:
  /// **'Composition source'**
  String get compositionOrigin;

  /// No description provided for @preservedCalculation.
  ///
  /// In en, this message translates to:
  /// **'Source and calculation preserved'**
  String get preservedCalculation;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @fractionNotice.
  ///
  /// In en, this message translates to:
  /// **'The exact fraction is preserved. Display is rounded to 6 decimal places. Traces, limits, incompatible units and missing bases do not become zero. Preparation does not change composition.'**
  String get fractionNotice;

  /// No description provided for @requestUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Request not confirmed'**
  String get requestUnconfirmed;

  /// No description provided for @correctIntakeAction.
  ///
  /// In en, this message translates to:
  /// **'Correct quantity, preparation or time'**
  String get correctIntakeAction;

  /// No description provided for @deleteThisIntake.
  ///
  /// In en, this message translates to:
  /// **'Delete this intake'**
  String get deleteThisIntake;

  /// No description provided for @thisPortionComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition of this portion'**
  String get thisPortionComposition;

  /// No description provided for @portionSourceNotice.
  ///
  /// In en, this message translates to:
  /// **'These values belong to the source version and method. Unknown does not mean zero.'**
  String get portionSourceNotice;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @basisOriginalCalculation.
  ///
  /// In en, this message translates to:
  /// **'Basis, original value and calculation'**
  String get basisOriginalCalculation;

  /// No description provided for @originalState.
  ///
  /// In en, this message translates to:
  /// **'Original state'**
  String get originalState;

  /// No description provided for @cell.
  ///
  /// In en, this message translates to:
  /// **'cell'**
  String get cell;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'limit'**
  String get limit;

  /// No description provided for @basis.
  ///
  /// In en, this message translates to:
  /// **'Basis'**
  String get basis;

  /// No description provided for @factor.
  ///
  /// In en, this message translates to:
  /// **'Factor'**
  String get factor;

  /// No description provided for @notCalculable.
  ///
  /// In en, this message translates to:
  /// **'not calculable'**
  String get notCalculable;

  /// No description provided for @exactFraction.
  ///
  /// In en, this message translates to:
  /// **'Exact fraction'**
  String get exactFraction;

  /// No description provided for @preparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparation;

  /// No description provided for @checkBeforeLeaving.
  ///
  /// In en, this message translates to:
  /// **'Check before leaving'**
  String get checkBeforeLeaving;

  /// No description provided for @leaveUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveUnsaved;

  /// No description provided for @uncertainDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'The response to the submission has not been confirmed. Leaving does not cancel the request. Check the history before creating another record; to retry safely, stay and use the same confirmation.'**
  String get uncertainDraftNotice;

  /// No description provided for @unsavedDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Changes in this form have not been saved. You can keep filling it in or discard only this draft.'**
  String get unsavedDraftNotice;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get continueEditing;

  /// No description provided for @leaveCheckHistory.
  ///
  /// In en, this message translates to:
  /// **'Leave and check history'**
  String get leaveCheckHistory;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get discardDraft;

  /// No description provided for @quantityEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity and choose whether it was measured or estimated.'**
  String get quantityEvidenceRequired;

  /// No description provided for @nutritionAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'The account changed. Return to sign-in before continuing.'**
  String get nutritionAccountChanged;

  /// No description provided for @nutritionCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Check the quantity, unit, date, preparation and entered fields.'**
  String get nutritionCheckFields;

  /// No description provided for @nutritionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The food or record is unavailable. Refresh the query.'**
  String get nutritionUnavailable;

  /// No description provided for @nutritionConflict.
  ///
  /// In en, this message translates to:
  /// **'The record or account changed. Refresh the history before correcting it.'**
  String get nutritionConflict;

  /// No description provided for @nutritionRetrySafe.
  ///
  /// In en, this message translates to:
  /// **'The action could not be confirmed. Check the connection and retry. Repeating the same action does not duplicate the record.'**
  String get nutritionRetrySafe;

  /// No description provided for @nutritionActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action could not be confirmed. Try again.'**
  String get nutritionActionFailed;

  /// No description provided for @daySubtotalCount.
  ///
  /// In en, this message translates to:
  /// **'Day subtotals · {count, plural, =1{1 record} other{{count} records}}'**
  String daySubtotalCount(int count);

  /// No description provided for @nutrientCoverage.
  ///
  /// In en, this message translates to:
  /// **'{included} included · {unknown} without a calculable value'**
  String nutrientCoverage(int included, int unknown);

  /// No description provided for @previousCorrections.
  ///
  /// In en, this message translates to:
  /// **'Previous corrections ({count})'**
  String previousCorrections(int count);

  /// No description provided for @revision.
  ///
  /// In en, this message translates to:
  /// **'Revision {number}'**
  String revision(int number);

  /// No description provided for @subtotalNotice.
  ///
  /// In en, this message translates to:
  /// **'Subtotals by source column and method; do not add different methods or units. Estimated quantities remain estimated; missing is not zero. Display is rounded to 6 decimal places; exact fractions are preserved. No targets or exercise compensation.'**
  String get subtotalNotice;

  /// No description provided for @privacyUpper.
  ///
  /// In en, this message translates to:
  /// **'EFFECTIVE POLICY · YOUR ACCOUNT CONTROLS'**
  String get privacyUpper;

  /// No description provided for @processingData.
  ///
  /// In en, this message translates to:
  /// **'Processing data request'**
  String get processingData;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'TrainForge account deleted'**
  String get accountDeleted;

  /// No description provided for @googleAccountKept.
  ///
  /// In en, this message translates to:
  /// **'Your Google account remains active. This account’s private data and sessions were removed from the current TrainForge database.'**
  String get googleAccountKept;

  /// No description provided for @erasureLocalPending.
  ///
  /// In en, this message translates to:
  /// **'Deletion was confirmed by the server. Session cleanup or confirmation on this device is still pending.'**
  String get erasureLocalPending;

  /// No description provided for @finishLocalCleanup.
  ///
  /// In en, this message translates to:
  /// **'Finish local cleanup'**
  String get finishLocalCleanup;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @dataControls.
  ///
  /// In en, this message translates to:
  /// **'Your data and controls'**
  String get dataControls;

  /// No description provided for @retryPolicy.
  ///
  /// In en, this message translates to:
  /// **'Retry loading policy'**
  String get retryPolicy;

  /// No description provided for @backupsRecovery.
  ///
  /// In en, this message translates to:
  /// **'Backups and recovery'**
  String get backupsRecovery;

  /// No description provided for @erasureMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum record after deletion'**
  String get erasureMinimum;

  /// No description provided for @externalCopiesNotice.
  ///
  /// In en, this message translates to:
  /// **'Data you copy or export is under your control; deleting the account does not erase external copies or the device clipboard.'**
  String get externalCopiesNotice;

  /// No description provided for @signInPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to view your account data and request deletion.'**
  String get signInPrivacy;

  /// No description provided for @viewCopyData.
  ///
  /// In en, this message translates to:
  /// **'View and copy my data'**
  String get viewCopyData;

  /// No description provided for @exportPageNotice.
  ///
  /// In en, this message translates to:
  /// **'Paginated by section. Each copy contains only the visible page, without access credentials.'**
  String get exportPageNotice;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data section'**
  String get dataSection;

  /// No description provided for @viewSection.
  ///
  /// In en, this message translates to:
  /// **'View section'**
  String get viewSection;

  /// No description provided for @currentPageOnly.
  ///
  /// In en, this message translates to:
  /// **'This is only the current page. The next page replaces the previous one on screen.'**
  String get currentPageOnly;

  /// No description provided for @noSectionRecords.
  ///
  /// In en, this message translates to:
  /// **'No records in this section.'**
  String get noSectionRecords;

  /// No description provided for @pageCopied.
  ///
  /// In en, this message translates to:
  /// **'Page copied. It may contain personal data.'**
  String get pageCopied;

  /// No description provided for @copyJsonPage.
  ///
  /// In en, this message translates to:
  /// **'Copy this JSON page'**
  String get copyJsonPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my TrainForge account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'This action removes your current data and revokes all sessions. Read the backup limits above. It requires a Google sign-in within the last 15 minutes.'**
  String get deleteAccountNotice;

  /// No description provided for @confirmGoogleAgain.
  ///
  /// In en, this message translates to:
  /// **'Confirm account again with Google'**
  String get confirmGoogleAgain;

  /// No description provided for @readDeletionLimits.
  ///
  /// In en, this message translates to:
  /// **'I have read the limits of deletion, historical copies and the Google account.'**
  String get readDeletionLimits;

  /// No description provided for @requestDeletionIntent.
  ///
  /// In en, this message translates to:
  /// **'Request deletion confirmation'**
  String get requestDeletionIntent;

  /// No description provided for @temporaryDeletionNotice.
  ///
  /// In en, this message translates to:
  /// **'A temporary confirmation was created for this session. Type the exact phrase below; it expires within 5 minutes.'**
  String get temporaryDeletionNotice;

  /// No description provided for @deleteAccountData.
  ///
  /// In en, this message translates to:
  /// **'Delete my account and its data'**
  String get deleteAccountData;

  /// No description provided for @cancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion'**
  String get cancelDeletion;

  /// No description provided for @policyOriginalNotice.
  ///
  /// In en, this message translates to:
  /// **'The effective policy text and notices returned by the API are shown in their original language. Exported data also preserves original values.'**
  String get policyOriginalNotice;

  /// No description provided for @privacySectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get privacySectionAccount;

  /// No description provided for @privacySectionSessions.
  ///
  /// In en, this message translates to:
  /// **'Access sessions'**
  String get privacySectionSessions;

  /// No description provided for @privacySectionEnrollments.
  ///
  /// In en, this message translates to:
  /// **'Enrollments'**
  String get privacySectionEnrollments;

  /// No description provided for @privacySectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get privacySectionSchedule;

  /// No description provided for @privacySectionActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get privacySectionActivities;

  /// No description provided for @privacySectionEvents.
  ///
  /// In en, this message translates to:
  /// **'Activity events'**
  String get privacySectionEvents;

  /// No description provided for @privacySectionFoods.
  ///
  /// In en, this message translates to:
  /// **'Private foods'**
  String get privacySectionFoods;

  /// No description provided for @privacySectionIntakes.
  ///
  /// In en, this message translates to:
  /// **'Intake records'**
  String get privacySectionIntakes;

  /// No description provided for @privacyConfirmPhrase.
  ///
  /// In en, this message translates to:
  /// **'Type EXCLUIR MINHA CONTA to confirm.'**
  String get privacyConfirmPhrase;

  /// No description provided for @privacyRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your account with Google again to authorize deletion.'**
  String get privacyRecentLogin;

  /// No description provided for @privacySessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your session needs confirmation. Sign in with Google again.'**
  String get privacySessionConfirm;

  /// No description provided for @privacyIntentExpired.
  ///
  /// In en, this message translates to:
  /// **'The confirmation expired or does not belong to this session. Request a new confirmation.'**
  String get privacyIntentExpired;

  /// No description provided for @privacyCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'The account was already deleted. Local cleanup is still pending.'**
  String get privacyCleanupPending;

  /// No description provided for @privacyDeletionUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Deletion could not be confirmed. Check the connection and try again.'**
  String get privacyDeletionUnconfirmed;

  /// No description provided for @privacyQueryFailed.
  ///
  /// In en, this message translates to:
  /// **'Data could not be loaded. Check the connection and try again.'**
  String get privacyQueryFailed;

  /// No description provided for @privacyActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action could not be completed. Try again.'**
  String get privacyActionFailed;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get understood;

  /// No description provided for @startingPoint.
  ///
  /// In en, this message translates to:
  /// **'Your starting point'**
  String get startingPoint;

  /// No description provided for @activityProgress.
  ///
  /// In en, this message translates to:
  /// **'Activity and progress'**
  String get activityProgress;

  /// No description provided for @accountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Account and preferences'**
  String get accountPreferences;

  /// No description provided for @versionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help for this version'**
  String get versionHelp;

  /// No description provided for @evaluationUpper.
  ///
  /// In en, this message translates to:
  /// **'EVALUATION VERSION · ACTUAL AVAILABILITY'**
  String get evaluationUpper;

  /// No description provided for @exploreWithoutSetup.
  ///
  /// In en, this message translates to:
  /// **'Explore without setup'**
  String get exploreWithoutSetup;

  /// No description provided for @exploreWithoutSetupHint.
  ///
  /// In en, this message translates to:
  /// **'The movement library and food composition can be browsed now. Sign in with Google for your private intake records.'**
  String get exploreWithoutSetupHint;

  /// No description provided for @setupNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Setup not available yet'**
  String get setupNotAvailable;

  /// No description provided for @setupNotAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Areas, goals, environments, experience, routine and review are not saved in this version. None of these choices was inferred from the Google account. There is no simulated mandatory setup to unlock navigation.'**
  String get setupNotAvailableHint;

  /// No description provided for @scopeCaregivers.
  ///
  /// In en, this message translates to:
  /// **'Home, parks and gyms remain in scope, as do older adults and caregivers. The focus is caregivers exercising for themselves during work breaks. The library does not determine clinical suitability or eligibility.'**
  String get scopeCaregivers;

  /// No description provided for @noActivityRecording.
  ///
  /// In en, this message translates to:
  /// **'Activity recording not available yet'**
  String get noActivityRecording;

  /// No description provided for @noActivityRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Starting, pausing, ending and viewing an activity require the recording service. This version does not create sets, doses, sessions, routes, energy expenditure or workout completion.'**
  String get noActivityRecordingHint;

  /// No description provided for @permissionsDevices.
  ///
  /// In en, this message translates to:
  /// **'Permissions and devices'**
  String get permissionsDevices;

  /// No description provided for @permissionsDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'GPS, sensors, Health Connect and camera are not integrated. This screen does not request permissions or collect location, images or device data. Image and OCR entries are not available either.'**
  String get permissionsDevicesHint;

  /// No description provided for @historyProgress.
  ///
  /// In en, this message translates to:
  /// **'History and progress'**
  String get historyProgress;

  /// No description provided for @historyProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Charts, activity periods, measurements and goals require their own records and calculations. Missing implementation does not mean zero activity. Confirmed intake history remains available through the Diary.'**
  String get historyProgressHint;

  /// No description provided for @googleIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity from Google'**
  String get googleIdentity;

  /// No description provided for @googleIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'Name and email are confirmed at sign-in. Editing them in TrainForge is not available yet. Connection confirmation, sign-out, export and deletion have their own actions in the profile.'**
  String get googleIdentityHint;

  /// No description provided for @devicePreferences.
  ///
  /// In en, this message translates to:
  /// **'Device preferences'**
  String get devicePreferences;

  /// No description provided for @devicePreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, follow device and language are available in preferences. These choices stay on this device and are separate from the account. Units, measurements and goals do not have saved editing yet. Foods preserve source names, bases and units until reviewed translations are available.'**
  String get devicePreferencesHint;

  /// No description provided for @whatToTest.
  ///
  /// In en, this message translates to:
  /// **'What you can test now'**
  String get whatToTest;

  /// No description provided for @whatToTestHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google, browse movements and foods, create private foods and record what you consumed. The Diary lets you check sources, correct and delete intake; Privacy lets you view and copy pages of your data.'**
  String get whatToTestHint;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq;

  /// No description provided for @whyOriginalNames.
  ///
  /// In en, this message translates to:
  /// **'Why are there French and English names?'**
  String get whyOriginalNames;

  /// No description provided for @whyOriginalNamesHint.
  ///
  /// In en, this message translates to:
  /// **'They are original names from Ciqual and CoFID. We do not create translations that could change the food’s identity.'**
  String get whyOriginalNamesHint;

  /// No description provided for @unknownMeansZero.
  ///
  /// In en, this message translates to:
  /// **'Does a trace or unknown value mean zero?'**
  String get unknownMeansZero;

  /// No description provided for @unknownMeansZeroHint.
  ///
  /// In en, this message translates to:
  /// **'No. Missing bases, unknown values, limits and different methods stay explicit. Estimated quantities are also marked.'**
  String get unknownMeansZeroHint;

  /// No description provided for @libraryGuidesTraining.
  ///
  /// In en, this message translates to:
  /// **'Does the library guide my training yet?'**
  String get libraryGuidesTraining;

  /// No description provided for @libraryGuidesTrainingHint.
  ///
  /// In en, this message translates to:
  /// **'Not yet. Metadata is read only; no program, dose, instruction or media has been approved for practice.'**
  String get libraryGuidesTrainingHint;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'How can I report a problem?'**
  String get reportProblem;

  /// No description provided for @reportProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Note the screen, action and expected result for evaluation. Hide email, personal data and records before sharing screenshots. In-app feedback submission is not implemented yet.'**
  String get reportProblemHint;

  /// No description provided for @evaluationConditions.
  ///
  /// In en, this message translates to:
  /// **'Evaluation conditions'**
  String get evaluationConditions;

  /// No description provided for @evaluationConditionsHint.
  ///
  /// In en, this message translates to:
  /// **'The effective data policy comes from the API under Privacy and data. Production terms and a support channel still need to be defined; this text does not replace those documents. There is no prescription, food recognition by photo or automatic target.'**
  String get evaluationConditionsHint;

  /// No description provided for @browseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse library'**
  String get browseLibrary;

  /// No description provided for @browseFoods.
  ///
  /// In en, this message translates to:
  /// **'Browse foods'**
  String get browseFoods;

  /// No description provided for @searchFoodNames.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchFoodNames;

  /// No description provided for @reviewedNamesHint.
  ///
  /// In en, this message translates to:
  /// **'Search the original name or a reviewed name/alias in the selected language. Without review, the original name stays.'**
  String get reviewedNamesHint;

  /// No description provided for @reviewedFoodName.
  ///
  /// In en, this message translates to:
  /// **'Reviewed name in this language'**
  String get reviewedFoodName;

  /// No description provided for @originalFoodName.
  ///
  /// In en, this message translates to:
  /// **'Original name'**
  String get originalFoodName;

  /// No description provided for @nameReviewSource.
  ///
  /// In en, this message translates to:
  /// **'Name review and rights'**
  String get nameReviewSource;

  /// No description provided for @nameCatalogChanged.
  ///
  /// In en, this message translates to:
  /// **'The reviewed names changed. The previous page was discarded; check the refreshed query.'**
  String get nameCatalogChanged;

  /// No description provided for @foodNameFallback.
  ///
  /// In en, this message translates to:
  /// **'No reviewed name in this language. The original source name is shown.'**
  String get foodNameFallback;

  /// No description provided for @retryReadPreference.
  ///
  /// In en, this message translates to:
  /// **'Try loading the preference again'**
  String get retryReadPreference;

  /// No description provided for @readingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Loading preference'**
  String get readingPreferences;
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageIntro => 'Choose the interface language on this device.';

  @override
  String get languageScope =>
      'This choice does not change your account, original foods or records.';

  @override
  String get contentOriginal =>
      'Source names and text stay in their original language when no reviewed translation is available.';

  @override
  String get languageProgress =>
      'Available flows use the selected language. New features will be localized as they are implemented.';

  @override
  String get followDevice => 'Use device language';

  @override
  String get languageUnavailable => 'Language settings are unavailable here.';

  @override
  String get languageFallback =>
      'The preference could not be read. The device language is being used.';

  @override
  String get languageSaveFailed =>
      'The language could not be saved. Try again.';

  @override
  String get languageSaveUncertain =>
      'The language was applied, but saving was not confirmed. Try saving again.';

  @override
  String get savingLanguage => 'Saving language';

  @override
  String get retrySave => 'Try saving again';

  @override
  String get retry => 'Try again';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceTitle => 'Your pace, your theme.';

  @override
  String get appearanceIntro =>
      'This choice stays on this device after you close the app. Your account data is unchanged.';

  @override
  String get appearanceUnavailable =>
      'Appearance settings are unavailable here.';

  @override
  String get themeSystem => 'Use device theme';

  @override
  String get themeSystemHint => 'Follows the light or dark system theme.';

  @override
  String get light => 'Light';

  @override
  String get lightHint => 'The original identity on light surfaces.';

  @override
  String get dark => 'Dark';

  @override
  String get darkHint => 'Dark surfaces with adapted contrast.';

  @override
  String get savingAppearance => 'Saving appearance';

  @override
  String get accessibilityDevice =>
      'Text size and reduced motion follow your device accessibility settings.';

  @override
  String get welcome => 'Good to have you here.';

  @override
  String get welcomeHint => 'Sign in to continue your routine.';

  @override
  String get waitingGoogle => 'Waiting for Google confirmation';

  @override
  String get connecting => 'Connecting…';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get noAccount => 'Don\'t have an account yet?';

  @override
  String get createGoogle => 'Create an account with Google';

  @override
  String get googleOnly =>
      'This version uses Google sign-in. Email and Apple sign-in are not available yet.';

  @override
  String get firstAccess => 'First access and setup';

  @override
  String get exploreFirst => 'Explore before signing in';

  @override
  String get publicCatalog => 'Browse the library without signing in';

  @override
  String get publicFood => 'Browse foods without recording intake';

  @override
  String get privacy => 'Privacy and data';

  @override
  String get preparing => 'Preparing TrainForge';

  @override
  String get restoringSession => 'Confirming your session';

  @override
  String get confirmingSession => 'Confirming session';

  @override
  String get today => 'Today';

  @override
  String get plans => 'Plans';

  @override
  String get activity => 'Activity';

  @override
  String get diary => 'Diary';

  @override
  String get evolution => 'Progress';

  @override
  String get openProfile => 'Open profile';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get yourSpace => 'Your space.';

  @override
  String get connected => 'Account connected';

  @override
  String get accountData => 'Account and personal data';

  @override
  String get identityHint => 'Google identity, export and deletion';

  @override
  String get goalsRoutine => 'Goals and routine';

  @override
  String get equipmentDays => 'Equipment, days and activities';

  @override
  String get preferences => 'Preferences';

  @override
  String get preferenceHint => 'Appearance and device accessibility';

  @override
  String get devicesPermissions => 'Devices and permissions';

  @override
  String get devicesHint => 'Health Connect, location and camera';

  @override
  String get privacyHint => 'Export, deletion and current policy';

  @override
  String get helpEvaluation => 'Help and evaluation terms';

  @override
  String get helpHint => 'Questions, sources and available features';

  @override
  String get confirmConnection => 'Confirm connection';

  @override
  String get signOut => 'Sign out of this session';

  @override
  String get languageNames =>
      'Brazilian Portuguese, European Portuguese, English and Spanish';

  @override
  String get sessionTimeout =>
      'Session confirmation took longer than expected. Your session was preserved; retry or browse the library without signing in.';

  @override
  String get googleConfiguration =>
      'Google sign-in is not configured in this environment. Check the evaluation guide.';

  @override
  String get authConfiguration =>
      'The authentication environment needs configuration. Check the evaluation guide.';

  @override
  String get sessionExpired =>
      'The session expired or was revoked. Sign in with Google again.';

  @override
  String get rateLimited => 'Too many attempts. Wait a minute and try again.';

  @override
  String get authUnavailable =>
      'The authentication service is unavailable. Try again later.';

  @override
  String get signOutUnconfirmed =>
      'Sign-out was not confirmed. Connect to the internet and try signing out again.';

  @override
  String get signInFailed =>
      'Sign-in failed. Check your connection and try again.';

  @override
  String get sessionOffline =>
      'The connection could not be confirmed. Your session was preserved; try again.';

  @override
  String get actionFailed => 'This action could not be completed. Try again.';

  @override
  String get appearanceInvalid =>
      'The previous preference could not be used. The device theme is being used.';

  @override
  String get appearanceReadFailed =>
      'The saved appearance could not be read. The device theme is being used.';

  @override
  String get appearanceSaveUncertain =>
      'The appearance was applied, but saving was not confirmed. Try again.';

  @override
  String get appearanceSaveFailed =>
      'The appearance could not be saved. Try again.';

  @override
  String get moveNow => 'Let\'s move!';

  @override
  String moveWithName(String name) {
    return 'Let\'s move, $name!';
  }

  @override
  String get dailyRhythm => 'Your pace, every day';

  @override
  String get strongerDaily => 'A LITTLE STRONGER, EVERY DAY';

  @override
  String get nextMovement => 'Your next movement';

  @override
  String get libraryReadOnly =>
      'Reference library. Guided practice is not available yet.';

  @override
  String get yourWeek => 'Your week';

  @override
  String get diaryByDate => 'Browse the food diary by date.';

  @override
  String get yourDay => 'Your day';

  @override
  String get loadingDayData => 'Loading your recorded day data';

  @override
  String get loadingDayRecords => 'Loading day records';

  @override
  String get dayUpdateFailed => 'The day could not be updated.';

  @override
  String get dayUnconfirmed =>
      'The data was not confirmed. This query does not create or delete intake records.';

  @override
  String get retryUpdate => 'Try updating again';

  @override
  String get energyNoSubtotal => 'energy without a confirmed single subtotal';

  @override
  String get energySourceMethod => 'kcal · one source method';

  @override
  String get activityUnavailable => 'activity not available yet';

  @override
  String get summaryLimit =>
      'The summary limit was exceeded. Check the history; no partial total is presented as complete.';

  @override
  String quantityEvidenceCounts(int measured, int estimated) {
    String _temp0 = intl.Intl.pluralLogic(
      measured,
      locale: localeName,
      other: '$measured measured quantities',
      one: '1 measured quantity',
    );
    String _temp1 = intl.Intl.pluralLogic(
      estimated,
      locale: localeName,
      other: '$estimated estimated quantities',
      one: '1 estimated quantity',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get originMethodDiary => 'Source and method in the diary.';

  @override
  String get myNutrition => 'My nutrition';

  @override
  String get loadingRecords => 'Loading records…';

  @override
  String get openHistoryRetry => 'Open history and try updating';

  @override
  String get noConfirmedToday => 'No confirmed intake for this day';

  @override
  String get viewRecordsOrigin => 'View records and sources';

  @override
  String confirmedDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed intakes for this day · view sources',
      one: '1 confirmed intake for this day · view source',
      zero: 'No confirmed intake for this day',
    );
    return '$_temp0';
  }

  @override
  String get whatToday => 'What would you like today?';

  @override
  String get exploreActivities => 'Walk, run, explore another activity';

  @override
  String get updateDay => 'Refresh the day';

  @override
  String viewFoodDay(String date) {
    return 'View intake for $date';
  }

  @override
  String get findMovement => 'Find your movement.';

  @override
  String get atYourPace => 'With guidance, at your pace.';

  @override
  String get searchUpper => 'SEARCH';

  @override
  String get movementSearchHint => 'Movement, activity or source';

  @override
  String get loadingPrograms => 'Loading available programs';

  @override
  String get programsUnconfirmed =>
      'Programs could not be loaded. Availability was not confirmed.';

  @override
  String get programsUnavailable => 'Programs not available yet';

  @override
  String get browsePrograms => 'Browse programs';

  @override
  String get noPracticeProgram =>
      'No program has been approved for practice. Browse the available references.';

  @override
  String get viewRequirements => 'View sources, requirements and availability';

  @override
  String get exploreModalities => 'Explore activities';

  @override
  String get referenceLibrary => 'Reference library · read only';

  @override
  String get createMyPlan => 'Create my plan';

  @override
  String get organizeWeek => 'Choose exercises and organize the week';

  @override
  String get compositionUnavailable => 'Composition unavailable';

  @override
  String get helpStart => 'Help me get started';

  @override
  String get audiencesEnvironments =>
      'Home, park, gym, older adults and caregivers';

  @override
  String get eatSimply => 'Eating well, made simple.';

  @override
  String get foodDiaryUpper => 'FOOD DIARY';

  @override
  String get loadingQuery => 'Loading…';

  @override
  String get queryUnavailable => 'Query unavailable';

  @override
  String get sourceSubtotals => 'View subtotals for each source method.';

  @override
  String get recordedEnergy => 'RECORDED ENERGY';

  @override
  String get energyMethodSubtotal => 'kcal · subtotal for one source method';

  @override
  String get updateDayRecords => 'Refresh day records';

  @override
  String get myRecords => 'My records';

  @override
  String get addFood => 'Add food';

  @override
  String get hydration => 'Hydration';

  @override
  String get waterUnavailable => 'Water tracking is not available yet';

  @override
  String get waterNotImplemented =>
      'Water tracking is not implemented yet. No quantity was filled automatically.';

  @override
  String get planLearn => 'Plan and learn';

  @override
  String get foodGuidanceUnavailable => 'Food guidance is not approved yet';

  @override
  String get planningLearning => 'Planning and learning';

  @override
  String get foodPlansUnavailable =>
      'Meal plans and guidance are not available yet. Sources and their nutrients can still be browsed through the diary.';

  @override
  String get outdoorsCounts => 'Outdoors counts too.';

  @override
  String get activityIntro => 'Walk, run or record your activity.';

  @override
  String get routeUnavailable =>
      'Routes are not available yet. No location is being collected.';

  @override
  String get noWalkKm => 'km · no walking record';

  @override
  String get noActivityMinutes => 'activity minutes unavailable';

  @override
  String get startActivity => 'Start activity';

  @override
  String get quickRecord => 'Quick entry';

  @override
  String get quickUnavailable =>
      'Manual and image entries are not available yet';

  @override
  String get myDevices => 'My devices';

  @override
  String get permissionsSync => 'Permissions, sources and sync';

  @override
  String get yourProgress => 'Look at your progress.';

  @override
  String get historyWithSource => 'YOUR HISTORY, WITH SOURCES';

  @override
  String get chartUnavailable =>
      'Activity progress is not available yet. The chart will appear when records and calculations are implemented.';

  @override
  String get workoutsUnavailable => 'workouts not available yet';

  @override
  String get walkingKmUnavailable => 'walking km unavailable';

  @override
  String get eachRecordCounts => 'Every record counts';

  @override
  String get historyCorrect => 'View history and correct an intake';

  @override
  String get measurementsGoals => 'Measurements and goals';

  @override
  String get configurationUnavailable => 'Setup not available yet';

  @override
  String get searchResults => 'Search results';

  @override
  String get foodReferences => 'FOOD REFERENCES';

  @override
  String searchFor(String query) {
    return 'SEARCH · $query';
  }

  @override
  String get searchOriginal => 'Search by original name';

  @override
  String get foodPreparation => 'Food or preparation';

  @override
  String get originalNamesHint =>
      'Names are in French or English, as provided by the source.';

  @override
  String get search => 'Search';

  @override
  String foodCoverage(int total, int unknown) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total references',
      one: '1 reference',
    );
    return '$_temp0 · $unknown without a confirmed basis.';
  }

  @override
  String get allSources => 'All sources';

  @override
  String get originalFoodNotice =>
      'Preparation and language stay in the original name. Missing values, traces and limits are not zero. Each detail includes its source and license.';

  @override
  String get readOnlyFood =>
      'Read-only reference without dietary prescription or intake recording.';

  @override
  String get loadingFood => 'Loading foods';

  @override
  String get noFoodResults =>
      'No food matches this search. Try a term in its original language or another source.';

  @override
  String get loading => 'Loading…';

  @override
  String get moreFood => 'Load more foods';

  @override
  String get clearSearch => 'Clear search and source';

  @override
  String get loadingComposition => 'Loading composition';

  @override
  String get sourceComposition => 'Source composition';

  @override
  String get referenceFood => 'REFERENCE FOOD';

  @override
  String get foodVersionUnavailable =>
      'This food is unavailable. The connection may have failed or the version may have been withdrawn.';

  @override
  String get originalFoodVersion => 'FOOD · ORIGINAL VERSION';

  @override
  String get foodQueryNotice =>
      'Source composition reference without dietary prescription. Original names and methods are preserved; missing does not mean zero. This query does not calculate portions or record intake.';

  @override
  String get refreshComposition => 'Refresh composition';

  @override
  String get useFoodVersion => 'Use this version to record intake';

  @override
  String get sourceLicense => 'Source and license';

  @override
  String get publication => 'Publication';

  @override
  String get provenanceConditions => 'Provenance and conditions';

  @override
  String get code => 'Code';

  @override
  String get version => 'Version';

  @override
  String get originalNutrients => 'Original nutrients and values';

  @override
  String get nutrientMethodsNotice =>
      'Different methods and columns remain separate. Each value shows its own basis; no portion is calculated.';

  @override
  String get originalCell => 'Original cell';

  @override
  String get basisUnknown => 'Composition basis unknown';

  @override
  String sourceBasis(String quantity, String unit) {
    return 'Source basis: $quantity $unit';
  }

  @override
  String perQuantity(String quantity, String unit) {
    return 'Per $quantity $unit';
  }

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get valueUnavailable => 'Value unavailable';

  @override
  String get limitUnavailable => 'Limit unavailable';

  @override
  String lessThanValue(String value, String unit) {
    return '< $value$unit (limit; no exact value)';
  }

  @override
  String get traceValue => 'Trace (no exact quantity)';

  @override
  String get notInformed => 'Not provided';

  @override
  String get presentUnknown => 'Present; quantity unknown';

  @override
  String unparsedValue(String value) {
    return 'Original value not interpreted: $value';
  }

  @override
  String get basisUnconfirmed => 'Basis not confirmed for this value';

  @override
  String get columnDeclares => 'Column declares';

  @override
  String get foodSearchTooLong =>
      'The search is too long. Use part of the original name.';

  @override
  String get foodQueryFailed =>
      'Foods could not be loaded. Check your connection and try again.';

  @override
  String get foodMoreFailed => 'More foods could not be loaded. Try again.';

  @override
  String get catalogQueryFailed =>
      'The library could not be loaded. Check your connection and try again.';

  @override
  String get catalogMoreFailed =>
      'The next page could not be loaded. Try again.';

  @override
  String get allKnownValues => 'All provided values';

  @override
  String get sourceFilters => 'Source filters';

  @override
  String get unknownNotAssumed =>
      'Missing values are not adapted or classified by assumption.';

  @override
  String get category => 'Category';

  @override
  String get equipment => 'Equipment';

  @override
  String get environment => 'Environment';

  @override
  String get audience => 'Audience';

  @override
  String get modality => 'Activity type';

  @override
  String unknownEnvironment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records without an environment.',
      one: '1 record without an environment.',
    );
    return '$_temp0';
  }

  @override
  String unknownAudience(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records without an audience.',
      one: '1 record without an audience.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get libraryTitle => 'Reference library';

  @override
  String get librarySubtitle => 'MOVEMENT · SOURCE · AVAILABILITY';

  @override
  String get metadataOnly =>
      'Read only. These records are not instructions or programs approved for practice.';

  @override
  String get movements => 'Movements';

  @override
  String get programs => 'Programs';

  @override
  String get filters => 'Filters';

  @override
  String get clear => 'Clear';

  @override
  String get noResults => 'No results';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get loadingLibrary => 'Loading library';

  @override
  String get noProgramsBatch => 'No authorized program in this batch.';

  @override
  String get noMetadataFilters => 'No metadata matches these filters.';

  @override
  String get audienceScope =>
      'Older adults, caregivers, home, parks and gyms remain in scope. The source must provide requirements and permission for each use.';

  @override
  String get loadMore => 'Load more';

  @override
  String get titleNotProvided => 'Title not provided by the source';

  @override
  String get movement => 'Movement';

  @override
  String get collection => 'Modular collection';

  @override
  String get program => 'Program';

  @override
  String get languageNotProvided => 'Language not provided';

  @override
  String get credits => 'Credits';

  @override
  String get licenseNotProvided => 'License not provided';

  @override
  String get sourceInDetail => 'Source and license in details · Read only';

  @override
  String get linkFailed =>
      'The link could not be opened. You can copy the URL below.';

  @override
  String get loadingDetail => 'Loading details';

  @override
  String get originAvailability => 'Source and availability';

  @override
  String get libraryUpper => 'LIBRARY';

  @override
  String get referenceUnavailable => 'Reference unavailable';

  @override
  String get recordWithdrawn =>
      'This record is unavailable or has been withdrawn. Return to the library.';

  @override
  String get recordUnconfirmed =>
      'This record could not be confirmed. Connect and try again.';

  @override
  String get backLibrary => 'Back to library';

  @override
  String get notProvidedSource => 'Not provided by the source';

  @override
  String get libraryReadOnlyUpper => 'LIBRARY · READ ONLY';

  @override
  String get referenceMovement => 'Reference movement';

  @override
  String get sourceProgram => 'Source program';

  @override
  String get noPracticeContent =>
      'Read only. Instructions, doses and media are not approved for use in the app.';

  @override
  String get authorship => 'Authorship and contribution';

  @override
  String get authorsProvided => 'Provided authors';

  @override
  String get sourceCredits => 'Source credits';

  @override
  String get attribution => 'Attribution';

  @override
  String get openOriginalSource => 'Open original source';

  @override
  String get openLicense => 'Open license';

  @override
  String get noticeNotProvided => 'Notice not provided';

  @override
  String get availability => 'Availability';

  @override
  String get audienceSupport => 'Audience, environment and support';

  @override
  String get support => 'Support';

  @override
  String get supportRequired => 'Required by the source';

  @override
  String get supportNotRequired => 'Not required according to the source';

  @override
  String get supportReference => 'Support reference';

  @override
  String get providedRequirements => 'Provided requirements';

  @override
  String get titleCredits => 'Original title credits';

  @override
  String get titleLicense => 'Title license';

  @override
  String get declaredChanges => 'Declared changes';

  @override
  String get deliveryConditions => 'Delivery conditions';

  @override
  String get queriedVersion => 'Queried version';

  @override
  String get versionHash => 'Imported version hash:';

  @override
  String get publishedVersion => 'Version published by the source';

  @override
  String get originalLanguage => 'Original language';

  @override
  String get portionYours => 'Your portion.';

  @override
  String get correctIntake => 'Correct intake';

  @override
  String get quantity => 'Quantity';

  @override
  String get consumedQuantity => 'Quantity consumed';

  @override
  String get enterQuantity => 'Enter the quantity';

  @override
  String get positiveQuantity =>
      'Enter a quantity greater than zero, with up to 6 decimal places.';

  @override
  String get quantityUnit => 'Quantity unit';

  @override
  String get grams => 'Grams (g)';

  @override
  String get milliliters => 'Milliliters (ml)';

  @override
  String get quantityHow => 'How did you get the quantity?';

  @override
  String get measuredChoice => 'I measured it with a scale or container';

  @override
  String get estimatedChoice => 'I estimated it';

  @override
  String get chooseEvidence => 'Choose measured or estimated.';

  @override
  String get portionComposition => 'Portion composition';

  @override
  String get calculationOnSave =>
      'The API confirms the calculation when saving. Unknown values do not become zero; different methods and units are not added together.';

  @override
  String get originPreparation => 'Source and preparation';

  @override
  String get sourceVersion => 'Source and version';

  @override
  String get origin => 'Source';

  @override
  String get observedPreparation => 'Observed preparation (optional)';

  @override
  String get preparationNote =>
      'Preparation is your note and does not change the source composition. Grams are not converted to milliliters without a verified density.';

  @override
  String get deviceDateConfirmed => 'Device date and time, confirmed by you.';

  @override
  String get intakeConfirmationNotice =>
      'Confirm only what you consumed. No diet is prescribed and no exercise compensation is applied. Estimated quantities will be marked as estimated.';

  @override
  String get intakeUncertain =>
      'The response has not been confirmed. Retry with the same data or return to check the history.';

  @override
  String get confirming => 'Confirming…';

  @override
  String get retryConfirmation => 'Retry confirmation';

  @override
  String get confirmIntake => 'Confirm intake';

  @override
  String get confirmCorrection => 'Confirm correction';

  @override
  String get createOwnFood => 'Create a private food';

  @override
  String get ownDataUpper => 'PRIVATE · DATA PROVIDED BY YOU';

  @override
  String get foodIdentity => 'Food identity';

  @override
  String get ownFoodNotice =>
      'A private record, separate from the public catalog. Creating this food does not record intake or imply editorial or clinical review.';

  @override
  String get foodName => 'Food name';

  @override
  String get enterName => 'Enter the name.';

  @override
  String get declaredPreparation => 'Declared preparation (optional)';

  @override
  String get compositionBasis => 'Composition basis';

  @override
  String get basisNotice =>
      'If known, enter the basis the nutrients refer to. Leave unknown values blank. Missing does not mean zero.';

  @override
  String get optionalBasisQuantity => 'Basis quantity (optional)';

  @override
  String get positiveBasis => 'The basis must be greater than zero.';

  @override
  String get basisUnit => 'Basis unit';

  @override
  String get declaredNutrients => 'Declared nutrients';

  @override
  String get noAssumedNutrients =>
      'Do not guess values. An empty field keeps the value unknown; entering 0 declares zero.';

  @override
  String get nutrientName => 'Nutrient name';

  @override
  String get enterNutrientName => 'Enter the nutrient name.';

  @override
  String get optionalBasisValue => 'Value for the basis (optional)';

  @override
  String get decimalOrUnknown => 'Enter a decimal or leave it unknown.';

  @override
  String get nutrientUnit => 'Nutrient unit';

  @override
  String get removeField => 'Remove this field';

  @override
  String get addNutrient => 'Add a known or unknown nutrient';

  @override
  String get ownFoodUncertain =>
      'Response not confirmed. Retry with the same data to avoid duplication.';

  @override
  String get saveFoodOnly => 'Save the food only';

  @override
  String get ownFoodSaved => 'Private food saved. No intake was recorded.';

  @override
  String get intake => 'Intake';

  @override
  String get myFoods => 'My foods';

  @override
  String get confirmedDiaryUpper => 'DIARY · RECORDS CONFIRMED BY YOU';

  @override
  String get searchRecordFood => 'Search for food and record intake';

  @override
  String get diaryNoPrescription =>
      'Records confirmed by you. No diet, target or exercise compensation is created.';

  @override
  String get loadingNutrition => 'Loading nutrition';

  @override
  String get noIntakeDay => 'No intake recorded for this day.';

  @override
  String get noIntakeHint =>
      'Choose another date or search for food to record what you consumed. No record does not mean zero intake.';

  @override
  String get measuredShort => 'measured';

  @override
  String get estimatedShort => 'estimated';

  @override
  String get moreRecords => 'Load more records';

  @override
  String get subtotalLimit => 'Subtotal limit exceeded';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get column => 'Column';

  @override
  String get privateFoodsUpper => 'PRIVATE FOODS · NOT PUBLISHED';

  @override
  String get privateFoodsHint =>
      'Only your private foods. Creating a food does not record intake or publish it in the catalog.';

  @override
  String get searchMyFoods => 'Search my foods';

  @override
  String get loadingPrivateFoods => 'Loading private foods';

  @override
  String get noPrivateResults => 'No private food matches this search.';

  @override
  String get noPrivateHint =>
      'Search another name or create a private food. Enter only known data; do not guess nutrients.';

  @override
  String get privatePortionHint => 'Private · tap to enter a portion';

  @override
  String get morePrivateFoods => 'Load more private foods';

  @override
  String get deleteIntakeQuestion => 'Delete this intake?';

  @override
  String get deleteIntakeNotice =>
      'It will be removed from subtotals and active history. The record and its corrections remain private in exports until account deletion. The food remains saved.';

  @override
  String get deleteIntake => 'Delete intake';

  @override
  String get intakeConfirmed => 'Intake confirmed';

  @override
  String get privateDiaryUpper => 'DIARY · PRIVATE RECORD';

  @override
  String get quantityMeasured => 'Measured quantity';

  @override
  String get quantityEstimated => 'Estimated quantity';

  @override
  String get deviceTime => 'Time on this device';

  @override
  String get recordedZone => 'Time zone provided in the record';

  @override
  String get notedPreparation => 'Preparation note';

  @override
  String get compositionOrigin => 'Composition source';

  @override
  String get preservedCalculation => 'Source and calculation preserved';

  @override
  String get method => 'Method';

  @override
  String get fractionNotice =>
      'The exact fraction is preserved. Display is rounded to 6 decimal places. Traces, limits, incompatible units and missing bases do not become zero. Preparation does not change composition.';

  @override
  String get requestUnconfirmed => 'Request not confirmed';

  @override
  String get correctIntakeAction => 'Correct quantity, preparation or time';

  @override
  String get deleteThisIntake => 'Delete this intake';

  @override
  String get thisPortionComposition => 'Composition of this portion';

  @override
  String get portionSourceNotice =>
      'These values belong to the source version and method. Unknown does not mean zero.';

  @override
  String get reason => 'Reason';

  @override
  String get basisOriginalCalculation =>
      'Basis, original value and calculation';

  @override
  String get originalState => 'Original state';

  @override
  String get cell => 'cell';

  @override
  String get limit => 'limit';

  @override
  String get basis => 'Basis';

  @override
  String get factor => 'Factor';

  @override
  String get notCalculable => 'not calculable';

  @override
  String get exactFraction => 'Exact fraction';

  @override
  String get preparation => 'Preparation';

  @override
  String get checkBeforeLeaving => 'Check before leaving';

  @override
  String get leaveUnsaved => 'Leave without saving?';

  @override
  String get uncertainDraftNotice =>
      'The response to the submission has not been confirmed. Leaving does not cancel the request. Check the history before creating another record; to retry safely, stay and use the same confirmation.';

  @override
  String get unsavedDraftNotice =>
      'Changes in this form have not been saved. You can keep filling it in or discard only this draft.';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get leaveCheckHistory => 'Leave and check history';

  @override
  String get discardDraft => 'Discard draft';

  @override
  String get quantityEvidenceRequired =>
      'Enter a quantity and choose whether it was measured or estimated.';

  @override
  String get nutritionAccountChanged =>
      'The account changed. Return to sign-in before continuing.';

  @override
  String get nutritionCheckFields =>
      'Check the quantity, unit, date, preparation and entered fields.';

  @override
  String get nutritionUnavailable =>
      'The food or record is unavailable. Refresh the query.';

  @override
  String get nutritionConflict =>
      'The record or account changed. Refresh the history before correcting it.';

  @override
  String get nutritionRetrySafe =>
      'The action could not be confirmed. Check the connection and retry. Repeating the same action does not duplicate the record.';

  @override
  String get nutritionActionFailed =>
      'The action could not be confirmed. Try again.';

  @override
  String daySubtotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return 'Day subtotals · $_temp0';
  }

  @override
  String nutrientCoverage(int included, int unknown) {
    return '$included included · $unknown without a calculable value';
  }

  @override
  String previousCorrections(int count) {
    return 'Previous corrections ($count)';
  }

  @override
  String revision(int number) {
    return 'Revision $number';
  }

  @override
  String get subtotalNotice =>
      'Subtotals by source column and method; do not add different methods or units. Estimated quantities remain estimated; missing is not zero. Display is rounded to 6 decimal places; exact fractions are preserved. No targets or exercise compensation.';

  @override
  String get privacyUpper => 'EFFECTIVE POLICY · YOUR ACCOUNT CONTROLS';

  @override
  String get processingData => 'Processing data request';

  @override
  String get accountDeleted => 'TrainForge account deleted';

  @override
  String get googleAccountKept =>
      'Your Google account remains active. This account’s private data and sessions were removed from the current TrainForge database.';

  @override
  String get erasureLocalPending =>
      'Deletion was confirmed by the server. Session cleanup or confirmation on this device is still pending.';

  @override
  String get finishLocalCleanup => 'Finish local cleanup';

  @override
  String get finish => 'Finish';

  @override
  String get dataControls => 'Your data and controls';

  @override
  String get retryPolicy => 'Retry loading policy';

  @override
  String get backupsRecovery => 'Backups and recovery';

  @override
  String get erasureMinimum => 'Minimum record after deletion';

  @override
  String get externalCopiesNotice =>
      'Data you copy or export is under your control; deleting the account does not erase external copies or the device clipboard.';

  @override
  String get signInPrivacy =>
      'Sign in with Google to view your account data and request deletion.';

  @override
  String get viewCopyData => 'View and copy my data';

  @override
  String get exportPageNotice =>
      'Paginated by section. Each copy contains only the visible page, without access credentials.';

  @override
  String get dataSection => 'Data section';

  @override
  String get viewSection => 'View section';

  @override
  String get currentPageOnly =>
      'This is only the current page. The next page replaces the previous one on screen.';

  @override
  String get noSectionRecords => 'No records in this section.';

  @override
  String get pageCopied => 'Page copied. It may contain personal data.';

  @override
  String get copyJsonPage => 'Copy this JSON page';

  @override
  String get nextPage => 'Next page';

  @override
  String get deleteMyAccount => 'Delete my TrainForge account';

  @override
  String get deleteAccountNotice =>
      'This action removes your current data and revokes all sessions. Read the backup limits above. It requires a Google sign-in within the last 15 minutes.';

  @override
  String get confirmGoogleAgain => 'Confirm account again with Google';

  @override
  String get readDeletionLimits =>
      'I have read the limits of deletion, historical copies and the Google account.';

  @override
  String get requestDeletionIntent => 'Request deletion confirmation';

  @override
  String get temporaryDeletionNotice =>
      'A temporary confirmation was created for this session. Type the exact phrase below; it expires within 5 minutes.';

  @override
  String get deleteAccountData => 'Delete my account and its data';

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String get policyOriginalNotice =>
      'The effective policy text and notices returned by the API are shown in their original language. Exported data also preserves original values.';

  @override
  String get privacySectionAccount => 'Account';

  @override
  String get privacySectionSessions => 'Access sessions';

  @override
  String get privacySectionEnrollments => 'Enrollments';

  @override
  String get privacySectionSchedule => 'Schedule';

  @override
  String get privacySectionActivities => 'Activities';

  @override
  String get privacySectionEvents => 'Activity events';

  @override
  String get privacySectionFoods => 'Private foods';

  @override
  String get privacySectionIntakes => 'Intake records';

  @override
  String get privacyConfirmPhrase => 'Type EXCLUIR MINHA CONTA to confirm.';

  @override
  String get privacyRecentLogin =>
      'Confirm your account with Google again to authorize deletion.';

  @override
  String get privacySessionConfirm =>
      'Your session needs confirmation. Sign in with Google again.';

  @override
  String get privacyIntentExpired =>
      'The confirmation expired or does not belong to this session. Request a new confirmation.';

  @override
  String get privacyCleanupPending =>
      'The account was already deleted. Local cleanup is still pending.';

  @override
  String get privacyDeletionUnconfirmed =>
      'Deletion could not be confirmed. Check the connection and try again.';

  @override
  String get privacyQueryFailed =>
      'Data could not be loaded. Check the connection and try again.';

  @override
  String get privacyActionFailed =>
      'The action could not be completed. Try again.';

  @override
  String get understood => 'Got it';

  @override
  String get startingPoint => 'Your starting point';

  @override
  String get activityProgress => 'Activity and progress';

  @override
  String get accountPreferences => 'Account and preferences';

  @override
  String get versionHelp => 'Help for this version';

  @override
  String get evaluationUpper => 'EVALUATION VERSION · ACTUAL AVAILABILITY';

  @override
  String get exploreWithoutSetup => 'Explore without setup';

  @override
  String get exploreWithoutSetupHint =>
      'The movement library and food composition can be browsed now. Sign in with Google for your private intake records.';

  @override
  String get setupNotAvailable => 'Setup not available yet';

  @override
  String get setupNotAvailableHint =>
      'Areas, goals, environments, experience, routine and review are not saved in this version. None of these choices was inferred from the Google account. There is no simulated mandatory setup to unlock navigation.';

  @override
  String get scopeCaregivers =>
      'Home, parks and gyms remain in scope, as do older adults and caregivers. The focus is caregivers exercising for themselves during work breaks. The library does not determine clinical suitability or eligibility.';

  @override
  String get noActivityRecording => 'Activity recording not available yet';

  @override
  String get noActivityRecordingHint =>
      'Starting, pausing, ending and viewing an activity require the recording service. This version does not create sets, doses, sessions, routes, energy expenditure or workout completion.';

  @override
  String get permissionsDevices => 'Permissions and devices';

  @override
  String get permissionsDevicesHint =>
      'GPS, sensors, Health Connect and camera are not integrated. This screen does not request permissions or collect location, images or device data. Image and OCR entries are not available either.';

  @override
  String get historyProgress => 'History and progress';

  @override
  String get historyProgressHint =>
      'Charts, activity periods, measurements and goals require their own records and calculations. Missing implementation does not mean zero activity. Confirmed intake history remains available through the Diary.';

  @override
  String get googleIdentity => 'Identity from Google';

  @override
  String get googleIdentityHint =>
      'Name and email are confirmed at sign-in. Editing them in TrainForge is not available yet. Connection confirmation, sign-out, export and deletion have their own actions in the profile.';

  @override
  String get devicePreferences => 'Device preferences';

  @override
  String get devicePreferencesHint =>
      'Light, dark, follow device and language are available in preferences. These choices stay on this device and are separate from the account. Units, measurements and goals do not have saved editing yet. Foods preserve source names, bases and units until reviewed translations are available.';

  @override
  String get whatToTest => 'What you can test now';

  @override
  String get whatToTestHint =>
      'Sign in with Google, browse movements and foods, create private foods and record what you consumed. The Diary lets you check sources, correct and delete intake; Privacy lets you view and copy pages of your data.';

  @override
  String get faq => 'Frequently asked questions';

  @override
  String get whyOriginalNames => 'Why are there French and English names?';

  @override
  String get whyOriginalNamesHint =>
      'They are original names from Ciqual and CoFID. We do not create translations that could change the food’s identity.';

  @override
  String get unknownMeansZero => 'Does a trace or unknown value mean zero?';

  @override
  String get unknownMeansZeroHint =>
      'No. Missing bases, unknown values, limits and different methods stay explicit. Estimated quantities are also marked.';

  @override
  String get libraryGuidesTraining => 'Does the library guide my training yet?';

  @override
  String get libraryGuidesTrainingHint =>
      'Not yet. Metadata is read only; no program, dose, instruction or media has been approved for practice.';

  @override
  String get reportProblem => 'How can I report a problem?';

  @override
  String get reportProblemHint =>
      'Note the screen, action and expected result for evaluation. Hide email, personal data and records before sharing screenshots. In-app feedback submission is not implemented yet.';

  @override
  String get evaluationConditions => 'Evaluation conditions';

  @override
  String get evaluationConditionsHint =>
      'The effective data policy comes from the API under Privacy and data. Production terms and a support channel still need to be defined; this text does not replace those documents. There is no prescription, food recognition by photo or automatic target.';

  @override
  String get browseLibrary => 'Browse library';

  @override
  String get browseFoods => 'Browse foods';

  @override
  String get searchFoodNames => 'Search by name';

  @override
  String get reviewedNamesHint =>
      'Search the original name or a reviewed name/alias in the selected language. Without review, the original name stays.';

  @override
  String get reviewedFoodName => 'Reviewed name in this language';

  @override
  String get originalFoodName => 'Original name';

  @override
  String get nameReviewSource => 'Name review and rights';

  @override
  String get nameCatalogChanged =>
      'The reviewed names changed. The previous page was discarded; check the refreshed query.';

  @override
  String get foodNameFallback =>
      'No reviewed name in this language. The original source name is shown.';

  @override
  String get retryReadPreference => 'Try loading the preference again';

  @override
  String get readingPreferences => 'Loading preference';

  @override
  String get trainingConfiguration => 'Training setup';

  @override
  String get trainingConfigIntro =>
      'Tell us where and when you can train. Review everything before confirming.';

  @override
  String get trainingConfigNotice =>
      'This setup describes your routine. It does not confirm fitness or create a workout. Programs and rules need human review.';

  @override
  String get configPlaces => 'Places and context';

  @override
  String get configResources => 'Available equipment';

  @override
  String get configAvailability => 'Availability';

  @override
  String get configReview => 'Final review';

  @override
  String configStep(int step) {
    return 'Step $step of 4';
  }

  @override
  String get configWhere => 'Where can you train?';

  @override
  String get configHome => 'Home';

  @override
  String get configPark => 'Square or park';

  @override
  String get configGym => 'Gym';

  @override
  String get configContext => 'In what context?';

  @override
  String get configPersonal => 'In my personal routine';

  @override
  String get configCaregiver => 'During my work breaks as a caregiver';

  @override
  String get configCaregiverHint =>
      'The workout is for you, not the person you care for.';

  @override
  String get configDeclared => 'I will select the equipment I have';

  @override
  String get configNone => 'I have no equipment';

  @override
  String get configUnknown => 'I do not know what I have yet';

  @override
  String get configEquipmentHint =>
      'Not knowing is different from having none. Select up to 32 items using the original source names.';

  @override
  String get configSelected => 'Selected equipment';

  @override
  String get configResourceWithdrawn =>
      'Reference unavailable. Remove it or select another before confirming.';

  @override
  String get configNoResources => 'No equipment found for this search.';

  @override
  String get configTimezone => 'Time zone for your routine';

  @override
  String get configTimezoneHint =>
      'Starts with the offset observed on this device. You can use UTC, an offset such as -03:00 or a zone such as America/Sao_Paulo. A fixed offset does not follow daylight saving changes.';

  @override
  String get configAvailabilityHint =>
      'Enter the time you have, not a prescribed workout duration. You can add several breaks per day. The day refers to the start of the break.';

  @override
  String get configDay => 'Day of the week';

  @override
  String get configMinutes => 'Available minutes';

  @override
  String get configStart => 'Start time (optional)';

  @override
  String get configUnfixed => 'No fixed time';

  @override
  String get configAddSlot => 'Add availability';

  @override
  String get configRemoveSlot => 'Remove availability';

  @override
  String get configMonday => 'Monday';

  @override
  String get configTuesday => 'Tuesday';

  @override
  String get configWednesday => 'Wednesday';

  @override
  String get configThursday => 'Thursday';

  @override
  String get configFriday => 'Friday';

  @override
  String get configSaturday => 'Saturday';

  @override
  String get configSunday => 'Sunday';

  @override
  String get configNext => 'Continue';

  @override
  String get configEdit => 'Edit answers';

  @override
  String get configConfirm => 'Confirm setup';

  @override
  String get configSaved => 'Setup confirmed';

  @override
  String get configSavedHint =>
      'Your answers are saved to your account. There is no approved program to show yet.';

  @override
  String get configUnavailable =>
      'The setup could not be confirmed. Check the connection and try again. Your form answers remain here.';

  @override
  String get configConflict =>
      'The account setup changed in another confirmation. Your answers were preserved. Reload the saved version before editing again.';

  @override
  String get configReload => 'Reload saved setup';

  @override
  String get configReloadNotice =>
      'Reloading replaces only the unsaved answers in this form. Continue?';

  @override
  String get configUncertain =>
      'The confirmation may have reached the server. Retry the same confirmation to check the result without creating another version. If you leave, check the saved setup when you return.';

  @override
  String get configLeaveCheck => 'Leave and check setup later';

  @override
  String get configChoosePlace => 'Select at least one place.';

  @override
  String get configChooseContext => 'Choose your context.';

  @override
  String get configChooseStatus =>
      'Choose whether you have equipment, have none or do not know yet.';

  @override
  String get configChooseResource => 'Select between 1 and 32 available items.';

  @override
  String get configInvalidTimezone =>
      'Check the time zone: UTC, an offset up to 14:00 or a recognized zone.';

  @override
  String get configChooseDay => 'Choose a day of the week.';

  @override
  String get configInvalidMinutes =>
      'Enter a whole number from 1 to 1440 minutes.';

  @override
  String get configInvalidSlot =>
      'Check the time and avoid repeating the same day and time. Keep between 1 and 28 availability slots.';

  @override
  String get privacySectionTrainingConfigurations => 'Training setup versions';

  @override
  String get configEntryHint =>
      'In your account, open Training setup. It is also under Plans, in Create my plan. Review places, context, equipment and availability before confirming.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get language => 'Idioma';

  @override
  String get languageIntro =>
      'Elige el idioma de la interfaz en este dispositivo.';

  @override
  String get languageScope =>
      'La elección no cambia tu cuenta, los alimentos originales ni los registros.';

  @override
  String get contentOriginal =>
      'Los nombres y textos de las fuentes conservan su idioma original si no hay traducción revisada.';

  @override
  String get languageProgress =>
      'Los flujos disponibles usan el idioma elegido. Las nuevas funciones se localizarán a medida que se implementen.';

  @override
  String get followDevice => 'Usar idioma del dispositivo';

  @override
  String get languageUnavailable =>
      'La configuración de idioma no está disponible aquí.';

  @override
  String get languageFallback =>
      'No se pudo leer la preferencia. Se usa el idioma del dispositivo.';

  @override
  String get languageSaveFailed =>
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get languageSaveUncertain =>
      'Se aplicó el idioma, pero no se confirmó el guardado. Intenta guardarlo de nuevo.';

  @override
  String get savingLanguage => 'Guardando idioma';

  @override
  String get retrySave => 'Volver a guardar';

  @override
  String get retry => 'Reintentar';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceTitle => 'Tu ritmo, tu tema.';

  @override
  String get appearanceIntro =>
      'La elección se mantiene en este dispositivo al cerrar la aplicación. No cambia los datos de tu cuenta.';

  @override
  String get appearanceUnavailable =>
      'La configuración de apariencia no está disponible aquí.';

  @override
  String get themeSystem => 'Usar tema del dispositivo';

  @override
  String get themeSystemHint => 'Sigue el tema claro u oscuro del sistema.';

  @override
  String get light => 'Claro';

  @override
  String get lightHint => 'La identidad original en superficies claras.';

  @override
  String get dark => 'Oscuro';

  @override
  String get darkHint => 'Superficies oscuras con contraste adaptado.';

  @override
  String get savingAppearance => 'Guardando apariencia';

  @override
  String get accessibilityDevice =>
      'El tamaño del texto y la reducción de movimiento siguen la configuración de accesibilidad del dispositivo.';

  @override
  String get welcome => 'Qué bueno verte por aquí.';

  @override
  String get welcomeHint => 'Inicia sesión para continuar tu rutina.';

  @override
  String get waitingGoogle => 'Esperando confirmación de Google';

  @override
  String get connecting => 'Conectando…';

  @override
  String get signInGoogle => 'Entrar con Google';

  @override
  String get noAccount => '¿Aún no tienes cuenta?';

  @override
  String get createGoogle => 'Crear una cuenta con Google';

  @override
  String get googleOnly =>
      'Esta versión usa el acceso con Google. El correo y Apple aún no están disponibles.';

  @override
  String get firstAccess => 'Primer acceso y configuración';

  @override
  String get exploreFirst => 'Explorar antes de entrar';

  @override
  String get publicCatalog => 'Consultar la biblioteca sin entrar';

  @override
  String get publicFood => 'Consultar alimentos sin registrar consumo';

  @override
  String get privacy => 'Privacidad y datos';

  @override
  String get preparing => 'Preparando TrainForge';

  @override
  String get restoringSession => 'Confirmando tu sesión';

  @override
  String get confirmingSession => 'Confirmando sesión';

  @override
  String get today => 'Hoy';

  @override
  String get plans => 'Planes';

  @override
  String get activity => 'Actividad';

  @override
  String get diary => 'Diario';

  @override
  String get evolution => 'Evolución';

  @override
  String get openProfile => 'Abrir perfil';

  @override
  String get back => 'Volver';

  @override
  String get close => 'Cerrar';

  @override
  String get yourSpace => 'Tu espacio.';

  @override
  String get connected => 'Cuenta conectada';

  @override
  String get accountData => 'Cuenta y datos personales';

  @override
  String get identityHint => 'Identidad de Google, exportación y eliminación';

  @override
  String get goalsRoutine => 'Objetivos y rutina';

  @override
  String get equipmentDays => 'Equipo, días y actividades';

  @override
  String get preferences => 'Preferencias';

  @override
  String get preferenceHint => 'Apariencia y accesibilidad del dispositivo';

  @override
  String get devicesPermissions => 'Dispositivos y permisos';

  @override
  String get devicesHint => 'Health Connect, ubicación y cámara';

  @override
  String get privacyHint => 'Exportación, eliminación y política vigente';

  @override
  String get helpEvaluation => 'Ayuda y condiciones de evaluación';

  @override
  String get helpHint => 'Dudas, fuentes y funciones disponibles';

  @override
  String get confirmConnection => 'Confirmar conexión';

  @override
  String get signOut => 'Cerrar esta sesión';

  @override
  String get languageNames =>
      'Portugués de Brasil, portugués de Portugal, inglés y español';

  @override
  String get sessionTimeout =>
      'La confirmación de la sesión tardó más de lo esperado. Tu sesión se conservó; reintenta o consulta la biblioteca sin entrar.';

  @override
  String get googleConfiguration =>
      'El acceso con Google no está configurado en este entorno. Consulta la guía de evaluación.';

  @override
  String get authConfiguration =>
      'El entorno de autenticación necesita configuración. Consulta la guía de evaluación.';

  @override
  String get sessionExpired =>
      'La sesión caducó o fue revocada. Vuelve a entrar con Google.';

  @override
  String get rateLimited =>
      'Demasiados intentos. Espera un minuto e inténtalo de nuevo.';

  @override
  String get authUnavailable =>
      'El servicio de autenticación no está disponible. Inténtalo más tarde.';

  @override
  String get signOutUnconfirmed =>
      'No se confirmó la salida. Conéctate a internet e intenta salir de nuevo.';

  @override
  String get signInFailed =>
      'No se pudo iniciar sesión. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get sessionOffline =>
      'No se pudo confirmar la conexión. Tu sesión se conservó; inténtalo de nuevo.';

  @override
  String get actionFailed =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get appearanceInvalid =>
      'No se pudo usar la preferencia anterior. Se usa el tema del dispositivo.';

  @override
  String get appearanceReadFailed =>
      'No se pudo leer la apariencia guardada. Se usa el tema del dispositivo.';

  @override
  String get appearanceSaveUncertain =>
      'Se aplicó la apariencia, pero no se confirmó el guardado. Inténtalo de nuevo.';

  @override
  String get appearanceSaveFailed =>
      'No se pudo guardar la apariencia. Inténtalo de nuevo.';

  @override
  String get moveNow => '¡Vamos a movernos!';

  @override
  String moveWithName(String name) {
    return '¡Vamos a movernos, $name!';
  }

  @override
  String get dailyRhythm => 'Tu ritmo, cada día';

  @override
  String get strongerDaily => 'UN POCO MÁS FUERTE, CADA DÍA';

  @override
  String get nextMovement => 'Tu próximo movimiento';

  @override
  String get libraryReadOnly =>
      'Biblioteca de consulta. La práctica guiada aún no está disponible.';

  @override
  String get yourWeek => 'Tu semana';

  @override
  String get diaryByDate => 'Consultar el diario alimentario por fecha.';

  @override
  String get yourDay => 'Tu día';

  @override
  String get loadingDayData => 'Consultando los datos reales del día';

  @override
  String get loadingDayRecords => 'Consultando registros del día';

  @override
  String get dayUpdateFailed => 'No se pudo actualizar el día.';

  @override
  String get dayUnconfirmed =>
      'Los datos no se confirmaron. Esta consulta no crea ni elimina consumos.';

  @override
  String get retryUpdate => 'Volver a actualizar';

  @override
  String get energyNoSubtotal => 'energía sin un subtotal único confirmado';

  @override
  String get energySourceMethod => 'kcal · un método de la fuente';

  @override
  String get activityUnavailable => 'actividad aún no disponible';

  @override
  String get summaryLimit =>
      'Se superó el límite del resumen. Consulta el historial; ningún total parcial se presenta como completo.';

  @override
  String quantityEvidenceCounts(int measured, int estimated) {
    String _temp0 = intl.Intl.pluralLogic(
      measured,
      locale: localeName,
      other: '$measured medidas',
      one: '1 medida',
    );
    String _temp1 = intl.Intl.pluralLogic(
      estimated,
      locale: localeName,
      other: '$estimated estimadas',
      one: '1 estimada',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get originMethodDiary => 'Origen y método en el diario.';

  @override
  String get myNutrition => 'Mi alimentación';

  @override
  String get loadingRecords => 'Consultando registros…';

  @override
  String get openHistoryRetry => 'Abrir historial e intentar actualizar';

  @override
  String get noConfirmedToday => 'Ningún consumo confirmado este día';

  @override
  String get viewRecordsOrigin => 'Consultar registros y origen';

  @override
  String confirmedDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consumos confirmados este día · ver origen',
      one: '1 consumo confirmado este día · ver origen',
      zero: 'Ningún consumo confirmado este día',
    );
    return '$_temp0';
  }

  @override
  String get whatToday => '¿Qué te apetece hoy?';

  @override
  String get exploreActivities => 'Caminar, correr, explorar otra actividad';

  @override
  String get updateDay => 'Actualizar el día';

  @override
  String viewFoodDay(String date) {
    return 'Consultar alimentación del $date';
  }

  @override
  String get findMovement => 'Encuentra tu movimiento.';

  @override
  String get atYourPace => 'Con orientación, a tu ritmo.';

  @override
  String get searchUpper => 'BUSCAR';

  @override
  String get movementSearchHint => 'Movimiento, actividad o fuente';

  @override
  String get loadingPrograms => 'Consultando programas disponibles';

  @override
  String get programsUnconfirmed =>
      'No se pudieron consultar los programas. No se confirmó la disponibilidad.';

  @override
  String get programsUnavailable => 'Programas aún no disponibles';

  @override
  String get browsePrograms => 'Consultar programas';

  @override
  String get noPracticeProgram =>
      'No hay programas autorizados para practicar. Consulta las referencias disponibles.';

  @override
  String get viewRequirements => 'Ver origen, requisitos y disponibilidad';

  @override
  String get exploreModalities => 'Explorar actividades';

  @override
  String get referenceLibrary => 'Biblioteca de referencia · solo consulta';

  @override
  String get createMyPlan => 'Crear mi plan';

  @override
  String get organizeWeek => 'Elegir ejercicios y organizar la semana';

  @override
  String get compositionUnavailable => 'Composición no disponible';

  @override
  String get helpStart => 'Ayúdame a empezar';

  @override
  String get audiencesEnvironments =>
      'Casa, parque, gimnasio, personas mayores y cuidadores';

  @override
  String get eatSimply => 'Comer bien, sin complicaciones.';

  @override
  String get foodDiaryUpper => 'DIARIO ALIMENTARIO';

  @override
  String get loadingQuery => 'Consultando…';

  @override
  String get queryUnavailable => 'Consulta no disponible';

  @override
  String get sourceSubtotals =>
      'Consulta los subtotales por método de la fuente.';

  @override
  String get recordedEnergy => 'ENERGÍA REGISTRADA';

  @override
  String get energyMethodSubtotal =>
      'kcal · subtotal de un método de la fuente';

  @override
  String get updateDayRecords => 'Actualizar registros del día';

  @override
  String get myRecords => 'Mis registros';

  @override
  String get addFood => 'Añadir alimento';

  @override
  String get hydration => 'Hidratación';

  @override
  String get waterUnavailable => 'Registro de agua aún no disponible';

  @override
  String get waterNotImplemented =>
      'El registro de agua aún no está implementado. No se ha rellenado ninguna cantidad automáticamente.';

  @override
  String get planLearn => 'Planificar y aprender';

  @override
  String get foodGuidanceUnavailable =>
      'Contenido alimentario aún no autorizado';

  @override
  String get planningLearning => 'Planificación y aprendizaje';

  @override
  String get foodPlansUnavailable =>
      'Los planes alimentarios y las orientaciones aún no están disponibles. Las fuentes y sus nutrientes se pueden consultar desde el diario.';

  @override
  String get outdoorsCounts => 'Salir también cuenta.';

  @override
  String get activityIntro => 'Camina, corre o registra tu actividad.';

  @override
  String get routeUnavailable =>
      'La ruta aún no está disponible. No se está recopilando tu ubicación.';

  @override
  String get noWalkKm => 'km · sin registro de caminata';

  @override
  String get noActivityMinutes => 'minutos de actividad no disponibles';

  @override
  String get startActivity => 'Comenzar actividad';

  @override
  String get quickRecord => 'Registro rápido';

  @override
  String get quickUnavailable =>
      'Registros manuales y por imagen aún no disponibles';

  @override
  String get myDevices => 'Mis dispositivos';

  @override
  String get permissionsSync => 'Permisos, origen y sincronización';

  @override
  String get yourProgress => 'Mira lo que has construido.';

  @override
  String get historyWithSource => 'TU HISTORIAL, CON ORIGEN';

  @override
  String get chartUnavailable =>
      'La evolución de actividad aún no está disponible. El gráfico aparecerá cuando haya registros y cálculos implementados.';

  @override
  String get workoutsUnavailable => 'entrenamientos aún no disponibles';

  @override
  String get walkingKmUnavailable => 'km de caminata no disponibles';

  @override
  String get eachRecordCounts => 'Cada registro cuenta';

  @override
  String get historyCorrect => 'Ver historial y corregir un consumo';

  @override
  String get measurementsGoals => 'Medidas y objetivos';

  @override
  String get configurationUnavailable => 'Configuración aún no disponible';

  @override
  String get searchResults => 'Resultados de búsqueda';

  @override
  String get foodReferences => 'ALIMENTOS DE REFERENCIA';

  @override
  String searchFor(String query) {
    return 'BÚSQUEDA · $query';
  }

  @override
  String get searchOriginal => 'Buscar por nombre original';

  @override
  String get foodPreparation => 'Alimento o preparación';

  @override
  String get originalNamesHint =>
      'Nombres en francés o inglés, según la fuente.';

  @override
  String get search => 'Buscar';

  @override
  String foodCoverage(int total, int unknown) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total referencias',
      one: '1 referencia',
    );
    return '$_temp0 · $unknown sin base confirmada.';
  }

  @override
  String get allSources => 'Todas las fuentes';

  @override
  String get originalFoodNotice =>
      'La preparación y el idioma permanecen en el nombre original. Los valores ausentes, las trazas y los límites no son cero. Cada detalle incluye fuente y licencia.';

  @override
  String get readOnlyFood =>
      'Consulta sin prescripción de dieta ni registro de consumo.';

  @override
  String get loadingFood => 'Consultando alimentos';

  @override
  String get noFoodResults =>
      'Ningún alimento coincide con la búsqueda. Prueba un término en el idioma original u otra fuente.';

  @override
  String get loading => 'Cargando…';

  @override
  String get moreFood => 'Cargar más alimentos';

  @override
  String get clearSearch => 'Borrar búsqueda y fuente';

  @override
  String get loadingComposition => 'Consultando composición';

  @override
  String get sourceComposition => 'Composición de la fuente';

  @override
  String get referenceFood => 'ALIMENTO DE REFERENCIA';

  @override
  String get foodVersionUnavailable =>
      'Este alimento no está disponible. Puede haber un fallo de conexión o una retirada de la versión.';

  @override
  String get originalFoodVersion => 'ALIMENTO · VERSIÓN ORIGINAL';

  @override
  String get foodQueryNotice =>
      'Referencia de composición de la fuente, sin prescripción de dieta. Se conservan nombres y métodos originales; la ausencia no significa cero. Esta consulta no calcula porciones ni registra consumo.';

  @override
  String get refreshComposition => 'Actualizar composición';

  @override
  String get useFoodVersion => 'Usar esta versión para registrar consumo';

  @override
  String get sourceLicense => 'Fuente y licencia';

  @override
  String get publication => 'Publicación';

  @override
  String get provenanceConditions => 'Procedencia y condiciones';

  @override
  String get code => 'Código';

  @override
  String get version => 'Versión';

  @override
  String get originalNutrients => 'Nutrientes y valores originales';

  @override
  String get nutrientMethodsNotice =>
      'Los métodos y columnas diferentes permanecen separados. Cada valor muestra su propia base; no se calcula ninguna porción.';

  @override
  String get originalCell => 'Celda original';

  @override
  String get basisUnknown => 'Base de composición desconocida';

  @override
  String sourceBasis(String quantity, String unit) {
    return 'Base de la fuente: $quantity $unit';
  }

  @override
  String perQuantity(String quantity, String unit) {
    return 'Por $quantity $unit';
  }

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get valueUnavailable => 'Valor no disponible';

  @override
  String get limitUnavailable => 'Límite no disponible';

  @override
  String lessThanValue(String value, String unit) {
    return '< $value$unit (límite; sin valor exacto)';
  }

  @override
  String get traceValue => 'Traza (sin cantidad exacta)';

  @override
  String get notInformed => 'No informado';

  @override
  String get presentUnknown => 'Presente; cantidad desconocida';

  @override
  String unparsedValue(String value) {
    return 'Valor original no interpretado: $value';
  }

  @override
  String get basisUnconfirmed => 'Base no confirmada para este valor';

  @override
  String get columnDeclares => 'La columna declara';

  @override
  String get foodSearchTooLong =>
      'La búsqueda es demasiado larga. Usa parte del nombre original.';

  @override
  String get foodQueryFailed =>
      'No se pudieron consultar los alimentos. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get foodMoreFailed =>
      'No se pudieron cargar más alimentos. Inténtalo de nuevo.';

  @override
  String get catalogQueryFailed =>
      'No se pudo consultar la biblioteca. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get catalogMoreFailed =>
      'No se pudo cargar la siguiente página. Inténtalo de nuevo.';

  @override
  String get allKnownValues => 'Todos los valores informados';

  @override
  String get sourceFilters => 'Filtros de la fuente';

  @override
  String get unknownNotAssumed =>
      'Los valores no informados no se adaptan ni clasifican por suposición.';

  @override
  String get category => 'Categoría';

  @override
  String get equipment => 'Equipo';

  @override
  String get environment => 'Entorno';

  @override
  String get audience => 'Público';

  @override
  String get modality => 'Modalidad';

  @override
  String unknownEnvironment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros sin entorno informado.',
      one: '1 registro sin entorno informado.',
    );
    return '$_temp0';
  }

  @override
  String unknownAudience(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros sin público informado.',
      one: '1 registro sin público informado.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get applyFilters => 'Aplicar filtros';

  @override
  String get libraryTitle => 'Biblioteca de referencia';

  @override
  String get librarySubtitle => 'MOVIMIENTO · ORIGEN · DISPONIBILIDAD';

  @override
  String get metadataOnly =>
      'Solo consulta. Estos registros no son instrucciones ni programas autorizados para practicar.';

  @override
  String get movements => 'Movimientos';

  @override
  String get programs => 'Programas';

  @override
  String get filters => 'Filtros';

  @override
  String get clear => 'Borrar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String get loadingLibrary => 'Consultando biblioteca';

  @override
  String get noProgramsBatch => 'Ningún programa autorizado en este lote.';

  @override
  String get noMetadataFilters => 'Ningún metadato coincide con los filtros.';

  @override
  String get audienceScope =>
      'Las personas mayores, cuidadores, casa, parques y gimnasios siguen incluidos. La fuente debe indicar requisitos y permisos para cada uso.';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get titleNotProvided => 'Título no informado por la fuente';

  @override
  String get movement => 'Movimiento';

  @override
  String get collection => 'Colección modular';

  @override
  String get program => 'Programa';

  @override
  String get languageNotProvided => 'Idioma no informado';

  @override
  String get credits => 'Créditos';

  @override
  String get licenseNotProvided => 'Licencia no informada';

  @override
  String get sourceInDetail => 'Fuente y licencia en detalles · Solo consulta';

  @override
  String get linkFailed =>
      'No se pudo abrir el enlace. Puedes copiar la URL de abajo.';

  @override
  String get loadingDetail => 'Consultando detalle';

  @override
  String get originAvailability => 'Origen y disponibilidad';

  @override
  String get libraryUpper => 'BIBLIOTECA';

  @override
  String get referenceUnavailable => 'Referencia no disponible';

  @override
  String get recordWithdrawn =>
      'Este registro no está disponible o fue retirado. Vuelve a la biblioteca.';

  @override
  String get recordUnconfirmed =>
      'No se pudo confirmar este registro. Conéctate e inténtalo de nuevo.';

  @override
  String get backLibrary => 'Volver a la biblioteca';

  @override
  String get notProvidedSource => 'No informado por la fuente';

  @override
  String get libraryReadOnlyUpper => 'BIBLIOTECA · SOLO CONSULTA';

  @override
  String get referenceMovement => 'Movimiento de referencia';

  @override
  String get sourceProgram => 'Programa de la fuente';

  @override
  String get noPracticeContent =>
      'Solo consulta. Las instrucciones, dosis y medios no están autorizados para usar en la aplicación.';

  @override
  String get authorship => 'Autoría y contribución';

  @override
  String get authorsProvided => 'Autores informados';

  @override
  String get sourceCredits => 'Créditos de la fuente';

  @override
  String get attribution => 'Atribución';

  @override
  String get openOriginalSource => 'Abrir fuente original';

  @override
  String get openLicense => 'Abrir licencia';

  @override
  String get noticeNotProvided => 'Aviso no informado';

  @override
  String get availability => 'Disponibilidad';

  @override
  String get audienceSupport => 'Público, entorno y apoyo';

  @override
  String get support => 'Apoyo';

  @override
  String get supportRequired => 'Exigido por la fuente';

  @override
  String get supportNotRequired => 'No exigido según la fuente';

  @override
  String get supportReference => 'Referencia de apoyo';

  @override
  String get providedRequirements => 'Requisitos informados';

  @override
  String get titleCredits => 'Créditos del título original';

  @override
  String get titleLicense => 'Licencia del título';

  @override
  String get declaredChanges => 'Cambios declarados';

  @override
  String get deliveryConditions => 'Condiciones de entrega';

  @override
  String get queriedVersion => 'Versión consultada';

  @override
  String get versionHash => 'Hash de la versión importada:';

  @override
  String get publishedVersion => 'Versión publicada por la fuente';

  @override
  String get originalLanguage => 'Idioma original';

  @override
  String get portionYours => 'Tu porción.';

  @override
  String get correctIntake => 'Corregir consumo';

  @override
  String get quantity => 'Cantidad';

  @override
  String get consumedQuantity => 'Cantidad consumida';

  @override
  String get enterQuantity => 'Introduce la cantidad';

  @override
  String get positiveQuantity =>
      'Introduce una cantidad mayor que cero, con hasta 6 decimales.';

  @override
  String get quantityUnit => 'Unidad de la cantidad';

  @override
  String get grams => 'Gramos (g)';

  @override
  String get milliliters => 'Mililitros (ml)';

  @override
  String get quantityHow => '¿Cómo obtuviste la cantidad?';

  @override
  String get measuredChoice => 'La medí con una báscula o recipiente';

  @override
  String get estimatedChoice => 'Hice una estimación';

  @override
  String get chooseEvidence => 'Elige medida o estimada.';

  @override
  String get portionComposition => 'Composición de la porción';

  @override
  String get calculationOnSave =>
      'La API confirma el cálculo al guardar. Los valores desconocidos no se convierten en cero; no se suman métodos ni unidades diferentes.';

  @override
  String get originPreparation => 'Origen y preparación';

  @override
  String get sourceVersion => 'Fuente y versión';

  @override
  String get origin => 'Origen';

  @override
  String get observedPreparation => 'Preparación observada (opcional)';

  @override
  String get preparationNote =>
      'La preparación es una anotación tuya y no cambia la composición de la fuente. No se convierten gramos en mililitros sin una densidad comprobada.';

  @override
  String get deviceDateConfirmed =>
      'Fecha y hora del dispositivo, confirmadas por ti.';

  @override
  String get intakeConfirmationNotice =>
      'Confirma solo lo que consumiste. No se prescribe una dieta ni se compensa el ejercicio. Las cantidades estimadas se identificarán como estimadas.';

  @override
  String get intakeUncertain =>
      'La respuesta aún no se ha confirmado. Reintenta con los mismos datos o vuelve para revisar el historial.';

  @override
  String get confirming => 'Confirmando…';

  @override
  String get retryConfirmation => 'Reintentar confirmación';

  @override
  String get confirmIntake => 'Confirmar consumo';

  @override
  String get confirmCorrection => 'Confirmar corrección';

  @override
  String get createOwnFood => 'Crear alimento propio';

  @override
  String get ownDataUpper => 'PRIVADO · DATOS INDICADOS POR TI';

  @override
  String get foodIdentity => 'Identidad del alimento';

  @override
  String get ownFoodNotice =>
      'Registro privado, separado del catálogo público. Crear este alimento no registra consumo ni implica revisión editorial o clínica.';

  @override
  String get foodName => 'Nombre del alimento';

  @override
  String get enterName => 'Introduce el nombre.';

  @override
  String get declaredPreparation => 'Preparación declarada (opcional)';

  @override
  String get compositionBasis => 'Base de la composición';

  @override
  String get basisNotice =>
      'Si la conoces, indica la base a la que se refieren los nutrientes. Deja en blanco lo que no sabes. La ausencia no significa cero.';

  @override
  String get optionalBasisQuantity => 'Cantidad de la base (opcional)';

  @override
  String get positiveBasis => 'La base debe ser mayor que cero.';

  @override
  String get basisUnit => 'Unidad de la base';

  @override
  String get declaredNutrients => 'Nutrientes declarados';

  @override
  String get noAssumedNutrients =>
      'No supongas valores. Un campo vacío conserva el valor desconocido; introducir 0 declara cero.';

  @override
  String get nutrientName => 'Nombre del nutriente';

  @override
  String get enterNutrientName => 'Introduce el nombre del nutriente.';

  @override
  String get optionalBasisValue => 'Valor en la base (opcional)';

  @override
  String get decimalOrUnknown => 'Introduce un decimal o déjalo desconocido.';

  @override
  String get nutrientUnit => 'Unidad del nutriente';

  @override
  String get removeField => 'Eliminar este campo';

  @override
  String get addNutrient => 'Añadir un nutriente conocido o desconocido';

  @override
  String get ownFoodUncertain =>
      'Respuesta no confirmada. Reintenta con los mismos datos para evitar duplicados.';

  @override
  String get saveFoodOnly => 'Guardar solo el alimento';

  @override
  String get ownFoodSaved =>
      'Alimento privado guardado. No se ha registrado consumo.';

  @override
  String get intake => 'Consumo';

  @override
  String get myFoods => 'Mis alimentos';

  @override
  String get confirmedDiaryUpper => 'DIARIO · REGISTROS CONFIRMADOS POR TI';

  @override
  String get searchRecordFood => 'Buscar alimento y registrar consumo';

  @override
  String get diaryNoPrescription =>
      'Registros confirmados por ti. No se crea una dieta, objetivo ni compensación por ejercicio.';

  @override
  String get loadingNutrition => 'Consultando alimentación';

  @override
  String get noIntakeDay => 'No hay consumo registrado en este día.';

  @override
  String get noIntakeHint =>
      'Elige otra fecha o busca un alimento para registrar lo que consumiste. La ausencia de registros no significa consumo cero.';

  @override
  String get measuredShort => 'medida';

  @override
  String get estimatedShort => 'estimada';

  @override
  String get moreRecords => 'Cargar más registros';

  @override
  String get subtotalLimit => 'Límite de subtotal superado';

  @override
  String get unknownValue => 'Desconocido';

  @override
  String get column => 'Columna';

  @override
  String get privateFoodsUpper => 'ALIMENTOS PRIVADOS · NO PUBLICADOS';

  @override
  String get privateFoodsHint =>
      'Solo tus alimentos privados. Crear un alimento no registra consumo ni lo publica en el catálogo.';

  @override
  String get searchMyFoods => 'Buscar en mis alimentos';

  @override
  String get loadingPrivateFoods => 'Consultando alimentos privados';

  @override
  String get noPrivateResults =>
      'Ningún alimento propio coincide con la búsqueda.';

  @override
  String get noPrivateHint =>
      'Busca otro nombre o crea un alimento privado. Introduce solo los datos conocidos; no supongas nutrientes.';

  @override
  String get privatePortionHint => 'Privado · toca para indicar una porción';

  @override
  String get morePrivateFoods => 'Cargar más alimentos propios';

  @override
  String get deleteIntakeQuestion => '¿Eliminar este consumo?';

  @override
  String get deleteIntakeNotice =>
      'Se eliminará de los subtotales y del historial activo. El registro y sus correcciones seguirán siendo privados en la exportación hasta eliminar la cuenta. El alimento guardado permanece.';

  @override
  String get deleteIntake => 'Eliminar consumo';

  @override
  String get intakeConfirmed => 'Consumo confirmado';

  @override
  String get privateDiaryUpper => 'DIARIO · REGISTRO PRIVADO';

  @override
  String get quantityMeasured => 'Cantidad medida';

  @override
  String get quantityEstimated => 'Cantidad estimada';

  @override
  String get deviceTime => 'Hora en este dispositivo';

  @override
  String get recordedZone => 'Zona horaria indicada en el registro';

  @override
  String get notedPreparation => 'Preparación anotada';

  @override
  String get compositionOrigin => 'Origen de la composición';

  @override
  String get preservedCalculation => 'Origen y cálculo conservados';

  @override
  String get method => 'Método';

  @override
  String get fractionNotice =>
      'Se conserva la fracción exacta. Se muestran valores redondeados a 6 decimales. Trazas, límites, unidades incompatibles y bases ausentes no se convierten en cero. La preparación no cambia la composición.';

  @override
  String get requestUnconfirmed => 'Solicitud no confirmada';

  @override
  String get correctIntakeAction => 'Corregir cantidad, preparación u hora';

  @override
  String get deleteThisIntake => 'Eliminar este consumo';

  @override
  String get thisPortionComposition => 'Composición de esta porción';

  @override
  String get portionSourceNotice =>
      'Estos valores pertenecen a la versión y al método de la fuente. Desconocido no significa cero.';

  @override
  String get reason => 'Motivo';

  @override
  String get basisOriginalCalculation => 'Base, valor original y cálculo';

  @override
  String get originalState => 'Estado original';

  @override
  String get cell => 'celda';

  @override
  String get limit => 'límite';

  @override
  String get basis => 'Base';

  @override
  String get factor => 'Factor';

  @override
  String get notCalculable => 'no calculable';

  @override
  String get exactFraction => 'Fracción exacta';

  @override
  String get preparation => 'Preparación';

  @override
  String get checkBeforeLeaving => 'Revisar antes de salir';

  @override
  String get leaveUnsaved => '¿Salir sin guardar?';

  @override
  String get uncertainDraftNotice =>
      'La respuesta al envío aún no se ha confirmado. Salir no cancela la solicitud. Revisa el historial antes de crear otro registro; para reintentar con seguridad, permanece y usa la misma confirmación.';

  @override
  String get unsavedDraftNotice =>
      'Los cambios de este formulario aún no se han guardado. Puedes seguir rellenándolo o descartar solo este borrador.';

  @override
  String get continueEditing => 'Seguir editando';

  @override
  String get leaveCheckHistory => 'Salir y revisar historial';

  @override
  String get discardDraft => 'Descartar borrador';

  @override
  String get quantityEvidenceRequired =>
      'Introduce la cantidad e indica si fue medida o estimada.';

  @override
  String get nutritionAccountChanged =>
      'La cuenta ha cambiado. Vuelve a la entrada antes de continuar.';

  @override
  String get nutritionCheckFields =>
      'Revisa la cantidad, unidad, fecha, preparación y los campos introducidos.';

  @override
  String get nutritionUnavailable =>
      'El alimento o registro no está disponible. Actualiza la consulta.';

  @override
  String get nutritionConflict =>
      'El registro o la cuenta ha cambiado. Actualiza el historial antes de corregirlo.';

  @override
  String get nutritionRetrySafe =>
      'No se ha podido confirmar la acción. Revisa la conexión y reintenta. Repetir la misma acción no duplica el registro.';

  @override
  String get nutritionActionFailed =>
      'No se ha podido confirmar la acción. Inténtalo de nuevo.';

  @override
  String daySubtotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return 'Subtotales del día · $_temp0';
  }

  @override
  String nutrientCoverage(int included, int unknown) {
    return '$included incluidos · $unknown sin valor calculable';
  }

  @override
  String previousCorrections(int count) {
    return 'Correcciones anteriores ($count)';
  }

  @override
  String revision(int number) {
    return 'Revisión $number';
  }

  @override
  String get subtotalNotice =>
      'Subtotales por columna y método de la fuente; no sumes métodos ni unidades diferentes. Las cantidades estimadas siguen siendo estimadas; la ausencia no es cero. Se muestran valores redondeados a 6 decimales y se conservan las fracciones exactas. Sin objetivos ni compensación por ejercicio.';

  @override
  String get privacyUpper => 'POLÍTICA VIGENTE · CONTROLES DE TU CUENTA';

  @override
  String get processingData => 'Procesando solicitud de datos';

  @override
  String get accountDeleted => 'Cuenta TrainForge eliminada';

  @override
  String get googleAccountKept =>
      'La cuenta Google permanece activa. Los datos privados y las sesiones de esta cuenta se eliminaron de la base actual de TrainForge.';

  @override
  String get erasureLocalPending =>
      'El servidor confirmó la eliminación. Falta completar la limpieza o confirmación de sesión en este dispositivo.';

  @override
  String get finishLocalCleanup => 'Completar limpieza local';

  @override
  String get finish => 'Finalizar';

  @override
  String get dataControls => 'Tus datos y controles';

  @override
  String get retryPolicy => 'Reintentar cargar política';

  @override
  String get backupsRecovery => 'Copias de seguridad y recuperación';

  @override
  String get erasureMinimum => 'Registro mínimo tras la eliminación';

  @override
  String get externalCopiesNotice =>
      'Los datos que copies o exportes quedan bajo tu gestión; eliminar la cuenta no borra copias externas ni el portapapeles del dispositivo.';

  @override
  String get signInPrivacy =>
      'Entra con Google para consultar los datos de tu cuenta y solicitar su eliminación.';

  @override
  String get viewCopyData => 'Consultar y copiar mis datos';

  @override
  String get exportPageNotice =>
      'Consulta paginada por sección. Cada copia contiene solo la página visible, sin credenciales de acceso.';

  @override
  String get dataSection => 'Sección de datos';

  @override
  String get viewSection => 'Consultar sección';

  @override
  String get currentPageOnly =>
      'Esta es solo la página actual. La página siguiente sustituye a la anterior en pantalla.';

  @override
  String get noSectionRecords => 'No hay registros en esta sección.';

  @override
  String get pageCopied => 'Página copiada. Puede contener datos personales.';

  @override
  String get copyJsonPage => 'Copiar esta página JSON';

  @override
  String get nextPage => 'Página siguiente';

  @override
  String get deleteMyAccount => 'Eliminar mi cuenta TrainForge';

  @override
  String get deleteAccountNotice =>
      'Esta acción elimina tus datos actuales y revoca todas las sesiones. Lee los límites de las copias de seguridad. Requiere haber entrado con Google en los últimos 15 minutos.';

  @override
  String get confirmGoogleAgain => 'Confirmar cuenta de nuevo con Google';

  @override
  String get readDeletionLimits =>
      'He leído los límites de la eliminación, las copias históricas y la cuenta Google.';

  @override
  String get requestDeletionIntent => 'Solicitar confirmación de eliminación';

  @override
  String get temporaryDeletionNotice =>
      'Se ha creado una confirmación temporal para esta sesión. Escribe la frase exacta de abajo; caduca en un máximo de 5 minutos.';

  @override
  String get deleteAccountData => 'Eliminar mi cuenta y sus datos';

  @override
  String get cancelDeletion => 'Cancelar eliminación';

  @override
  String get policyOriginalNotice =>
      'El texto vigente de la política y los avisos de la API se muestran en su idioma original. Los datos exportados también conservan los valores originales.';

  @override
  String get privacySectionAccount => 'Cuenta';

  @override
  String get privacySectionSessions => 'Sesiones de acceso';

  @override
  String get privacySectionEnrollments => 'Inscripciones';

  @override
  String get privacySectionSchedule => 'Agenda';

  @override
  String get privacySectionActivities => 'Actividades';

  @override
  String get privacySectionEvents => 'Eventos de actividad';

  @override
  String get privacySectionFoods => 'Alimentos propios';

  @override
  String get privacySectionIntakes => 'Registros de consumo';

  @override
  String get privacyConfirmPhrase =>
      'Escribe EXCLUIR MINHA CONTA para confirmar.';

  @override
  String get privacyRecentLogin =>
      'Confirma tu cuenta con Google de nuevo para autorizar la eliminación.';

  @override
  String get privacySessionConfirm =>
      'Tu sesión necesita confirmación. Entra de nuevo con Google.';

  @override
  String get privacyIntentExpired =>
      'La confirmación ha caducado o no pertenece a esta sesión. Solicita una nueva confirmación.';

  @override
  String get privacyCleanupPending =>
      'La cuenta ya se ha eliminado. La limpieza local sigue pendiente.';

  @override
  String get privacyDeletionUnconfirmed =>
      'No se ha podido confirmar la eliminación. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get privacyQueryFailed =>
      'No se han podido consultar los datos. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get privacyActionFailed =>
      'No se ha podido completar la acción. Inténtalo de nuevo.';

  @override
  String get understood => 'Entendido';

  @override
  String get startingPoint => 'Tu punto de partida';

  @override
  String get activityProgress => 'Actividad y evolución';

  @override
  String get accountPreferences => 'Cuenta y preferencias';

  @override
  String get versionHelp => 'Ayuda de esta versión';

  @override
  String get evaluationUpper => 'VERSIÓN DE EVALUACIÓN · DISPONIBILIDAD REAL';

  @override
  String get exploreWithoutSetup => 'Explora sin configurar';

  @override
  String get exploreWithoutSetupHint =>
      'Ya puedes consultar la biblioteca de movimientos y la composición de alimentos. Entra con Google para tus registros privados de alimentación.';

  @override
  String get setupNotAvailable => 'Configuración aún no disponible';

  @override
  String get setupNotAvailableHint =>
      'Áreas, objetivos, entornos, experiencia, rutina y revisión aún no se guardan en esta versión. Ninguna elección se ha inferido de la cuenta Google. No hay una configuración obligatoria simulada para acceder a la navegación.';

  @override
  String get scopeCaregivers =>
      'Casa, parques y gimnasio siguen en el alcance, al igual que personas mayores y cuidadores. El foco es que los cuidadores entrenen para sí mismos durante las pausas de trabajo. La biblioteca no determina adecuación clínica ni elegibilidad.';

  @override
  String get noActivityRecording => 'Aún sin registro de actividad';

  @override
  String get noActivityRecordingHint =>
      'Iniciar, pausar, finalizar y consultar una actividad dependen del servicio de registro. Esta versión no crea series, dosis, sesiones, rutas, gasto ni finalización de entrenamientos.';

  @override
  String get permissionsDevices => 'Permisos y dispositivos';

  @override
  String get permissionsDevicesHint =>
      'GPS, sensores, Health Connect y cámara no están integrados. Esta pantalla no solicita permisos ni recoge ubicación, imágenes ni datos de dispositivos. El registro por imagen y OCR tampoco están disponibles.';

  @override
  String get historyProgress => 'Historial y evolución';

  @override
  String get historyProgressHint =>
      'Gráficos, períodos de actividad, medidas y objetivos requieren registros y cálculos propios. La falta de implementación no significa actividad cero. El historial alimentario confirmado sigue accesible en el Diario.';

  @override
  String get googleIdentity => 'Identidad de Google';

  @override
  String get googleIdentityHint =>
      'El nombre y correo son los confirmados al entrar. Su edición en TrainForge aún no está disponible. La confirmación de conexión, cierre de sesión, exportación y eliminación tienen acciones propias en el perfil.';

  @override
  String get devicePreferences => 'Preferencias del dispositivo';

  @override
  String get devicePreferencesHint =>
      'Claro, oscuro, seguir dispositivo e idioma están disponibles en preferencias. Estas elecciones se guardan en este dispositivo y están separadas de la cuenta. Unidades, medidas y objetivos aún no tienen edición persistida. Los alimentos conservan nombres, bases y unidades de la fuente hasta disponer de traducciones revisadas.';

  @override
  String get whatToTest => 'Lo que ya puedes probar';

  @override
  String get whatToTestHint =>
      'Entrar con Google, consultar movimientos y alimentos, crear alimentos privados y registrar lo consumido. El Diario permite revisar el origen, corregir y eliminar consumo; Privacidad permite consultar y copiar páginas de tus datos.';

  @override
  String get faq => 'Preguntas frecuentes';

  @override
  String get whyOriginalNames => '¿Por qué hay nombres en francés e inglés?';

  @override
  String get whyOriginalNamesHint =>
      'Son nombres originales de Ciqual y CoFID. No creamos traducciones que puedan cambiar la identidad del alimento.';

  @override
  String get unknownMeansZero =>
      '¿Una traza o un valor desconocido significa cero?';

  @override
  String get unknownMeansZeroHint =>
      'No. Las bases ausentes, los valores desconocidos, los límites y los métodos diferentes siguen explícitos. Las cantidades estimadas también se identifican.';

  @override
  String get libraryGuidesTraining =>
      '¿La biblioteca ya guía mi entrenamiento?';

  @override
  String get libraryGuidesTrainingHint =>
      'Todavía no. Los metadatos son solo de consulta; no hay programas, dosis, instrucciones ni medios aprobados para la práctica.';

  @override
  String get reportProblem => '¿Cómo informar de un problema?';

  @override
  String get reportProblemHint =>
      'Anota la pantalla, la acción y el resultado esperado para la evaluación. Oculta correo, datos personales y registros antes de compartir capturas. El envío de comentarios desde la aplicación aún no está implementado.';

  @override
  String get evaluationConditions => 'Condiciones de esta evaluación';

  @override
  String get evaluationConditionsHint =>
      'La política de datos vigente viene de la API en Privacidad y datos. Faltan por definir las condiciones de producción y el canal de soporte; este texto no sustituye esos documentos. No hay prescripción, reconocimiento de alimentos por foto ni objetivos automáticos.';

  @override
  String get browseLibrary => 'Consultar biblioteca';

  @override
  String get browseFoods => 'Consultar alimentos';

  @override
  String get searchFoodNames => 'Buscar por nombre';

  @override
  String get reviewedNamesHint =>
      'Busca el nombre original o un nombre/alias revisado en el idioma elegido. Sin revisión, se conserva el original.';

  @override
  String get reviewedFoodName => 'Nombre revisado en este idioma';

  @override
  String get originalFoodName => 'Nombre original';

  @override
  String get nameReviewSource => 'Revisión y derechos del nombre';

  @override
  String get nameCatalogChanged =>
      'Los nombres revisados han cambiado. Se descartó la página anterior; revisa la consulta actualizada.';

  @override
  String get foodNameFallback =>
      'No hay un nombre revisado en este idioma. Se muestra el nombre original de la fuente.';

  @override
  String get retryReadPreference => 'Volver a leer la preferencia';

  @override
  String get readingPreferences => 'Leyendo preferencia';

  @override
  String get trainingConfiguration => 'Configuración de entrenamiento';

  @override
  String get trainingConfigIntro =>
      'Indica dónde y cuándo puedes entrenar. Revisa todo antes de confirmar.';

  @override
  String get trainingConfigNotice =>
      'Esta configuración describe tu rutina. No confirma tu aptitud física ni crea un entrenamiento. Los programas y las reglas necesitan revisión humana.';

  @override
  String get configPlaces => 'Lugares y contexto';

  @override
  String get configResources => 'Equipamiento disponible';

  @override
  String get configAvailability => 'Disponibilidad';

  @override
  String get configReview => 'Revisión final';

  @override
  String configStep(int step) {
    return 'Paso $step de 4';
  }

  @override
  String get configWhere => '¿Dónde puedes entrenar?';

  @override
  String get configHome => 'Casa';

  @override
  String get configPark => 'Plaza o parque';

  @override
  String get configGym => 'Gimnasio';

  @override
  String get configContext => '¿En qué contexto?';

  @override
  String get configPersonal => 'En mi rutina personal';

  @override
  String get configCaregiver =>
      'Durante mis descansos de trabajo como cuidador';

  @override
  String get configCaregiverHint =>
      'El entrenamiento es para ti, no para la persona que cuidas.';

  @override
  String get configDeclared => 'Voy a indicar el equipamiento que tengo';

  @override
  String get configNone => 'No tengo equipamiento';

  @override
  String get configUnknown => 'Todavía no sé qué tengo';

  @override
  String get configEquipmentHint =>
      'No saber es distinto de no tener. Selecciona hasta 32 elementos por sus nombres originales de la fuente.';

  @override
  String get configSelected => 'Equipamiento seleccionado';

  @override
  String get configResourceWithdrawn =>
      'Referencia no disponible. Elimínala o elige otra antes de confirmar.';

  @override
  String get configNoResources =>
      'No se encontró equipamiento para esta búsqueda.';

  @override
  String get configTimezone => 'Zona horaria de tu rutina';

  @override
  String get configTimezoneHint =>
      'Empieza con el desfase observado en este dispositivo. Puedes usar UTC, un desfase como -03:00 o una zona como America/Sao_Paulo. Un desfase fijo no sigue los cambios de horario.';

  @override
  String get configAvailabilityHint =>
      'Indica el tiempo que tienes, no la duración de un entrenamiento prescrito. Puedes añadir varios descansos por día. El día se refiere al inicio del descanso.';

  @override
  String get configDay => 'Día de la semana';

  @override
  String get configMinutes => 'Minutos disponibles';

  @override
  String get configStart => 'Hora de inicio (opcional)';

  @override
  String get configUnfixed => 'Sin hora fija';

  @override
  String get configAddSlot => 'Añadir disponibilidad';

  @override
  String get configRemoveSlot => 'Eliminar disponibilidad';

  @override
  String get configMonday => 'Lunes';

  @override
  String get configTuesday => 'Martes';

  @override
  String get configWednesday => 'Miércoles';

  @override
  String get configThursday => 'Jueves';

  @override
  String get configFriday => 'Viernes';

  @override
  String get configSaturday => 'Sábado';

  @override
  String get configSunday => 'Domingo';

  @override
  String get configNext => 'Continuar';

  @override
  String get configEdit => 'Editar respuestas';

  @override
  String get configConfirm => 'Confirmar configuración';

  @override
  String get configSaved => 'Configuración confirmada';

  @override
  String get configSavedHint =>
      'Tus respuestas están guardadas en tu cuenta. Todavía no hay un programa aprobado para mostrar.';

  @override
  String get configUnavailable =>
      'No se pudo confirmar la configuración. Revisa la conexión e inténtalo de nuevo. Las respuestas del formulario siguen aquí.';

  @override
  String get configConflict =>
      'La configuración de la cuenta cambió en otra confirmación. Tus respuestas se conservaron. Vuelve a cargar la versión guardada antes de editar.';

  @override
  String get configReload => 'Volver a cargar la configuración guardada';

  @override
  String get configReloadNotice =>
      'Al volver a cargar se sustituyen solo las respuestas sin guardar de este formulario. ¿Continuar?';

  @override
  String get configUncertain =>
      'La confirmación puede haber llegado al servidor. Repite la misma confirmación para comprobar el resultado sin crear otra versión. Si sales, revisa la configuración guardada al volver.';

  @override
  String get configLeaveCheck => 'Salir y revisar la configuración después';

  @override
  String get configChoosePlace => 'Selecciona al menos un lugar.';

  @override
  String get configChooseContext => 'Elige tu contexto.';

  @override
  String get configChooseStatus =>
      'Indica si tienes equipamiento, no lo tienes o todavía no lo sabes.';

  @override
  String get configChooseResource =>
      'Selecciona entre 1 y 32 elementos disponibles.';

  @override
  String get configInvalidTimezone =>
      'Revisa la zona: UTC, desfase hasta 14:00 o una zona reconocida.';

  @override
  String get configChooseDay => 'Elige un día de la semana.';

  @override
  String get configInvalidMinutes =>
      'Indica un número entero de 1 a 1440 minutos.';

  @override
  String get configInvalidSlot =>
      'Revisa la hora y evita repetir el mismo día y hora. Mantén entre 1 y 28 disponibilidades.';

  @override
  String get privacySectionTrainingConfigurations =>
      'Versiones de la configuración de entrenamiento';

  @override
  String get configEntryHint =>
      'En tu cuenta, abre Configuración de entrenamiento. También está en Planes, en Crear mi plan. Revisa lugares, contexto, equipamiento y disponibilidad antes de confirmar.';

  @override
  String get mealDiary => 'Comidas y alimentos';

  @override
  String get byMeal => 'Por comida';

  @override
  String get byFood => 'Por alimento';

  @override
  String get recordMeal => 'Registrar comida';

  @override
  String get mealTitle => 'Nombre de la comida (opcional)';

  @override
  String get prepareMealItem => 'Preparar un alimento';

  @override
  String get addMealItem => 'Añadir alimento a la comida';

  @override
  String get mealDraftNotice =>
      'Los alimentos quedan en este borrador hasta revisar y confirmar toda la comida. Aún no se ha registrado nada.';

  @override
  String get mealReviewConfirmation =>
      'He revisado los alimentos, cantidades y horarios de esta comida.';

  @override
  String get confirmMeal => 'Confirmar comida';

  @override
  String get mealSaved => 'Comida confirmada';

  @override
  String get mealNoItems => 'Esta comida aún no contiene alimentos.';

  @override
  String get ungroupedIntakes => 'Registros sin comida indicada';

  @override
  String get mealMetadataOnly =>
      'El horario de la comida organiza el grupo. No cambia el horario ni la cantidad de cada alimento.';

  @override
  String get correctMeal => 'Corregir nombre u horario de la comida';

  @override
  String get deleteMeal => 'Eliminar toda la comida';

  @override
  String get deleteMealConfirm =>
      'Esto elimina la comida y todos sus consumos activos. Para eliminar solo un alimento, ábralo por separado.';

  @override
  String get mealDeleted => 'Comida eliminada';

  @override
  String get mealConflictNotice =>
      'Revise el historial antes de registrar de nuevo. La comida puede haberse confirmado o modificado; este borrador no se reenviará como un registro nuevo.';

  @override
  String get mealItemPending => 'Borrador — aún no registrado';

  @override
  String get mealDraftLimit => 'Puede registrar hasta 32 alimentos a la vez.';

  @override
  String get removeMealItem => 'Quitar alimento del borrador';

  @override
  String get mealUnnamed => 'Comida sin nombre';

  @override
  String get viewMeals => 'Ver por comida o alimento';

  @override
  String get mealDayScope =>
      'Cambie la vista de los mismos registros confirmados. El horario de cada alimento determina el día en que aparece.';

  @override
  String get mealEmptyGroup => 'Esta comida ya no tiene alimentos activos.';

  @override
  String mealItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos',
      one: '1 alimento',
    );
    return '$_temp0';
  }

  @override
  String mealOtherItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos de esta comida están fuera de esta selección.',
      one: '1 alimento de esta comida está fuera de esta selección.',
    );
    return '$_temp0';
  }

  @override
  String get privacySectionMeals => 'Comidas';

  @override
  String get privacySectionMealItems => 'Alimentos vinculados a comidas';

  @override
  String get privacySectionMealVersions => 'Revisiones de comidas';
}

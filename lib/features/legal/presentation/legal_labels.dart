import 'package:flutter/widgets.dart';

String legalLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ??
      _labels['en']![key] ??
      key;
}

const _labels = <String, Map<String, String>>{
  'pt': {
    'beforeStart': 'Antes de começar',
    'beforeStartBody':
        'Para usar sua conta no TrainForge, leia e aceite os documentos abaixo.',
    'terms': 'Termos de Uso',
    'privacy': 'Política de Privacidade',
    'acceptDocs': 'Li e aceito os Termos de Uso e a Política de Privacidade.',
    'adult':
        'Tenho 18 anos ou mais, ou uso com autorização do meu responsável.',
    'continue': 'Continuar',
    'notMedical':
        'O TrainForge não substitui orientação médica ou nutricional.',
    'update': 'Atualização',
    'changedTitle': 'Os termos mudaram',
    'changedBody': 'Atualizamos os documentos. Veja o que mudou:',
    'acceptNew': 'Li e aceito a nova versão.',
    'acceptContinue': 'Aceitar e continuar',
    'deleteAccount': 'Excluir minha conta',
    'healthTitle': 'Seus dados de saúde',
    'healthBody':
        'Refeições, consumo e treinos podem revelar informações sobre sua saúde. Eles ficam no seu celular e, com sua conta, são sincronizados em servidores no Brasil.',
    'healthCheck':
        'Autorizo o TrainForge a guardar e sincronizar meus registros de alimentação e treino para as funções do app.',
    'healthHint':
        'Você pode retirar esta autorização e excluir seus dados em Configurações. Sem ela, os registros ficam só neste celular.',
    'authorize': 'Autorizar e continuar',
    'notNow': 'Agora não',
    'legalSettings': 'Termos e privacidade',
    'legalSettingsHint': 'Aceites, dados de saúde e licenças',
    'acceptedVersion': 'v{v} aceita',
    'acceptedOn': 'Aceita em {date}',
    'healthData': 'Dados de saúde',
    'granted': 'autorizado',
    'notGranted': 'não autorizado',
    'grant': 'Autorizar',
    'revoke': 'Retirar autorização',
    'licenses': 'Licenças de software',
    'syncPausedHealth':
        'Sincronização pausada: autorize os dados de saúde em Configurações → Termos e privacidade.',
    'open': 'Abrir',
    'readError': 'Não foi possível abrir o documento.',
    'saveError': 'Não foi possível salvar o aceite. Tente de novo.',
    'decline': 'Não aceito, sair da conta',
  },
  'en': {
    'beforeStart': 'Before you start',
    'beforeStartBody':
        'To use TrainForge, read and accept the documents below.',
    'terms': 'Terms of Use',
    'privacy': 'Privacy Policy',
    'acceptDocs': 'I have read and accept the Terms of Use and Privacy Policy.',
    'adult': "I'm 18 or older, or I use it with my guardian's permission.",
    'continue': 'Continue',
    'notMedical': 'TrainForge does not replace medical or nutrition advice.',
    'update': 'Update',
    'changedTitle': 'The terms changed',
    'changedBody': "We updated the documents. Here's what changed:",
    'acceptNew': 'I have read and accept the new version.',
    'acceptContinue': 'Accept and continue',
    'deleteAccount': 'Delete my account',
    'healthTitle': 'Your health data',
    'healthBody':
        'Meals, intake and workouts can reveal information about your health. They stay on your phone and, with your account, sync to servers in Brazil.',
    'healthCheck':
        'I allow TrainForge to store and sync my food and workout records for the app features.',
    'healthHint':
        'You can withdraw this and delete your data in Settings. Without it, records stay only on this phone.',
    'authorize': 'Allow and continue',
    'notNow': 'Not now',
    'legalSettings': 'Terms and privacy',
    'legalSettingsHint': 'Acceptances, health data and licenses',
    'acceptedVersion': 'v{v} accepted',
    'acceptedOn': 'Accepted on {date}',
    'healthData': 'Health data',
    'granted': 'allowed',
    'notGranted': 'not allowed',
    'grant': 'Allow',
    'revoke': 'Withdraw permission',
    'licenses': 'Software licenses',
    'syncPausedHealth':
        'Sync paused: allow health data in Settings → Terms and privacy.',
    'open': 'Open',
    'readError': "Couldn't open the document.",
    'saveError': "Couldn't save your acceptance. Try again.",
    'decline': "I don't accept, sign out",
  },
  'es': {
    'beforeStart': 'Antes de empezar',
    'beforeStartBody':
        'Para usar TrainForge, lee y acepta los documentos siguientes.',
    'terms': 'Términos de uso',
    'privacy': 'Política de privacidad',
    'acceptDocs':
        'He leído y acepto los Términos de uso y la Política de privacidad.',
    'adult':
        'Tengo 18 años o más, o lo uso con autorización de mi responsable.',
    'continue': 'Continuar',
    'notMedical':
        'TrainForge no sustituye la orientación médica o nutricional.',
    'update': 'Actualización',
    'changedTitle': 'Los términos cambiaron',
    'changedBody': 'Actualizamos los documentos. Esto es lo que cambió:',
    'acceptNew': 'He leído y acepto la nueva versión.',
    'acceptContinue': 'Aceptar y continuar',
    'deleteAccount': 'Eliminar mi cuenta',
    'healthTitle': 'Tus datos de salud',
    'healthBody':
        'Comidas, consumo y entrenamientos pueden revelar información sobre tu salud. Quedan en tu teléfono y, con tu cuenta, se sincronizan en servidores en Brasil.',
    'healthCheck':
        'Autorizo a TrainForge a guardar y sincronizar mis registros de alimentación y entrenamiento para las funciones de la app.',
    'healthHint':
        'Puedes retirar esta autorización y eliminar tus datos en Ajustes. Sin ella, los registros quedan solo en este teléfono.',
    'authorize': 'Autorizar y continuar',
    'notNow': 'Ahora no',
    'legalSettings': 'Términos y privacidad',
    'legalSettingsHint': 'Aceptaciones, datos de salud y licencias',
    'acceptedVersion': 'v{v} aceptada',
    'acceptedOn': 'Aceptada el {date}',
    'healthData': 'Datos de salud',
    'granted': 'autorizado',
    'notGranted': 'no autorizado',
    'grant': 'Autorizar',
    'revoke': 'Retirar autorización',
    'licenses': 'Licencias de software',
    'syncPausedHealth':
        'Sincronización en pausa: autoriza los datos de salud en Ajustes → Términos y privacidad.',
    'open': 'Abrir',
    'readError': 'No se pudo abrir el documento.',
    'saveError': 'No se pudo guardar la aceptación. Inténtalo de nuevo.',
    'decline': 'No acepto, cerrar sesión',
  },
};

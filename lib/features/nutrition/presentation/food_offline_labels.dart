import 'package:flutter/widgets.dart';

String foodOfflineLabel(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return (_labels[language] ?? _labels['en']!)[key] ??
      _labels['en']![key] ??
      key;
}

const _labels = <String, Map<String, String>>{
  'en': {
    'offlineDiary': 'Saved on this device',
    'pending': 'Pending synchronization',
    'confirmed': 'Confirmed by server',
    'sync': 'Synchronize',
    'syncing': 'Synchronizing…',
    'syncFailure':
        'Your data remains saved on this device. Synchronization is pending.',
    'authFailure':
        'Sign in again to synchronize. Your local data is preserved.',
    'conflicts': 'Review conflicts',
    'serverVersion': 'Use the server version',
    'keepLocal': 'Reapply my change',
    'onDevice': 'On this device',
    'onServer': 'On the server',
    'reviewRequired': 'These data need review before they can be synchronized.',
    'withdrawn': 'Withdrawn',
    'conflictNotice':
        'Your local change has not replaced the server record. Review both versions before choosing.',
    'scan': 'Scan barcode',
    'scanHint':
        'Point the camera at the product barcode. The lookup works offline.',
    'scanUnavailable':
        'Camera unavailable. You can enter the barcode manually.',
    'barcode': 'Barcode',
    'brand': 'Brand (optional)',
    'notFound': 'Product not found in the installed catalog.',
    'manual': 'Create a personal food',
    'portion': 'Documented portion',
    'manualQuantity': 'Enter grams or millilitres',
    'portionCount': 'Number of portions',
    'addPortion': 'Add a measured portion',
    'portionLabel': 'Measure name (for example, level spoon)',
    'portionCondition': 'Condition (optional: drained, level, full)',
    'personalPortionNotice':
        'Add only a weight or volume you know for this food. A spoon or package has no universal weight.',
    'portionNotice':
        'This portion applies only to this food and preparation. The amount can be adjusted below.',
    'helpCatalog': 'Help expand the food catalog?',
    'suppressInvites': 'Do not show this invitation again',
    'enableInvites': 'Show contribution invitations again',
    'invitesEnabled': 'Contribution invitations enabled.',
    'invite':
        'TrainForge is free. You can voluntarily share this food for review and possible inclusion in the public catalog. Your weight and meal history will not be shared.',
    'review': 'Review contribution',
    'later': 'Not now',
    'contribute': 'Share food',
    'consent':
        'I authorize publication and reuse of these food data under CC0 1.0. I understand that already distributed public copies may remain available.',
    'contributionNotice':
        'Only the fields shown below and selected label photos will be sent to TrainForge. Publication requires review. Sharing is optional and does not affect your personal food.',
    'photo': 'Add label photo (optional)',
    'removePhoto': 'Remove photo',
    'queued': 'Contribution saved for sending when connected.',
    'contributions': 'My contributions',
    'cancelContribution': 'Withdraw contribution',
    'cancelled': 'Cancelled',
    'submitted': 'Submitted for review',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'catalog': 'Offline catalog',
    'catalogPreparation':
        'Preparing the complete food catalog. The first opening may take several minutes and needs storage space. After preparation, searches work offline.',
    'catalogSpace':
        'The app ships with the Brazil pack. Additional regional packs are being prepared; a downloaded pack is verified before it replaces the installed one.',
    'import': 'Import signed catalog',
    'update': 'Update catalog',
    'packs': 'Food packs',
    'installed': 'Installed',
    'downloading': 'Downloading…',
    'verifying': 'Checking signature and installing…',
    'downloadCanceled': 'Download canceled. The installed catalog was kept.',
    'cancel': 'Cancel',
    'downloadConfirmTitle': 'Download food pack?',
    'downloadConfirmBody':
        'This download has about {mb} MB. Prefer Wi-Fi. The installed catalog keeps working until the new one is verified.',
    'packBrazil': 'Brazil (installed with the app)',
    'packBrazilPortugal': 'Brazil + Portugal',
    'download': 'Download pack',
    'catalogNotice':
        'The installed catalog works without a connection. Packs are signed by TrainForge and downloaded from its public GitHub releases. Your meals and personal foods are preserved.',
    'imported': 'Catalog installed. Reopen the food search to use it.',
    'importFailure':
        'The catalog could not be verified or installed. The previous version is preserved.',
    'source': 'Source',
    'pendingTotals': 'These totals include entries saved only on this device.',
  },
  'pt': {
    'offlineDiary': 'Salvo neste aparelho',
    'pending': 'Pendente de sincronização',
    'confirmed': 'Confirmado pelo servidor',
    'sync': 'Sincronizar',
    'syncing': 'Sincronizando…',
    'syncFailure':
        'Os dados continuam salvos neste aparelho. A sincronização está pendente.',
    'authFailure':
        'Entre novamente para sincronizar. Os dados locais foram preservados.',
    'conflicts': 'Revisar conflitos',
    'serverVersion': 'Usar a versão do servidor',
    'keepLocal': 'Reaplicar minha alteração',
    'onDevice': 'Neste aparelho',
    'onServer': 'No servidor',
    'reviewRequired': 'Estes dados precisam de revisão antes de sincronizar.',
    'withdrawn': 'Retirada',
    'conflictNotice':
        'Sua alteração local não substituiu o registro do servidor. Confira as duas versões antes de escolher.',
    'scan': 'Ler código de barras',
    'scanHint':
        'Aponte a câmera para o código de barras do produto. A consulta funciona offline.',
    'scanUnavailable':
        'Câmera indisponível. Você pode digitar o código de barras.',
    'barcode': 'Código de barras',
    'brand': 'Marca (opcional)',
    'notFound': 'Produto não encontrado no catálogo instalado.',
    'manual': 'Cadastrar alimento pessoal',
    'portion': 'Porção documentada',
    'manualQuantity': 'Informar gramas ou mililitros',
    'portionCount': 'Quantidade de porções',
    'addPortion': 'Adicionar porção medida',
    'portionLabel': 'Nome da medida (ex.: colher rasa)',
    'portionCondition': 'Condição (opcional: drenado, rasa, cheia)',
    'personalPortionNotice':
        'Informe somente um peso ou volume conhecido para este alimento. Colher e embalagem não têm peso universal.',
    'portionNotice':
        'Esta medida se aplica somente a este alimento e preparo. Ajuste a quantidade abaixo, se necessário.',
    'helpCatalog': 'Quer ajudar a ampliar o catálogo?',
    'suppressInvites': 'Não mostrar este convite novamente',
    'enableInvites': 'Mostrar convites de contribuição novamente',
    'invitesEnabled': 'Convites de contribuição ativados.',
    'invite':
        'O TrainForge é gratuito. Você pode compartilhar voluntariamente este alimento para revisão e possível inclusão no catálogo público. Seu peso e histórico de refeições não serão compartilhados.',
    'review': 'Revisar contribuição',
    'later': 'Agora não',
    'contribute': 'Compartilhar alimento',
    'consent':
        'Autorizo a publicação e reutilização destes dados alimentares sob CC0 1.0. Entendo que cópias públicas já distribuídas podem continuar disponíveis.',
    'contributionNotice':
        'Serão enviados ao TrainForge somente os campos abaixo e as fotos de rótulo selecionadas. A publicação depende de revisão. Compartilhar é opcional e não altera seu alimento pessoal.',
    'photo': 'Adicionar foto do rótulo (opcional)',
    'removePhoto': 'Remover foto',
    'queued': 'Contribuição salva para envio quando houver conexão.',
    'contributions': 'Minhas contribuições',
    'cancelContribution': 'Retirar contribuição',
    'cancelled': 'Cancelada',
    'submitted': 'Enviada para revisão',
    'approved': 'Aprovada',
    'rejected': 'Rejeitada',
    'catalog': 'Catálogo offline',
    'catalogPreparation':
        'Preparando o catálogo completo de alimentos. A primeira abertura pode levar vários minutos e precisa de espaço no aparelho. Depois, as buscas funcionam offline.',
    'catalogSpace':
        'O app já vem com o pacote do Brasil. Pacotes regionais adicionais estão em preparação; um pacote baixado é verificado antes de substituir o instalado.',
    'import': 'Importar catálogo assinado',
    'update': 'Atualizar catálogo',
    'packs': 'Pacotes de alimentos',
    'installed': 'Instalado',
    'downloading': 'Baixando…',
    'verifying': 'Conferindo assinatura e instalando…',
    'downloadCanceled': 'Download cancelado. O catálogo instalado foi mantido.',
    'cancel': 'Cancelar',
    'downloadConfirmTitle': 'Baixar pacote de alimentos?',
    'downloadConfirmBody':
        'Este download tem cerca de {mb} MB. Prefira usar Wi-Fi. O catálogo instalado continua funcionando até o novo ser verificado.',
    'packBrazil': 'Brasil (já vem no app)',
    'packBrazilPortugal': 'Brasil + Portugal',
    'download': 'Baixar pacote',
    'catalogNotice':
        'O catálogo instalado funciona sem conexão. Os pacotes são assinados pelo TrainForge e baixados das publicações públicas dele no GitHub. Refeições e alimentos pessoais são preservados.',
    'imported': 'Catálogo instalado. Reabra a busca de alimentos para usá-lo.',
    'importFailure':
        'Não foi possível verificar ou instalar o catálogo. A versão anterior foi preservada.',
    'source': 'Fonte',
    'pendingTotals':
        'Estes totais incluem registros salvos somente neste aparelho.',
  },
  'es': {
    'offlineDiary': 'Guardado en este dispositivo',
    'pending': 'Sincronización pendiente',
    'confirmed': 'Confirmado por el servidor',
    'sync': 'Sincronizar',
    'syncing': 'Sincronizando…',
    'syncFailure':
        'Los datos siguen guardados en este dispositivo. La sincronización está pendiente.',
    'authFailure':
        'Inicia sesión de nuevo para sincronizar. Los datos locales se conservan.',
    'conflicts': 'Revisar conflictos',
    'serverVersion': 'Usar la versión del servidor',
    'keepLocal': 'Volver a aplicar mi cambio',
    'onDevice': 'En este dispositivo',
    'onServer': 'En el servidor',
    'reviewRequired': 'Estos datos requieren revisión antes de sincronizar.',
    'withdrawn': 'Retirada',
    'conflictNotice':
        'Tu cambio local no ha sustituido el registro del servidor. Revisa ambas versiones antes de elegir.',
    'scan': 'Leer código de barras',
    'scanHint':
        'Apunta la cámara al código de barras. La consulta funciona sin conexión.',
    'scanUnavailable':
        'Cámara no disponible. Puedes escribir el código de barras.',
    'barcode': 'Código de barras',
    'brand': 'Marca (opcional)',
    'notFound': 'Producto no encontrado en el catálogo instalado.',
    'manual': 'Crear alimento personal',
    'portion': 'Porción documentada',
    'manualQuantity': 'Introducir gramos o mililitros',
    'portionCount': 'Número de porciones',
    'addPortion': 'Añadir porción medida',
    'portionLabel': 'Nombre de la medida (p. ej., cuchara rasa)',
    'portionCondition': 'Condición (opcional: escurrido, rasa, llena)',
    'personalPortionNotice':
        'Añade solo un peso o volumen conocido para este alimento. Las cucharas y los envases no tienen un peso universal.',
    'portionNotice':
        'Esta medida corresponde solo a este alimento y preparación. Puedes ajustar la cantidad abajo.',
    'helpCatalog': '¿Quieres ayudar a ampliar el catálogo?',
    'suppressInvites': 'No volver a mostrar esta invitación',
    'enableInvites': 'Volver a mostrar invitaciones de contribución',
    'invitesEnabled': 'Invitaciones de contribución activadas.',
    'invite':
        'TrainForge es gratuito. Puedes compartir voluntariamente este alimento para su revisión y posible inclusión en el catálogo público. Tu peso e historial de comidas no se compartirán.',
    'review': 'Revisar contribución',
    'later': 'Ahora no',
    'contribute': 'Compartir alimento',
    'consent':
        'Autorizo la publicación y reutilización de estos datos alimentarios bajo CC0 1.0. Entiendo que las copias públicas ya distribuidas pueden seguir disponibles.',
    'contributionNotice':
        'Solo se enviarán a TrainForge los campos mostrados y las fotos de etiqueta seleccionadas. La publicación requiere revisión. Compartir es opcional y no modifica tu alimento personal.',
    'photo': 'Añadir foto de etiqueta (opcional)',
    'removePhoto': 'Quitar foto',
    'queued': 'Contribución guardada para enviar cuando haya conexión.',
    'contributions': 'Mis contribuciones',
    'cancelContribution': 'Retirar contribución',
    'cancelled': 'Cancelada',
    'submitted': 'Enviada para revisión',
    'approved': 'Aprobada',
    'rejected': 'Rechazada',
    'catalog': 'Catálogo sin conexión',
    'catalogPreparation':
        'Preparando el catálogo completo de alimentos. La primera apertura puede tardar varios minutos y necesita espacio. Después, las búsquedas funcionan sin conexión.',
    'catalogSpace':
        'La app incluye el paquete de Brasil. Se están preparando paquetes regionales adicionales; un paquete descargado se verifica antes de reemplazar el instalado.',
    'import': 'Importar catálogo firmado',
    'update': 'Actualizar catálogo',
    'packs': 'Paquetes de alimentos',
    'installed': 'Instalado',
    'downloading': 'Descargando…',
    'verifying': 'Verificando firma e instalando…',
    'downloadCanceled': 'Descarga cancelada. Se conservó el catálogo instalado.',
    'cancel': 'Cancelar',
    'downloadConfirmTitle': '¿Descargar paquete de alimentos?',
    'downloadConfirmBody':
        'Esta descarga tiene unos {mb} MB. Prefiere usar Wi-Fi. El catálogo instalado sigue funcionando hasta verificar el nuevo.',
    'packBrazil': 'Brasil (incluido en la app)',
    'packBrazilPortugal': 'Brasil + Portugal',
    'download': 'Descargar paquete',
    'catalogNotice':
        'El catálogo instalado funciona sin conexión. Los paquetes están firmados por TrainForge y se descargan de sus publicaciones públicas en GitHub. Se conservan tus comidas y alimentos personales.',
    'imported': 'Catálogo instalado. Vuelve a abrir la búsqueda para usarlo.',
    'importFailure':
        'No se pudo verificar o instalar el catálogo. Se conserva la versión anterior.',
    'source': 'Fuente',
    'pendingTotals':
        'Estos totales incluyen registros guardados solo en este dispositivo.',
  },
};

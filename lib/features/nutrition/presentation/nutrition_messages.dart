import 'package:dio/dio.dart';

String nutritionError(Object error) {
  if (error is StateError) {
    return 'A conta mudou. Volte à entrada antes de continuar.';
  }
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      400 => 'Confira quantidade, unidade, data, preparo e campos informados.',
      401 => 'Sua sessão expirou. Entre novamente com Google.',
      404 => 'O alimento ou registro está indisponível. Atualize a consulta.',
      409 =>
        'O registro ou a conta mudou. Atualize o histórico antes de corrigir.',
      429 => 'Muitas tentativas. Aguarde um minuto e tente novamente.',
      _ =>
        'Não foi possível confirmar a ação. Confira a conexão e tente novamente. Repetir a mesma ação não duplica o registro.',
    };
  }
  return 'Não foi possível confirmar a ação. Tente novamente.';
}

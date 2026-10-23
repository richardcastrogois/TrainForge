import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/privacy.dart';

class PrivacyController extends ChangeNotifier {
  final PrivacyRepository repository;
  final Future<void> Function(String)? afterDeletion;
  final String? Function()? currentAccountId;
  PrivacyController(
    this.repository, {
    this.afterDeletion,
    this.currentAccountId,
  });
  PrivacyPolicy? policy;
  PrivateExportPage? exportPage;
  DeletionIntent? deletionIntent;
  AccountErasure? erased;
  bool busy = false, _disposed = false;
  String? error;
  String section = 'account';
  int _generation = 0;
  Future<void> loadPolicy() => _run(() async {
    final value = await repository.policy();
    if (!_disposed) policy = value;
  });
  Future<void> loadExport({String? section, bool next = false}) async {
    if (busy || _disposed) return;
    if (section != null) this.section = section;
    final cursor = next ? exportPage?.cursor : null;
    exportPage = null;
    await _run(() async {
      final value = await repository.export(this.section, cursor: cursor);
      if (!_disposed) {
        final current = currentAccountId?.call();
        if (currentAccountId != null && current != value.accountId) {
          throw StateError("Account changed");
        }
        exportPage = value;
      }
    });
  }

  Future<void> confirmAccount(Future<void> Function() action) => _run(() async {
    deletionIntent = null;
    exportPage = null;
    await action();
  });
  Future<void> requestDeletion() => _run(() async {
    deletionIntent = null;
    final value = await repository.intent();
    if (!_disposed) deletionIntent = value;
  });
  void cancelDeletion() {
    if (busy) return;
    deletionIntent = null;
    error = null;
    notifyListeners();
  }

  Future<void> erase(String confirmation) => _run(() async {
    final intent = deletionIntent;
    if (intent == null || confirmation != 'EXCLUIR MINHA CONTA') {
      error = 'Digite EXCLUIR MINHA CONTA para confirmar.';
      return;
    }
    final result = await repository.erase(intent, confirmation);
    if (!_disposed) {
      erased = result;
      deletionIntent = null;
      exportPage = null;
    }
    // Server erasure is already confirmed: local cleanup failure must not turn it
    // into a claim that the account still exists or trigger another DELETE.
    if (!result.cleanupPending && afterDeletion != null) {
      try {
        await afterDeletion!(result.accountId);
      } catch (_) {
        if (!_disposed) {
          erased = AccountErasure(
            result.accountId,
            result.backupNotice,
            cleanupPending: true,
          );
        }
      }
    }
  });
  Future<void> finishCleanup() => _run(() async {
    final result = erased;
    if (result == null) return;
    await repository.finishCleanup();
    if (afterDeletion != null) await afterDeletion!(result.accountId);
    erased = AccountErasure(result.accountId, result.backupNotice);
  });
  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    final generation = ++_generation;
    notifyListeners();
    try {
      await action();
    } on DioException catch (e) {
      if (!_disposed && generation == _generation) {
        final code = e.response?.data is Map
            ? (e.response?.data as Map)['code']
            : null;
        error = code == 'recent_login_required'
            ? 'Confirme sua conta com Google novamente para autorizar a exclusão.'
            : e.response?.statusCode == 401
            ? 'Sua sessão precisa ser confirmada. Entre novamente com Google.'
            : e.response?.statusCode == 429
            ? 'Muitas solicitações. Aguarde um minuto e tente novamente.'
            : code == 'deletion_confirmation_invalid'
            ? 'A confirmação expirou ou não pertence a esta sessão. Solicite uma nova confirmação.'
            : (erased != null
                  ? 'A conta já foi excluída. A limpeza local permanece pendente.'
                  : deletionIntent != null
                  ? 'Não foi possível confirmar a exclusão. Verifique a conexão e tente novamente.'
                  : 'Não foi possível consultar os dados. Verifique a conexão e tente novamente.');
        if (code == 'deletion_confirmation_invalid' ||
            code == 'recent_login_required') {
          deletionIntent = null;
        }
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        error = 'Não foi possível concluir. Tente novamente.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    deletionIntent = null;
    exportPage = null;
    super.dispose();
  }
}

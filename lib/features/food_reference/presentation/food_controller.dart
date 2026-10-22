import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../domain/food_reference.dart';

class FoodController extends ChangeNotifier {
  final FoodRepository repository;
  FoodController(this.repository);
  List<FoodReference> items = [];
  FoodFacets? facets;
  String q = '', sourceId = '';
  String? cursor, error, moreError;
  bool busy = false, loadingMore = false, _disposed = false;
  int _generation = 0;
  Future<void> load({String? q, String? sourceId}) async {
    if (_disposed) return;
    if (q != null) this.q = q;
    if (sourceId != null) this.sourceId = sourceId;
    final generation = ++_generation;
    busy = true;
    loadingMore = false;
    error = null;
    moreError = null;
    items = [];
    cursor = null;
    notifyListeners();
    if (utf8.encode(this.q).length > 100) {
      error = 'A busca ficou longa. Use uma parte do nome original.';
      busy = false;
      notifyListeners();
      return;
    }
    try {
      final r = await Future.wait<Object>([
        repository.list(q: this.q, sourceId: this.sourceId),
        repository.facets(),
      ]);
      if (_disposed || generation != _generation) return;
      final page = r[0] as FoodPageData;
      items = page.items;
      cursor = page.nextCursor;
      facets = r[1] as FoodFacets;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error =
          'Não foi possível consultar os alimentos. Verifique a conexão e tente novamente.';
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> more() async {
    if (_disposed || busy || loadingMore || cursor == null) return;
    final generation = _generation;
    loadingMore = true;
    moreError = null;
    notifyListeners();
    try {
      final page = await repository.list(
        q: q,
        sourceId: sourceId,
        cursor: cursor,
      );
      if (_disposed || generation != _generation) return;
      final ids = items.map((v) => v.id).toSet();
      items = [...items, ...page.items.where((v) => ids.add(v.id))];
      cursor = page.nextCursor;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        moreError =
            'Não foi possível carregar mais alimentos. Tente novamente.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

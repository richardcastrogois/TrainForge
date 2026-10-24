import 'package:flutter/foundation.dart';
import '../domain/catalog_entry.dart';

class CatalogController extends ChangeNotifier {
  final CatalogRepository repository;
  CatalogController(this.repository);
  CatalogFilters filters = const CatalogFilters();
  CatalogFacets? facets;
  List<CatalogEntry> items = [];
  String? nextCursor, error, moreError;
  bool busy = false, loadingMore = false;
  int _generation = 0;
  bool _disposed = false;
  Future<void> load({CatalogFilters? filters}) async {
    if (_disposed) return;
    if (filters != null) this.filters = filters;
    final generation = ++_generation;
    items = [];
    nextCursor = null;
    error = null;
    moreError = null;
    loadingMore = false;
    busy = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        repository.list(this.filters),
        repository.facets(),
      ]);
      if (_disposed || generation != _generation) return;
      final page = results[0] as CatalogPageData;
      items = page.items;
      nextCursor = page.nextCursor;
      facets = results[1] as CatalogFacets;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error =
          'Não foi possível consultar a biblioteca. Verifique a conexão e tente novamente.';
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> more() async {
    if (_disposed || busy || loadingMore || nextCursor == null) return;
    final generation = _generation;
    loadingMore = true;
    moreError = null;
    notifyListeners();
    try {
      final page = await repository.list(filters, cursor: nextCursor);
      if (_disposed || generation != _generation) return;
      final ids = items.map((e) => e.id).toSet();
      items = [...items, ...page.items.where((e) => ids.add(e.id))];
      nextCursor = page.nextCursor;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      moreError =
          'Não foi possível carregar a próxima página. Tente novamente.';
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

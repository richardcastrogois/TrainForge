import 'food_photo_classifier.dart';

/// One food heard in the sentence: the words used and the catalog foods it may be.
class FoodVoiceItem {
  final String heard;

  /// Best first; empty when the words match none of the known foods (search the catalog instead).
  final List<FoodPhotoClass> candidates;
  const FoodVoiceItem(this.heard, this.candidates);
}

/// Turns a spoken sentence ("arroz com feijão, dois ovos fritos e um suco de laranja")
/// into known foods. It only chooses among the 370 foods shared with the photo model;
/// it never invents a food. Longest names win, so "café com leite" stays one food.
class FoodVoiceMatcher {
  final List<FoodPhotoClass> classes;
  late final List<(List<String>, int)> _names = [
    for (var i = 0; i < classes.length; i++) (_stems(classes[i].name), i),
    for (final alias in aliases.entries)
      if (_bySlug.containsKey(alias.value))
        (_stems(alias.key), _bySlug[alias.value]!),
  ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
  late final Map<String, int> _bySlug = {
    for (var i = 0; i < classes.length; i++) classes[i].slug: i,
  };

  late final List<String> _heads = [
    for (final c in classes) _stems(c.name).first,
  ];

  FoodVoiceMatcher(this.classes);

  /// Everyday words for foods whose catalog name differs; generic words point to the usual choice.
  static const aliases = {
    'couve': 'couve',
    'bolacha de água e sal': 'cream_cracker',
    'biscoito de água e sal': 'cream_cracker',
    'pãozinho': 'pao_frances',
    'pão de sal': 'pao_frances',
    'cacetinho': 'pao_frances',
    'refri': 'refrigerante',
    'coca': 'refrigerante',
    'coca cola': 'refrigerante',
    'cafezinho': 'cafe',
    'pingado': 'cafe_com_leite',
    'batata': 'batata_cozida',
    'fritas': 'batata_frita',
    'salada': 'salada_verde',
    'carne': 'bife',
    'peito de frango': 'frango_grelhado',
    'ovo': 'ovo_cozido',
    'macaxeira': 'mandioca_cozida',
    'aipim': 'mandioca_cozida',
    'mandioca': 'mandioca_cozida',
    'tangerina': 'mexerica',
    'bergamota': 'mexerica',
    'iogurte natural': 'iogurte',
    'queijo branco': 'queijo_minas',
    'muçarela': 'mussarela',
    'x burguer': 'hamburguer_lanche',
    'hambúrguer': 'hamburguer_lanche',
    'cachorro quente': 'cachorro_quente',
    'suco': 'suco_fruta',
    'vitamina de banana': 'vitamina',
    'feijão': 'feijao_carioca',
    'arroz': 'arroz_branco',
    'frango': 'frango_grelhado',
    'peixe': 'peixe_grelhado',
    'queijo': 'queijo_minas',
    'pão': 'pao_frances',
    'biscoito': 'cream_cracker',
    'bolacha': 'cream_cracker',
    'bolacha recheada': 'biscoito_recheado',
    'bolo': 'bolo_simples',
    'leite com café': 'cafe_com_leite',
  };

  /// Quantities, measures and filler words are dropped; separators split foods.
  static const _filler = {
    'um',
    'uma',
    'uns',
    'umas',
    'dois',
    'duas',
    'tres',
    'quatro',
    'cinco',
    'seis',
    'sete',
    'oito',
    'nove',
    'dez',
    'meio',
    'meia',
    'metade',
    'de',
    'do',
    'da',
    'dos',
    'das',
    'no',
    'na',
    'nos',
    'nas',
    'o',
    'a',
    'os',
    'as',
    'eu',
    'comi',
    'tomei',
    'bebi',
    'almocei',
    'jantei',
    'lanchei',
    'hoje',
    'agora',
    'prato',
    'colher',
    'copo',
    'xicara',
    'fatia',
    'pedaco',
    'porcao',
    'concha',
    'unidade',
    'grama',
    'g',
    'ml',
    'litro',
    'pouco',
    'bastante',
    'lata',
    'garrafa',
    'tigela',
    'pote',
    'inteiro',
    'inteira',
    'pequeno',
    'pequena',
    'grande',
    'medio',
    'media',
    'cheio',
    'cheia',
    'raso',
    'rasa',
    'almoco',
    'jantar',
    'janta',
    'lanche',
    'tambem',
    'so',
    'sobremesa',
    'mais',
    'e',
    'com',
    'depois',
    'ai',
    'tipo',
    'manha',
  };

  /// Measures whose last word is also a food ("colher de sopa", "colher de chá").
  static final _measures = RegExp(
    r'\b(colher(es)?|colherzinha) (de|da) (sopa|cha|sobremesa)\b|\bcafe da manha\b',
  );

  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final out = StringBuffer();
    for (final ch in text.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      out.write(i < 0 ? ch : to[i]);
    }
    return out
        .toString()
        .replaceAll(RegExp(r'[-_/]'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9,;. ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Plural and gender noise removed so "ovos fritos" meets "Ovo frito".
  static String _stem(String word) {
    if (word.length > 4 && word.endsWith('oes')) {
      return '${word.substring(0, word.length - 3)}ao';
    }
    if (word.length > 4 && word.endsWith('aes')) {
      return '${word.substring(0, word.length - 3)}ao';
    }
    if (word.length > 4 && word.endsWith('eis')) {
      return '${word.substring(0, word.length - 3)}el';
    }
    if (word.length > 4 && word.endsWith('ais')) {
      return '${word.substring(0, word.length - 3)}al';
    }
    if (word.length > 3 && word.endsWith('s')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static List<String> _stems(String text) =>
      normalize(text).split(' ').where((w) => w.isNotEmpty).map(_stem).toList();

  List<FoodVoiceItem> match(String sentence, {int alternatives = 3}) {
    final text = normalize(sentence).replaceAll(_measures, ' ');
    final words = text
        .replaceAll(RegExp(r'[,;.]'), ' , ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final stems = words.map(_stem).toList();
    final items = <FoodVoiceItem>[];
    final unknown = <String>[];
    void flushUnknown() {
      final heard = unknown
          .where((w) => !_filler.contains(w) && !_filler.contains(_stem(w)))
          .join(' ');
      if (heard.isNotEmpty && !RegExp(r'^\d+$').hasMatch(heard)) {
        items.add(FoodVoiceItem(heard, const []));
      }
      unknown.clear();
    }

    // Words right after a food that match nothing describe it ("bife acebolado").
    var attach = false;
    var i = 0;
    while (i < words.length) {
      if (words[i] == ',') {
        flushUnknown();
        attach = false;
        i++;
        continue;
      }
      final hit = _longest(stems, i);
      if (hit == null) {
        if ((_filler.contains(words[i]) || _filler.contains(stems[i])) ||
            RegExp(r'^\d+$').hasMatch(words[i])) {
          flushUnknown();
          attach = false;
        } else if (attach) {
          final last = items.removeLast();
          items.add(
            FoodVoiceItem('${last.heard} ${words[i]}', last.candidates),
          );
        } else {
          unknown.add(words[i]);
        }
        i++;
        continue;
      }
      flushUnknown();
      attach = true;
      final (length, index) = hit;
      items.add(
        FoodVoiceItem(words.sublist(i, i + length).join(' '), [
          classes[index],
          ..._related(index, alternatives - 1),
        ]),
      );
      i += length;
    }
    flushUnknown();
    return items;
  }

  /// Longest known name starting at [start]: (words used, class index).
  (int, int)? _longest(List<String> stems, int start) {
    for (final (name, index) in _names) {
      if (start + name.length > stems.length) continue;
      var same = true;
      for (var k = 0; k < name.length && same; k++) {
        same = stems[start + k] == name[k];
      }
      if (same) return (name.length, index);
    }
    // A single word that starts known names ("cuscuz", "couve") means the first of them.
    for (var j = 0; j < classes.length; j++) {
      if (_heads[j] == stems[start]) return (1, j);
    }
    return null;
  }

  /// Other foods that share the first word ("Feijão carioca" → "Feijão preto", ...).
  Iterable<FoodPhotoClass> _related(int index, int count) {
    final head = _heads[index];
    return [
      for (var j = 0; j < classes.length; j++)
        if (j != index && _heads[j] == head) classes[j],
    ].take(count);
  }
}

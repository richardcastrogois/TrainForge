import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/food_reference/data/food_photo_classifier.dart';
import 'package:trainforge/features/food_reference/data/food_voice_matcher.dart';

/// Spoken sentences → foods expected as the first suggestion, in order.
const _phrases = <String, List<String>>{
  'arroz, feijão e bife': ['arroz_branco', 'feijao_carioca', 'bife'],
  'comi arroz com feijão e um ovo frito': [
    'arroz_branco',
    'feijao_carioca',
    'ovo_frito',
  ],
  'dois ovos fritos': ['ovo_frito'],
  'um copo de suco de laranja': ['suco_laranja'],
  'café com leite e pão com manteiga': [
    'cafe_com_leite',
    'pao_frances',
    'manteiga',
  ],
  'no café da manhã comi pão de queijo e café': ['pao_de_queijo', 'cafe'],
  'uma banana e uma maçã': ['banana', 'maca'],
  'duas fatias de pão integral com requeijão': ['pao_integral', 'requeijao'],
  'salada, frango grelhado e batata doce': [
    'salada_verde',
    'frango_grelhado',
    'batata_doce',
  ],
  'macarrão à bolonhesa': ['macarrao_bolonhesa'],
  'lasanha e refrigerante': ['lasanha', 'refrigerante'],
  'feijoada com farofa e couve': ['feijoada', 'farofa', 'couve'],
  'um prato de arroz integral com lentilha': ['arroz_integral', 'lentilha'],
  'tapioca com queijo coalho': ['tapioca', 'queijo_coalho'],
  'iogurte com granola e mel': ['iogurte', 'granola', 'mel'],
  'uma xícara de café': ['cafe'],
  'chá de camomila': ['cha'],
  'uma colher de sopa de azeite na salada': ['azeite', 'salada_verde'],
  'sopa de legumes': ['sopa'],
  'pastéis de carne': ['pastel'],
  'uma coxinha e um guaraná': ['coxinha', 'guarana'],
  'pizza': ['pizza'],
  'hambúrguer com batata frita': ['hamburguer_lanche', 'batata_frita'],
  'cuscuz com ovo': ['cuscuz_milho', 'ovo_cozido'],
  'açaí na tigela com banana': ['acai', 'banana'],
  'peixe frito, arroz e salada de tomate': [
    'peixe_frito',
    'arroz_branco',
    'salada_tomate',
  ],
  'estrogonofe de frango com arroz e batata palha': [
    'estrogonofe_frango',
    'arroz_branco',
    'batata_palha',
  ],
  'carne moída com purê de batata': ['carne_moida', 'pure_batata'],
  'mandioca frita': ['mandioca_frita'],
  'aipim cozido': ['mandioca_cozida'],
  'macaxeira com carne seca': ['mandioca_cozida', 'carne_seca'],
  'um pãozinho com mortadela': ['pao_frances', 'mortadela'],
  'misto quente e suco de uva': ['misto_quente', 'suco_fruta'],
  'brigadeiro': ['brigadeiro'],
  'um pedaço de bolo de cenoura': ['bolo_cenoura'],
  'sorvete de chocolate': ['sorvete'],
  'pudim': ['pudim'],
  'mamão com aveia': ['mamao', 'aveia'],
  'três biscoitos recheados': ['biscoito_recheado'],
  'bolacha de água e sal': ['cream_cracker'],
  'uma tangerina': ['mexerica'],
  'melancia e melão': ['melancia', 'melao'],
  'abacate com açúcar': ['abacate'],
  'vitamina de banana': ['vitamina'],
  'água de coco': ['agua_coco'],
  'uma cerveja': ['cerveja'],
  'caldo verde': ['caldo_verde'],
  'canja de galinha': ['canja'],
  'sushi e temaki': ['sushi', 'temaki'],
  'yakisoba': ['yakisoba'],
  'escondidinho de carne seca': ['escondidinho', 'carne_seca'],
  'baião de dois': ['baiao_de_dois'],
  'feijão tropeiro e linguiça': ['feijao_tropeiro', 'linguica'],
  'churrasco com vinagrete e farofa': ['churrasco', 'farofa'],
  'picanha e mandioca': ['picanha', 'mandioca_cozida'],
  'moqueca de peixe com pirão': ['moqueca', 'peixe_grelhado'],
  'omelete de queijo': ['omelete', 'queijo_minas'],
  'ovos mexidos com torrada': ['ovo_mexido', 'torrada'],
  'leite com achocolatado': ['leite', 'achocolatado'],
  'cappuccino e um croissant': ['cappuccino', 'croissant'],
  'paçoca': ['pacoca'],
  'uma porção de batatas fritas': ['batata_frita'],
  'brócolis e cenoura cozida': ['brocolis', 'cenoura'],
  'feijão preto com arroz': ['feijao_preto', 'arroz_branco'],
  'peito de frango grelhado com legumes no vapor': [
    'frango_grelhado',
    'legumes_vapor',
  ],
};

void main() {
  final data = jsonDecode(
    File('assets/models/food_photo_classes.json').readAsStringSync(),
  );
  final classes = [
    for (final c in data['classes'] as List)
      FoodPhotoClass(
        slug: c['slug'] as String,
        name: c['name'] as String,
        foodId: c['foodId'] as String,
        versionId: c['versionId'] as String,
      ),
  ];
  final matcher = FoodVoiceMatcher(classes);

  test('every expected slug and alias target exists in the class list', () {
    final slugs = classes.map((c) => c.slug).toSet();
    for (final target in FoodVoiceMatcher.aliases.values) {
      expect(slugs, contains(target));
    }
    for (final want in _phrases.values.expand((v) => v)) {
      expect(slugs, contains(want));
    }
  });

  test('spoken sentences find the expected foods first (≥ 95%)', () {
    var expected = 0, found = 0, extra = 0;
    final misses = <String>[];
    for (final entry in _phrases.entries) {
      final firsts = [
        for (final item in matcher.match(entry.key))
          if (item.candidates.isNotEmpty) item.candidates.first.slug,
      ];
      for (final want in entry.value) {
        expected++;
        if (firsts.contains(want)) {
          found++;
        } else {
          misses.add('${entry.key} → falta $want (veio $firsts)');
        }
      }
      extra += firsts.where((s) => !entry.value.contains(s)).length;
    }
    final rate = found / expected;
    // ignore: avoid_print
    print(
      'voz → alimento: $found/$expected (${(rate * 100).toStringAsFixed(1)}%), extras $extra\n${misses.join('\n')}',
    );
    expect(rate, greaterThanOrEqualTo(0.95));
  });

  test('multi-word names stay whole and quantities are ignored', () {
    final items = matcher.match(
      'dois copos de café com leite e meia colher de sopa de açúcar',
    );
    expect(items.first.candidates.first.slug, 'cafe_com_leite');
    expect(items.first.heard, 'cafe com leite');
  });

  test('unknown words become a search item instead of a guess', () {
    final items = matcher.match('arroz e quinoto');
    expect(items.map((i) => i.heard), ['arroz', 'quinoto']);
    expect(items.last.candidates, isEmpty);
  });

  test('a generic word offers related foods as alternatives', () {
    final item = matcher.match('feijão').single;
    expect(item.candidates.first.slug, 'feijao_carioca');
    expect(item.candidates.map((c) => c.slug), contains('feijao_preto'));
  });
}

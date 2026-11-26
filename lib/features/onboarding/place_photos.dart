/// Banner photos per place, chosen by the author (credits in
/// docs/conteudo/banners-creditos.md). File names carry who appears:
/// "mulher", "homem" or neither (general).
const _placePhotos = <String, List<String>>{
  'casa': [
    'casa-mulher',
    'casa-homem-7',
    'casa-geral-5',
    'casa-mulher-2',
    'casa-geral-halteres',
    'casa-mulher-halteres',
  ],
  'praca': [
    'praca-geral',
    'praca-mulher-4',
    'praca-homem-4',
    'praca-mulher',
    'praca-homem-5',
    'praca-mulher-2',
    'praca-homem',
    'praca-mulher-3',
    'praca-homem-2',
    'praca-mulher-5',
    'praca-homem-3',
  ],
  'academia': [
    'academia-geral-2',
    'academia-mulher-1',
    'academia-homem',
    'academia-geral',
    'academia-mulher',
    'academia-homem-1',
    'academia-geral-3',
    'academia-mulher-3',
    'academia-geral-4',
    'academia-mulher-2',
  ],
  'pausa': ['pausa', 'pausa-mulher', 'pausa-homem', 'pausa-homem-2'],
};

/// Photos for [place]: with a stated gender, that gender's photos come first
/// and the other gender's are left out; otherwise every photo, in a mixed order.
List<String> placePhotos(String place, [String? gender]) {
  final all = _placePhotos[place] ?? const <String>[];
  final own = switch (gender) {
    'woman' => 'mulher',
    'man' => 'homem',
    _ => null,
  };
  Iterable<String> names = all;
  if (own != null) {
    final other = own == 'mulher' ? 'homem' : 'mulher';
    names = [
      ...all.where((n) => n.contains(own)),
      ...all.where((n) => !n.contains(own) && !n.contains(other)),
    ];
  }
  return [for (final n in names) 'assets/banners/$n.webp'];
}

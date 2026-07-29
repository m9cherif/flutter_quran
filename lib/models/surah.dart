class Surah {
  final int numSoura;
  final String soura;
  final int numPage;
  final int nbrAya;

  const Surah({
    required this.numSoura,
    required this.soura,
    required this.numPage,
    required this.nbrAya,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    numSoura: json['num_soura'] as int,
    soura: json['soura'] as String,
    numPage: json['num_page'] as int,
    nbrAya: json['nbr_aya'] as int,
  );

  Map<String, dynamic> toJson() => {
    'num_soura': numSoura,
    'soura': soura,
    'num_page': numPage,
    'nbr_aya': nbrAya,
  };
}

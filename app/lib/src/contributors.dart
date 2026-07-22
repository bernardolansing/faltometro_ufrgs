class Contributor {
  final String name;
  final String bond;
  final String role;
  final String instagramNickname;

  const Contributor({
    required this.name,
    required this.bond,
    required this.role,
    required this.instagramNickname,
  });

  /// Returns an URI for the contributor's Instagram profile.
  Uri get instagramUri => Uri.https('instagram.com', instagramNickname);
}

const contributors = [
  Contributor(
      name: 'Bernardo Lansing',
      bond: 'Estudante de engenharia de computação',
      role: 'Criador e responsável pelo projeto',
      instagramNickname: 'bernardolansing',
  ),

  Contributor(
    name: 'Faísca Design Júnior',
    bond: 'Empresa júnior do curso de design da UFRGS',
    role: 'Criação do ícone e demais artes',
    instagramNickname: 'faiscadesignjr',
  ),
];

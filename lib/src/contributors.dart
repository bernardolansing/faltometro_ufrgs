class Contributor {
  final String name;
  final String bond;
  final String role;
  final String? instagramNickname;
  final String? telegramNickname;

  /// Constructs a Contributor class.
  ///
  /// Provide the contributor complete [name] with proper case and its [bond]
  /// with the university. The [bond] should start with a upper case letter.
  /// You may also provide a [instagramNickname] and a [telegramNickname], but
  /// be aware that those will break if the contributor decides to change its
  /// nickname.
  const Contributor({
    required this.name,
    required this.bond,
    required this.role,
    this.instagramNickname,
    this.telegramNickname
  });

  bool get instagramAvailable => instagramNickname != null;

  bool get telegramAvailable => telegramNickname != null;

  /// Returns an URI for the contributor's Instagram profile. Do not call if
  /// [instagramNickname] is null.
  Uri get instagramUri {
    assert (instagramNickname != null);
    return Uri.https('instagram.com', instagramNickname!);
  }

  /// Returns an URI for the contributor's Telegram profile. Do not call if
  /// [telegramNickname] is null.
  Uri get telegramUri {
    assert (telegramNickname != null);
    return Uri.https('t.me', telegramNickname!);
  }
}

const contributors = [
  Contributor(
      name: 'Bernardo Lansing',
      bond: 'Estudante de engenharia de computação',
      role: 'Criador e responsável pelo projeto',
      instagramNickname: 'bernardolansing',
      telegramNickname: 'bernardolansing'
  ),

  Contributor(
    name: 'Faísca Design Júnior',
    bond: 'Empresa júnior do curso de design da UFRGS',
    role: 'Criação do ícone e demais artes',
    instagramNickname: 'faiscadesignjr',
  ),
];

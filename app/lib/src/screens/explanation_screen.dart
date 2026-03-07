import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../contributors.dart';

class ExplanationScreen extends StatelessWidget {
  final ScrollController _scrollController;

  ExplanationScreen({super.key}) :
        _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sobre o Faltômetro'),
      leading: IconButton(
        onPressed: Navigator.of(context).pop,
        icon: PhosphorIcon(PhosphorIcons.bold.arrowLeft),
      ),
    ),
    body: SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true, // Makes the scrollbar always visible (making
        // sure the user realizes that this screen is scrollable).
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          controller: _scrollController,
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true, // Needed as it is a child of a
                // SingleChildScrollView.
                physics: const NeverScrollableScrollPhysics(), // Disables the
                // scrolling effect.
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemCount: _paragraphs.length,
                itemBuilder: (context, index) => Text(
                  _paragraphs[index],
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),

              const Divider(thickness: 2, height: 48),

              const Text('Contribuidores:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),

              Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: contributors
                    .map((contributor) => _ContributorWidget(contributor))
                    .toList(growable: false),
              ),

              const SizedBox(height: 24),

              const Text(_bottomText, textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: () => launchUrl(
                  _repositoryUrl,
                  mode: LaunchMode.externalApplication,
                ),
                icon: PhosphorIcon(PhosphorIcons.regular.githubLogo),
                label: const Text(
                  'Faltômetro UFRGS no GitHub',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ContributorWidget extends StatelessWidget {
  final Contributor _contributor;

  const _ContributorWidget(this._contributor);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        _contributor.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(_contributor.bond),
      Text(_contributor.role),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_contributor.instagramAvailable)
            IconButton.outlined(
              onPressed: () => launchUrl(_contributor.instagramUri),
              icon: PhosphorIcon(PhosphorIcons.light.instagramLogo),
            )
          else
            Container(),

          if (_contributor.telegramAvailable)
            IconButton.outlined(
              onPressed: () => launchUrl(_contributor.telegramUri),
              icon: PhosphorIcon(PhosphorIcons.light.telegramLogo),
            )
          else
            Container()
        ],
      )
    ],
  );
}

const _paragraphs = [
  'O Faltômetro UFRGS é um aplicativo extraoficial criado com o intuito de '
      'facilitar ao estudante o seu controle de faltas. A promessa é que ele '
      'ajude a evitar o conceito FF por desatenção. É importante deixar claro '
      'que o Faltômetro NÃO endossa a prática de faltar aulas. O aplicativo '
      'se propõe meramente a auxiliar a organização do aluno.',

  'A UFRGS exige uma frequência mínima de 75% nas suas aulas, para qualquer '
      'disciplina. No entanto, cada disciplina tem uma quantidade diferente '
      'de aulas, mesmo entre disciplinas com o mesmo número de créditos. O '
      'Faltômetro calculará sua frequência baseando-se na duração em semanas '
      'especificada para cada disciplina. Geralmente, as elas têm 15 semanas '
      'de aula. Esteja ciente de que a porcentagem de faltas queimadas é uma '
      'ESTIMATIVA (precisa, mas não exata).',

  'É deixada a recomendação de não ultrapassar os 80% da cota de faltas. Para '
      'além desse valor, você já não está mais garantido.'
];

const _bottomText = 'Bugs? Sugestões? Dúvidas? Todas bem-vindas, basta enviar '
    'uma mensagem. O Faltômetro UFRGS é um projeto de código-livre, consulte '
    'o repositório:';

final _repositoryUrl = Uri
    .https('github.com', 'bernardolansing/faltometro_ufrgs');

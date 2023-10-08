import 'package:faltometro_ufrgs/src/contributors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Faltômetro'),
        leading: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: PhosphorIcon(PhosphorIcons.bold.arrowLeft)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true, // Needed as it is a child of a
              // SingleChildScrollView.
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemCount: _paragraphs.length,
              itemBuilder: (context, index) => Text(
                _paragraphs[index],
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),

            const Divider(thickness: 2, height: 48),

            const Text('Contribuidores:', style: TextStyle(fontSize: 18),),
            const SizedBox(height: 12),

            ...contributors
                .map((contributor) => _buildContributor(context, contributor))
                .toList(growable: false),

            const SizedBox(height: 24),

            const Text(_contributionIsWelcomeText, textAlign: TextAlign.center)
          ],
        ),
      )
  );

  Widget _buildContributor(BuildContext context, Contributor contributor) =>
      Column(
        children: [
          Text(
              contributor.name,
              style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          Text(contributor.bond),
          Text(contributor.role),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contributor.instagramAvailable)
                IconButton.outlined(
                    onPressed: () => launchUrl(contributor.instagramUri),
                    icon: PhosphorIcon(PhosphorIcons.light.instagramLogo)
                )
              else
                Container(),

              if (contributor.telegramAvailable)
                IconButton.outlined(
                    onPressed: () => launchUrl(contributor.telegramUri),
                    icon: PhosphorIcon(PhosphorIcons.light.telegramLogo)
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
      'Faltômetro calculará sua frequência baseando-se no palpite de que a '
      'disciplina terá exatamente 15 semanas de duração. Algumas costumam ter '
      'menos.',

  'Por essa razão, é deixada a recomendação de não ultrapassar os 80% sob '
      'nenhuma hipótese. Acima deste limite, não há garantia nenhuma de que '
      'você já não tenha obtido o conceito FF.'
];

const _contributionIsWelcomeText = 'Você é bem-vindo para contribuir! '
    'Atualmente o projeto poderia se valer de um designer para elaborar '
    'algumas decorações para o app. Desenvolvedores que desejarem melhorar '
    'as funcionalidades também podem fazê-lo. Sugestões, críticas e '
    'relatórios de bugs são muito valorizados; basta mandar uma mensagem.';

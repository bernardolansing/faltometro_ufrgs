# Faltômetro UFRGS
Aplicativo mobile para os estudantes da UFRGS controlarem suas frequências nas aulas. Foi testado
apenas em dispositivos Android, e há planos para publicá-lo na Play Store em breve. Por enquanto,
se você quiser obter o app você pode compilá-lo por conta própria (ver
[aspectos técnicos](#aspectos-técnicos)) ou pedir para eu te enviá-lo (ver [contato](#contato)).

### Funcionalidades
- Você pode adicionar suas disciplinas e registrar suas faltas nela. O aplicativo calculará quantas
faltas você já consumiu.
- Você pode editar as cadeiras, alterando seu nome e número de períodos por dia da semana.

### Funcionalidades planejadas
- URGENTE: ter um ícone para o app :)...
- Backup em nuvem em contas de usuário para evitar perda de dados quando o app for reinstalado ou
você trocar de dispositivo.
- Banco de dados de disciplinas com seus horários. Com isso, não será necessário que você preencha
manualmente o número de períodos por dia da semana para cada disciplina, e você terá uma maneira
prática de consultar os horários das suas aulas.
- Notificações do aplicativo para te lembrar de registrar suas faltas.

### Contato
Se você tiver qualquer sugestão ou crítica, ou quiser reportar um bug ou quiser contribuir com o
projeto, sinta-se livre para me mandar uma mensagem no meu [Telegram](https://t.me/bernardolansing)
ou [Instagram](https://instagram.com/bernardolansing), ou
[postar uma issue](https://github.com/bernardolansing/faltometro_ufrgs/issues) no repositório
GitHub.

### Aspectos técnicos
Este aplicativo foi desenvolvido com [Flutter](https://flutter.dev/), um framework para a linguagem
de programação Dart. O Flutter é capaz de gerar aplicações para diversas plataformas com o mesmo
código-base. Para aqueles que não estão familiarizados com a estrutura dos projetos Dart/Flutter,
o código-fonte propriamente dito está na pasta `lib/src`.

O app deve funcionar em qualquer dispositivo com Android 5.0+ (Lollipop ou mais recente). Se você
estiver enfrentando problemas para rodá-lo no seu dispositivo, por favor me comunique como
instruído na sessão de [contato](#contato).

Para compilar o aplicativo para Android, você deve executar `flutter build apk --release
--no-tree-shake-icons`.

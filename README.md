# Faltômetro UFRGS

_Você pode ler este texto em português [clicando aqui](README_PTBR.md)._

Mobile app for UFRGS students to control their attendance in classes. The app is only targeted for
Android devices and is available at Play Store. There are plans for releasing a web version so that
iOS or even PC users can use it too. Due to the high costs for publishing in the AppStore, it is
unlikely that an iOS native port will ever be offered.

[Download it at Play Store](
https://play.google.com/store/apps/details?id=com.bernardolansing.faltometro_ufrgs)

### Features
- You can add your courses and register absences. The app will calculate how much of the absences
you've already consumed.
- You can edit courses, changing their name or amount of periods per week day.
- You can opt for receiving notifications to remember you of registering your absences. You can
choose between receiving one notification a week (on Fridays nights), every day you have classes
(at night as well) or not receiving them at all.
- Dark theme.
- You can write down you University Restaurant ticket at the home screen, so you won't forget it.

### Planned features
- Cloud backup in user accounts in order to avoid data deletion when the app is reinstalled or you
switch your device.
- Database of courses with their schedules. With this, it won't be necessary for you to manually
fill how many periods each course has per weekday, and you will have a practical way to check your 
class schedules.
- Registering exams dates.

### Contact
If you have any suggestion or complaint, want to report a bug or if you wish to contribute with the
project, feel free to send me a message in my [Telegram](https://t.me/bernardolansing) or 
[Instagram](https://instagram.com/bernardolansing), or 
[post an issue](https://github.com/bernardolansing/faltometro_ufrgs/issues) in the GitHub
repository.

### Technical overview
This application was developed with [Flutter](https://flutter.dev/), a framework for the Dart
programming language. Flutter is capable of generating applications for several platforms with the
same code base. For those unfamiliar with Dart/Flutter project structure, the actual source code is
in `lib/src` folder.

The app is supposed to work on any 5.0+ (Lollipop or newer) Android device. If you are having
trouble running it on your Android device, please text me as instructed in [contact](#contact)
session.

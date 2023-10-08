
# Faltômetro UFRGS

_Você pode ler este texto em português [clicando aqui](README_PTBR.md)._

Mobile app for UFRGS students to control their classes attendances. It has only been tested on
Android devices, and there are plans for it to be published in Play Store soon. For now, if you
want to get the app you can build it yourself (see [technical overview](#technical-overview)) or
ask me to send it to you (see [contact](#contact)).

### Features
- You can add your courses and register absences. The app will calculate how much of the absences
you've already consumed.
- You can edit courses, changing their name or amount of periods per week day.

### Planned features
- URGENT: to have an app icon :)...
- Cloud backup in user accounts in order to avoid data deletion when the app is reinstalled or you
switch your device.
- Database of courses with their schedules. With this, it won't be necessary for you to manually
fill how many periods each course has per weekday, and you will have a practical way to check your 
class schedules.
- App notifications to remember you of registering your absences.

### Contact
If you have any suggestion or critic, want to report a bug or if you wish to contribute with the
project, feel free to send me a message in my [Telegram](https://t.me/bernardolansing) or 
[Instagram](https://instagram.com/bernardolansing), or 
[post an issue](https://github.com/bernardolansing/faltometro_ufrgs/issues) in the GitHub
repository.

### Technical overview
This application was developed with [Flutter](https://flutter.dev/), a framework for the Dart
programming language. Flutter is capable of generating applications for several platforms with the
same code base. For those unfamiliar with Dart/Flutter project structure, the actual source code is
in `lib/src` folder.

The app is supposed to work on any 5.0+ (Lollipop or more recent) Android device. If you are having
trouble running it on your Android device, please text me as instructed in [contact](#contact)
session.

In order to build the application for Android, you have to run `flutter build apk --release
--no-tree-shake-icons`.

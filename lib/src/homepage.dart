import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
        leading: PhosphorIcon(PhosphorIcons.bold.flame),
        title: const Text('Faltômetro UFRGS')
    ),
    body: SafeArea(
      child: Column(
        children: [],
      ),
    ),
  );
}

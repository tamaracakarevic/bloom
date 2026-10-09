import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models.dart';
import 'screens/home.dart';
import 'screens/measurements.dart';
import 'screens/onboarding.dart';
import 'screens/profile.dart';
import 'screens/progress.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Reminders.init();
  final state = await AppState.load();
  runApp(AppScope(state: state, child: const BloomApp()));
}

const _serbianLatin =
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom',
      debugShowCheckedModeBanner: false,
      theme: bloomTheme(),
      locale: _serbianLatin,
      supportedLocales: const [_serbianLatin, Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final hasProfile = AppScope.of(context).data.profile != null;
    return hasProfile ? const HomeShell() : const OnboardingScreen();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  int _today = today();
  late int _day = _today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => AppScope.of(context).syncSteps(_day));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) return;
    // ako je app ostao otvoren preko ponoći
    final now = today();
    if (now != _today) {
      setState(() {
        if (_day == _today) _day = now;
        _today = now;
      });
    }
    AppScope.of(context).syncSteps(_day);
  }

  void _changeDay(int day) {
    setState(() => _day = day);
    AppScope.of(context).syncSteps(day);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final body = switch (_tab) {
      0 => HomeScreen(
          day: _day,
          today: _today,
          onDayChange: _changeDay,
          onGoMeasure: () {
            setState(() => _tab = 1);
            openEntryEditor(context);
          },
        ),
      1 => const MeasurementsScreen(),
      2 => ProgressScreen(today: _today),
      _ => ProfileScreen(today: _today),
    };

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: body),
        // sadržaj se skroluje ispod statusne trake
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset,
          child: DecoratedBox(
            decoration: _tab == 0
                ? const BoxDecoration(gradient: headerGradient)
                : const BoxDecoration(color: BloomColors.background),
          ),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Danas'),
          NavigationDestination(
              icon: Icon(Icons.straighten_rounded), label: 'Merenja'),
          NavigationDestination(
              icon: Icon(Icons.insights_rounded), label: 'Napredak'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

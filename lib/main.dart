import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api_client.dart';
import 'data/http_repositories.dart';
import 'models/lost_found_model.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore(await SharedPreferences.getInstance());
  runApp(LostFoundRoot(tokens: tokens));
}

class LostFoundRoot extends StatefulWidget {
  const LostFoundRoot({super.key, required this.tokens});
  final TokenStore tokens;
  @override
  State<LostFoundRoot> createState() => _LostFoundRootState();
}

class _LostFoundRootState extends State<LostFoundRoot> {
  late final ApiClient api;
  late final AuthApi auth;
  late final GoRouter navigation;
  int session = 0;
  @override
  void initState() {
    super.initState();
    navigation = createRouter(
      initialLocation: widget.tokens.token == null ? '/login' : '/items',
      isAuthenticated: () => widget.tokens.token != null,
    );
    api = ApiClient(
      widget.tokens,
      onUnauthorized: () => changeSession('/login'),
    );
    auth = AuthApi(api, () => changeSession('/items'));
  }

  void changeSession(String route) {
    if (!mounted) return;
    setState(() => session++);
    navigation.go(route);
  }

  @override
  void dispose() {
    api.close();
    navigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: api),
      Provider.value(value: auth),
    ],
    child: ChangeNotifierProvider(
      key: ValueKey(session),
      create: (_) {
        final model = LostFoundModel(
          HttpItemRepository(api),
          HttpClaimRepository(api),
          HttpMessageRepository(api),
          serverPaging: true,
        );
        if (widget.tokens.token != null) model.load();
        return model;
      },
      child: LostFoundApp(routerConfig: navigation),
    ),
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
    ),
  );
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, this.routerConfig});
  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'LostFound',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: routerConfig ?? router,
  );
}

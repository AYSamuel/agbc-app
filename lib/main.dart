import 'package:agbc_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/providers/supabase_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_success_screen.dart';
import 'services/location_service.dart';
import 'services/permissions_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase with custom redirect URL
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authCallbackUrlHostname: 'agbcapp', // This matches the scheme in AndroidManifest.xml
    );

    // Initialize services
    final locationService = LocationService();
    final permissionsService = PermissionsService();
    final notificationService = NotificationService();
    final userService = UserService();
    final supabaseService = SupabaseService();
    final authService = AuthService(
      supabaseService: supabaseService,
      permissionsService: permissionsService,
    );

    // Initialize services in sequence
    await permissionsService.initialize();
    await locationService.initialize();
    await notificationService.initialize();
    await userService.initialize();
    await authService.initialize();

    // Configure system UI
    _configureSystemUI();

    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
  }
}

void _configureSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    // Handle incoming links when app is running
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error handling incoming links: $err');
    });

    // Handle links that opened the app
    getInitialUri().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path.contains('callback')) {
      // This is a Supabase auth callback
      final client = Supabase.instance.client;
      client.auth.getSessionFromUrl(uri).then((_) {
        // Navigate to success screen
        Navigator.of(context).pushReplacementNamed('/email-verification-success');
      }).catchError((error) {
        print('Error handling auth callback: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGBC App',
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email-verification-success': (context) => const EmailVerificationSuccessScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        // backgroundColor: const Color.fromARGB(255, 228, 231, 233),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

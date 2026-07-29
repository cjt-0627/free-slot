import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'services/calendar_availability_service.dart';
import 'views/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('zh_Hant_TW');
  await GoogleSignIn.instance.initialize();

  runApp(const FreeTimeApp());
}

class FreeTimeApp extends StatelessWidget {
  const FreeTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarAvailabilityService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FreeSlot',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            surface: Colors.black,
            onSurface: Colors.white,
            onSurfaceVariant: Colors.white70,
            primary: Colors.white,
            onPrimary: Colors.black,
            secondaryContainer: Color(0xFF2C2C2E),
            onSecondaryContainer: Colors.white,
            outline: Colors.white24,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

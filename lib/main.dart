import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'auth/auth_gate.dart';
import 'auth/user_provider.dart';
import 'staff/ui/staff_invite_link_listener.dart';
import 'theme/avoo_theme.dart';
import 'supabase/supabase_config.dart';
import 'sync/offline_sync_banner.dart';
import 'sync/offline_sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final offlineSyncController = await OfflineSyncController.create();
  runApp(AvooApp(offlineSyncController: offlineSyncController));
}

class AvooApp extends StatelessWidget {
  const AvooApp({super.key, required this.offlineSyncController});

  final OfflineSyncController offlineSyncController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<OfflineSyncController>(
          create: (_) => offlineSyncController,
        ),
      ],
      child: MaterialApp(
        title: 'Avoo',
        debugShowCheckedModeBanner: false,
        theme: AvooTheme.light,
        builder: (context, child) {
          return Stack(
            children: [if (child != null) child, const OfflineSyncBanner()],
          );
        },
        home: const StaffInviteLinkListener(child: AuthGate()),
      ),
    );
  }
}

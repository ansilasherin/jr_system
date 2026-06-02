import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/core/network/api_client.dart';
import 'src/core/network/api_config.dart';
import 'src/features/candidate/data/candidate_repository.dart';
import 'src/features/candidate/data/profile_repository.dart';
import 'src/features/candidate/data/profile_service.dart';
import 'src/features/candidate/presentation/view_models/auth_view_model.dart';
import 'src/features/candidate/presentation/view_models/applications_view_model.dart';
import 'src/features/candidate/presentation/view_models/dashboard_view_model.dart';
import 'src/features/candidate/presentation/view_models/hr_dashboard_view_model.dart';
import 'src/features/candidate/presentation/view_models/profile_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  final apiClient = ApiClient();
  await apiClient.loadSavedServerUrl();
  final repository = CandidateRepository(apiClient);
  final profileRepository = ProfileRepository(
    repository,
    const ProfileService(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repository),
        Provider.value(value: profileRepository),
        ChangeNotifierProvider(create: (_) => AuthViewModel(repository)),
        ChangeNotifierProvider(create: (_) => DashboardViewModel(repository)),
        ChangeNotifierProvider(
          create: (_) => ApplicationsViewModel(repository),
        ),
        ChangeNotifierProvider(create: (_) => HrDashboardViewModel(repository)),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(profileRepository),
        ),
      ],
      child: CandidatePortalApp(),
    ),
  );
}

// Web/Desktop: http://127.0.0.1:8000
// Physical phone: http://192.168.1.16:8000
// Android emulator: http://10.0.2.2:8000
// First working server കിട്ടിയാൽ app അത് save ചെയ്യും, പിന്നെ അതാണ് use ചെയ്യുക.

// Backend ഇങ്ങനെ run ചെയ്താൽ phone/emulator/desktop എല്ലാം connect ചെയ്യാൻ chance കൂടുതലാണ്:

// .\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
// Important: the backend must be accessible on your LAN IP for a real phone.
// If the phone cannot connect, start the server with 0.0.0.0 and allow port 8000 through firewall.
// Still IP മാറിയാൽ മാത്രം custom ആയി run ചെയ്യാം:

// flutter run --dart-define=API_LAN_URL=http://YOUR_PC_IP:8000
// Updated:

// api_config.dart
// api_client.dart
// candidate_repository.dart
// Verified:

// flutter analyze passed
// flutter test passed

// sneha123@gmail.com
// anu@gmail.com

//latest - python manage.py runserver 0.0.0.0:8000

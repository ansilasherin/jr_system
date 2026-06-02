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



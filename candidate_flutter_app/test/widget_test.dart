import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:candidate_flutter_app/src/app.dart';
import 'package:candidate_flutter_app/src/core/network/api_client.dart';
import 'package:candidate_flutter_app/src/features/candidate/data/candidate_repository.dart';
import 'package:candidate_flutter_app/src/features/candidate/presentation/view_models/applications_view_model.dart';
import 'package:candidate_flutter_app/src/features/candidate/presentation/view_models/auth_view_model.dart';
import 'package:candidate_flutter_app/src/features/candidate/presentation/view_models/dashboard_view_model.dart';
import 'package:candidate_flutter_app/src/features/candidate/presentation/view_models/hr_dashboard_view_model.dart';

void main() {
  testWidgets('shows candidate and HR login options', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final repository = CandidateRepository(ApiClient());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repository),
          ChangeNotifierProvider(create: (_) => AuthViewModel(repository)),
          ChangeNotifierProvider(create: (_) => DashboardViewModel(repository)),
          ChangeNotifierProvider(
            create: (_) => ApplicationsViewModel(repository),
          ),
          ChangeNotifierProvider(
            create: (_) => HrDashboardViewModel(repository),
          ),
        ],
        child: const CandidatePortalApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Candidate Login'), findsOneWidget);
    expect(find.text('Candidate'), findsOneWidget);
    expect(find.text('HR'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);

    await tester.tap(find.text('HR'));
    await tester.pump();

    expect(find.text('HR Login'), findsOneWidget);
    expect(find.text('Login as HR'), findsOneWidget);
  });
}

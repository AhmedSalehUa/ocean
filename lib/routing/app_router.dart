import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/assign/assign_assistant_screen.dart';
import '../features/assistant/assistant_home_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/handoff/handoff_screen.dart';
import '../features/finalize/finalize_screen.dart';
import '../features/guided_capture/guided_items_screen.dart';
import '../features/item_loop/item_loop_screen.dart';
import '../features/master_steps/master_steps_screen.dart';
import '../features/master_steps/step_items_screen.dart';
import '../features/master_steps/step_vendors_screen.dart';
import '../features/proofs/proof_viewer_screen.dart';
import '../features/proofs/proofs_screen.dart';
import '../features/shipment_capture/shipment_capture_screen.dart';
import '../features/step_done/step_done_screen.dart';
import '../features/vendor_detail/vendor_detail_screen.dart';
import '../features/vendor_list/vendor_list_screen.dart';
import 'routes.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: auth,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final signedIn = authProvider.isSignedIn;
      final isAssistant = authProvider.user?.isSubLogisticsOfficer ?? false;
      final loc = state.matchedLocation;
      final isLogin = loc == Routes.login;
      // The role's home: assistants get the tasks screen, reps the dashboard.
      final home = isAssistant ? Routes.assistantHome : Routes.dashboard;

      if (!signedIn && !isLogin) return Routes.login;
      if (signedIn && isLogin) return home;
      // Keep each role out of the other's home screen.
      if (signedIn && isAssistant && loc == Routes.dashboard) return Routes.assistantHome;
      if (signedIn && !isAssistant && loc == Routes.assistantHome) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: Routes.assistantHome,
        builder: (_, __) => const AssistantHomeScreen(),
      ),
      GoRoute(
        path: Routes.masterSteps,
        builder: (_, s) => MasterStepsScreen(masterId: s.pathParameters['masterId']!),
      ),
      GoRoute(
        path: Routes.stepVendors,
        builder: (_, s) => StepVendorsScreen(
          masterId: s.pathParameters['masterId']!,
          stepId: s.pathParameters['stepId']!,
        ),
      ),
      GoRoute(
        path: Routes.stepItems,
        builder: (_, s) => StepItemsScreen(
          vendorId: s.pathParameters['vendorId']!,
          stepId: s.pathParameters['stepId']!,
        ),
      ),
      GoRoute(
        path: Routes.vendorList,
        builder: (_, s) => VendorListScreen(masterId: s.pathParameters['masterId']!),
      ),
      GoRoute(
        path: Routes.vendorDetail,
        builder: (_, s) => VendorDetailScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.shipmentCapture,
        builder: (_, s) => ShipmentCaptureScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.itemLoop,
        builder: (_, s) => ItemLoopScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.guidedItems,
        builder: (_, s) =>
            GuidedItemsScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.proofs,
        builder: (_, s) => ProofsScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.proofViewer,
        builder: (_, s) => ProofViewerScreen(
          vendorId: s.pathParameters['vendorId']!,
          proofId: s.pathParameters['proofId']!,
        ),
      ),
      GoRoute(
        path: Routes.finalize,
        builder: (_, s) => FinalizeScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.handoff,
        builder: (_, s) => HandoffScreen(vendorId: s.pathParameters['vendorId']!),
      ),
      GoRoute(
        path: Routes.stepDone,
        builder: (_, s) => StepDoneScreen(
          vendorId: s.pathParameters['vendorId']!,
          completedStepId: s.pathParameters['stepId']!,
        ),
      ),
      GoRoute(
        path: Routes.assignAssistant,
        builder: (_, s) => AssignAssistantScreen(vendorId: s.pathParameters['vendorId']!),
      ),
    ],
  );
}

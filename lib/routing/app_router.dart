import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/handoff/handoff_screen.dart';
import '../features/finalize/finalize_screen.dart';
import '../features/guided_capture/guided_items_screen.dart';
import '../features/item_loop/item_loop_screen.dart';
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
      final signedIn = context.read<AuthProvider>().isSignedIn;
      final isLogin = state.matchedLocation == Routes.login;
      if (!signedIn && !isLogin) return Routes.login;
      if (signedIn && isLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.dashboard, builder: (_, __) => const DashboardScreen()),
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
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/screens/auth/auth_screen.dart';
import 'package:sentio_app/screens/auth/pending_approval_screen.dart';
import 'package:sentio_app/screens/onboarding/onboarding_screen.dart';
import 'package:sentio_app/screens/home/home_screen.dart';
import 'package:sentio_app/screens/checkin/checkin_screen.dart';
import 'package:sentio_app/screens/journal/journal_screen.dart';
import 'package:sentio_app/screens/journal/journal_entry_screen.dart';
import 'package:sentio_app/screens/chat/chat_screen.dart';
import 'package:sentio_app/screens/tools/tools_screen.dart';
import 'package:sentio_app/screens/tools/tool_detail_screen.dart';
import 'package:sentio_app/screens/tools/burnout_test_screen.dart';
import 'package:sentio_app/screens/content/article_screen.dart';
import 'package:sentio_app/screens/profile/profile_screen.dart';
import 'package:sentio_app/screens/crisis/crisis_screen.dart';
import 'package:sentio_app/screens/routines/routine_screen.dart';
import 'package:sentio_app/screens/progress/progress_screen.dart';
import 'package:sentio_app/screens/insights/insights_screen.dart';
import 'package:sentio_app/screens/community/community_feed_screen.dart';
import 'package:sentio_app/screens/community/post_detail_screen.dart';
import 'package:sentio_app/screens/community/community_profile_screen.dart';
import 'package:sentio_app/screens/community/story_viewer_screen.dart';
import 'package:sentio_app/screens/community/create_post_screen.dart';
import 'package:sentio_app/screens/community/create_story_screen.dart';
import 'package:sentio_app/screens/community/validation_screen.dart';
import 'package:sentio_app/screens/settings/notification_settings_screen.dart';
import 'package:sentio_app/screens/finance/finance_dashboard_screen.dart';
import 'package:sentio_app/screens/finance/finance_accounts_screen.dart';
import 'package:sentio_app/screens/finance/add_transaction_screen.dart';
import 'package:sentio_app/screens/finance/receipt_scan_screen.dart';
import 'package:sentio_app/screens/finance/finance_advisor_screen.dart';
import 'package:sentio_app/screens/legal/legal_screen.dart';
import 'package:sentio_app/screens/about/mateo_about_screen.dart';
import 'package:sentio_app/screens/materials/materials_screen.dart';
import 'package:sentio_app/screens/notifications/notifications_screen.dart';
import 'package:sentio_app/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AppProvider appProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: appProvider,
    redirect: (context, state) {
      final isAuthenticated = appProvider.isAuthenticated;
      final hasOnboarded = appProvider.hasCompletedOnboarding;
      final wizardSeen = appProvider.wizardSeen;
      final isApproved = appProvider.isApproved;
      final hasProfile = appProvider.profile != null;
      final currentPath = state.matchedLocation;

      // Always allow legal pages
      if (currentPath == '/legal/terms' || currentPath == '/legal/privacy') {
        return null;
      }

      if (!isAuthenticated) {
        // Show wizard first the very first time
        if (!wizardSeen) {
          if (currentPath == '/onboarding') return null;
          return '/onboarding';
        }
        if (currentPath == '/auth') return null;
        return '/auth';
      }

      if (hasProfile && !isApproved) {
        if (currentPath == '/pending-approval') return null;
        return '/pending-approval';
      }

      if (!hasOnboarded) {
        if (currentPath == '/onboarding') return null;
        return '/onboarding';
      }

      if (currentPath == '/auth' ||
          currentPath == '/onboarding' ||
          currentPath == '/pending-approval') {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Pending approval
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Crisis - accessible from anywhere
      GoRoute(
        path: '/crisis',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CrisisScreen(),
      ),
      // Journal entry screens - full screen
      GoRoute(
        path: '/journal/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JournalEntryScreen(),
      ),
      GoRoute(
        path: '/journal/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => JournalEntryScreen(
          entryId: state.pathParameters['id'],
        ),
      ),
      // Tools - full screen (moved from shell)
      GoRoute(
        path: '/tools',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ToolsScreen(),
      ),
      GoRoute(
        path: '/tool/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id == 'burnout_test') return const BurnoutTestScreen();
          return ToolDetailScreen(toolId: id);
        },
      ),
      // Check-in - full screen
      GoRoute(
        path: '/checkin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckinScreen(),
      ),
      // Insights - full screen
      GoRoute(
        path: '/insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InsightsScreen(),
      ),
      // Progress - full screen
      GoRoute(
        path: '/progress',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProgressScreen(),
      ),
      // Article detail - full screen
      GoRoute(
        path: '/article/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ArticleScreen(
          articleId: state.pathParameters['id']!,
        ),
      ),
      // Routine - full screen
      GoRoute(
        path: '/routine/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RoutineScreen(
          routineId: state.pathParameters['id']!,
        ),
      ),
      // Community - fullscreen routes
      GoRoute(
        path: '/community/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/community/user/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CommunityProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/community/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/community/story/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/community/validate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ValidationScreen(),
      ),
      GoRoute(
        path: '/community/story/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StoryViewerScreen(
          userId: state.pathParameters['userId'] ?? '',
        ),
      ),
      // Chat - full screen (accessible from home quick actions)
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/finance/accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinanceAccountsScreen(),
      ),
      GoRoute(
        path: '/finance/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddTransactionScreen(
          initialType: state.uri.queryParameters['type'] ?? 'expense',
          transactionId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/finance/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReceiptScanScreen(),
      ),
      GoRoute(
        path: '/finance/advisor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinanceAdvisorScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalScreen(type: LegalDocType.terms),
      ),
      GoRoute(
        path: '/legal/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalScreen(type: LegalDocType.privacy),
      ),
      GoRoute(
        path: '/about/mateo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MateoAboutScreen(),
      ),
      GoRoute(
        path: '/materials',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaterialsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // Main shell with bottom nav (5 tabs)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityFeedScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/screens/auth/auth_screen.dart';
import 'package:sentio_app/screens/onboarding/onboarding_screen.dart';
import 'package:sentio_app/screens/home/home_screen.dart';
import 'package:sentio_app/screens/checkin/checkin_screen.dart';
import 'package:sentio_app/screens/journal/journal_screen.dart';
import 'package:sentio_app/screens/journal/journal_entry_screen.dart';
import 'package:sentio_app/screens/chat/chat_screen.dart';
import 'package:sentio_app/screens/tools/tools_screen.dart';
import 'package:sentio_app/screens/tools/tool_detail_screen.dart';
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
import 'package:sentio_app/screens/settings/notification_settings_screen.dart';
import 'package:sentio_app/screens/finance/finance_dashboard_screen.dart';
import 'package:sentio_app/screens/finance/finance_accounts_screen.dart';
import 'package:sentio_app/screens/finance/add_transaction_screen.dart';
import 'package:sentio_app/screens/finance/receipt_scan_screen.dart';
import 'package:sentio_app/screens/finance/finance_advisor_screen.dart';
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
      final currentPath = state.matchedLocation;

      // TODO: Remove this bypass after testing community feature
      if (!isAuthenticated || !hasOnboarded) {
        if (currentPath == '/auth' || currentPath == '/onboarding') {
          return '/';
        }
        return null;
      }

      if (currentPath == '/auth' || currentPath == '/onboarding') {
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
        builder: (context, state) => ToolDetailScreen(
          toolId: state.pathParameters['id']!,
        ),
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
        path: '/community/story/:index',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StoryViewerScreen(
          initialIndex: int.tryParse(state.pathParameters['index'] ?? '0') ?? 0,
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

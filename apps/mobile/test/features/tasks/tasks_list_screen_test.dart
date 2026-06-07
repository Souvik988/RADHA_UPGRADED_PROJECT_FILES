import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/task_dto.dart';
import 'package:radha_mobile/features/tasks/task_detail_screen.dart';
import 'package:radha_mobile/features/tasks/tasks_list_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  group('TasksListScreen', () {
    testWidgets('Renders 3 filter tabs', (tester) async {
      when(
        () => mockApi.getTasks(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const PaginatedTasks(items: [], total: 0));

      await tester.pumpWidget(
        _buildApp(
          const TasksListScreen(),
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            currentUserProvider.overrideWithValue(
              const CurrentUser(userId: 'u1', tenantId: 't1', roles: ['staff']),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('FAB visible for manager role', (tester) async {
      when(
        () => mockApi.getTasks(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const PaginatedTasks(items: [], total: 0));

      await tester.pumpWidget(
        _buildApp(
          const TasksListScreen(),
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            currentUserProvider.overrideWithValue(
              const CurrentUser(
                userId: 'u1',
                tenantId: 't1',
                roles: ['manager'],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB hidden for staff role', (tester) async {
      when(
        () => mockApi.getTasks(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const PaginatedTasks(items: [], total: 0));

      await tester.pumpWidget(
        _buildApp(
          const TasksListScreen(),
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            currentUserProvider.overrideWithValue(
              const CurrentUser(userId: 'u1', tenantId: 't1', roles: ['staff']),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Detail screen shows Start button for pending task', (
      tester,
    ) async {
      when(() => mockApi.getTask('task-1')).thenAnswer(
        (_) async => const TaskResponse(
          id: 'task-1',
          title: 'Check expiry dates',
          description: 'Review all dairy products',
          type: 'expiry_check',
          priority: 'high',
          status: 'pending',
          assigneeName: 'Ravi',
          dueDate: '2025-03-01T00:00:00.000Z',
          requiresEvidence: false,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const TaskDetailScreen(taskId: 'task-1'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
    });
  });
}

import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/reviews/data/repositories/supabase_design_review_repository.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/workspace/data/repositories/supabase_workspace_repository.dart';
import 'package:engineering_werk/features/workspace/domain/entities/comment.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_test_helpers.dart';

void main() {
  late SupabaseClient admin;
  late SupabaseClient client;

  setUpAll(() async {
    await loadSupabaseTestEnv();
  });

  setUp(() async {
    if (!supabaseEnvFilesPresent()) return;
    requireLiveSupabase();
    admin = createAdminClient();
    client = await initAnonSupabase();
  });

  tearDown(() async {
    await signOutIfInitialized();
  });

  group('Supabase review flow', () {
    test(
      'create → read → update workspace → delete review graph',
      () async {
        requireLiveSupabase();

        final user = await createConfirmedUser(
          admin: admin,
          emailPrefix: 'review.flow',
        );
        addTearDown(() => deleteUser(admin, user.id));

        await client.auth.signInWithPassword(
          email: user.email,
          password: user.password,
        );

        final reviewRepo = SupabaseDesignReviewRepository(client);
        final workspaceRepo = SupabaseWorkspaceRepository(client);
        const uuid = Uuid();

        final now = DateTime.now().toUtc();
        final stages = getDefaultStages();
        final review = DesignReview(
          id: uuid.v4(),
          name: 'Integration Review',
          owner: 'Integration Tester',
          discipline: 'Systems',
          createdAt: now,
          lastUpdated: now,
          status: ProjectStatus.active,
          stages: stages,
          stakeholders: [
            Stakeholder(
              id: uuid.v4(),
              name: 'Alice',
              role: 'Engineer',
            ),
          ],
        );

        await reviewRepo.saveReview(review);

        final loaded = await reviewRepo.getReviewById(review.id);
        expect(loaded, isNotNull);
        expect(loaded!.name, 'Integration Review');
        expect(loaded.stakeholders.length, 1);
        expect(loaded.stakeholders.first.name, 'Alice');

        // Default stages should round-trip via sub_steps name matching.
        expect(loaded.stages, isNotEmpty);
        final firstWorkspaceId = loaded.stages.first.subSteps.first.workspaceId;

        final workspace = WorkspaceData(
          id: firstWorkspaceId,
          problemStatement: 'Validate pump housing clearance',
          notes: 'integration note',
          approvalStatus: ApprovalStatus.pending,
          checklistItem: loaded.stages.first.subSteps.first.name,
          comments: [
            Comment(
              id: uuid.v4(),
              author: 'Integration Tester',
              content: 'Looks good so far',
              createdAt: now,
            ),
          ],
        );
        await workspaceRepo.saveWorkspace(workspace);

        final loadedWorkspace =
            await workspaceRepo.getWorkspaceById(firstWorkspaceId);
        expect(loadedWorkspace, isNotNull);
        expect(loadedWorkspace!.problemStatement, contains('pump housing'));
        expect(loadedWorkspace.comments.length, 1);

        final all = await reviewRepo.getAllReviews();
        expect(all.any((r) => r.id == review.id), isTrue);

        await reviewRepo.deleteReview(review.id);
        expect(await reviewRepo.getReviewById(review.id), isNull);

        // Orphan workspace cleanup (deleteReview does not cascade to workspaces)
        await client.from('workspaces').delete().eq('id', firstWorkspaceId);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }, skip: !supabaseEnvFilesPresent()
      ? 'Live Supabase credentials not configured (.env / .env.admin)'
      : false);
}

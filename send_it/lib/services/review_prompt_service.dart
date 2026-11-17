import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'analytics_service.dart';

/// Asks for an App Store rating after a send that went well.
///
/// The native prompt is requested on the 2nd, 5th and 15th successful send,
/// but only when that batch reached at least [minSent] people with no
/// failures, and never in the same flow as a paywall. A milestone missed
/// because its batch didn't qualify carries over to the next good batch.
/// iOS still decides whether the prompt actually appears (at most 3 times a
/// year), so this only requests it.
class ReviewPromptService {
  ReviewPromptService._();

  static final ReviewPromptService instance = ReviewPromptService._();

  static const appStoreId = '6746167372';
  static const successfulSendsKey = 'review_successful_sends';
  static const lastPromptedMilestoneKey = 'review_last_prompted_milestone';

  static const milestones = [2, 5, 15];
  static const minSent = 3;

  /// The milestone to prompt for after this batch, or null for no prompt.
  /// [successfulSends] already includes this batch.
  @visibleForTesting
  static int? milestoneToPrompt({
    required int successfulSends,
    required int lastPromptedMilestone,
    required int sentCount,
    required int failedCount,
    required bool paywallShown,
  }) {
    if (paywallShown || sentCount < minSent || failedCount > 0) return null;
    final due = milestones
        .where((m) => m <= successfulSends && m > lastPromptedMilestone);
    return due.isEmpty ? null : due.last;
  }

  /// Call once per batch with at least one sent message, after the results
  /// sheet has closed.
  Future<void> onBatchCompleted({
    required int sentCount,
    required int failedCount,
    required bool paywallShown,
  }) async {
    if (sentCount == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final sends = (prefs.getInt(successfulSendsKey) ?? 0) + 1;
    await prefs.setInt(successfulSendsKey, sends);

    final milestone = milestoneToPrompt(
      successfulSends: sends,
      lastPromptedMilestone: prefs.getInt(lastPromptedMilestoneKey) ?? 0,
      sentCount: sentCount,
      failedCount: failedCount,
      paywallShown: paywallShown,
    );
    if (milestone == null) return;

    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    await prefs.setInt(lastPromptedMilestoneKey, milestone);
    AnalyticsService.instance.reviewPromptRequested(successfulSends: sends);
    await review.requestReview();
  }

  /// Opens the App Store's "Write a Review" page, from Settings.
  Future<void> openWriteReview() async {
    AnalyticsService.instance.reviewLinkOpened();
    await launchUrl(
      Uri.parse(
          'https://apps.apple.com/app/id$appStoreId?action=write-review'),
      mode: LaunchMode.externalApplication,
    );
  }
}

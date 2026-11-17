import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/review_prompt_service.dart';

void main() {
  int? decide({
    required int sends,
    int last = 0,
    int sent = 5,
    int failed = 0,
    bool paywall = false,
  }) =>
      ReviewPromptService.milestoneToPrompt(
        successfulSends: sends,
        lastPromptedMilestone: last,
        sentCount: sent,
        failedCount: failed,
        paywallShown: paywall,
      );

  group('ReviewPromptService.milestoneToPrompt', () {
    test('no prompt on the first send', () {
      expect(decide(sends: 1), isNull);
    });

    test('prompts on the 2nd, 5th and 15th good send', () {
      expect(decide(sends: 2), 2);
      expect(decide(sends: 5, last: 2), 5);
      expect(decide(sends: 15, last: 5), 15);
    });

    test('no prompt between milestones or after the last one', () {
      expect(decide(sends: 3, last: 2), isNull);
      expect(decide(sends: 14, last: 5), isNull);
      expect(decide(sends: 40, last: 15), isNull);
    });

    test('small batches, failures and paywall flows never prompt', () {
      expect(decide(sends: 2, sent: 2), isNull);
      expect(decide(sends: 2, failed: 1), isNull);
      expect(decide(sends: 2, paywall: true), isNull);
    });

    test('a missed milestone carries over to the next good batch', () {
      expect(decide(sends: 2, sent: 1), isNull);
      expect(decide(sends: 3), 2);
    });

    test('skipped milestones collapse into one prompt', () {
      // A user who passed 2 and 5 without a qualifying batch gets one
      // prompt, recorded at 5, so 15 is still ahead.
      expect(decide(sends: 6), 5);
    });
  });
}

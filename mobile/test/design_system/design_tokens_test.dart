import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/design_system/tokens/app_tokens.dart';

void main() {
  test('design token values match the approved master system', () {
    expect(AppColors.background.toARGB32(), 0xFF0A0C10);
    expect(AppColors.primary.toARGB32(), 0xFF00F0FF);
    expect(AppColors.aiAccent.toARGB32(), 0xFFA855F7);
    expect(AppSpacing.lg, 16);
    expect(AppRadius.card.x, 12);
    expect(AppBreakpoints.reference, 390);
    expect(AppDurations.normal.inMilliseconds, 200);
  });
}

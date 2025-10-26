import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state using shared preferences.
class OnboardingService {
  static const String _onboardingKey = 'has_completed_onboarding';

  /// Check if user has completed onboarding.
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Reset onboarding state (for testing).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  /// Get the initial route based on onboarding status.
  Future<String> getInitialRoute() async {
    final completed = await hasCompletedOnboarding();
    return completed ? '/' : '/onboarding';
  }
}

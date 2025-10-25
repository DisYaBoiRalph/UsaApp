/// Service to manage onboarding state using shared preferences.
class OnboardingService {
  // static const String _onboardingKey = 'has_completed_onboarding';
  
  // Simple in-memory storage for now
  // TODO: Replace with SharedPreferences for persistent storage
  static bool _hasCompletedOnboarding = false;

  /// Check if user has completed onboarding.
  Future<bool> hasCompletedOnboarding() async {
    // TODO: Implement with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool(_onboardingKey) ?? false;
    return _hasCompletedOnboarding;
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    // TODO: Implement with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool(_onboardingKey, true);
    _hasCompletedOnboarding = true;
  }

  /// Reset onboarding state (for testing).
  Future<void> reset() async {
    _hasCompletedOnboarding = false;
  }

  /// Get the initial route based on onboarding status.
  Future<String> getInitialRoute() async {
    final completed = await hasCompletedOnboarding();
    return completed ? '/' : '/onboarding';
  }
}

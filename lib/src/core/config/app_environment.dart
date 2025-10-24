enum AppEnvironment { development, staging, production }

extension AppEnvironmentX on AppEnvironment {
  bool get isProduction => this == AppEnvironment.production;
}

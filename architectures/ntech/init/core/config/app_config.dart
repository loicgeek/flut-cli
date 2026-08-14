enum AppFlavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
    this.enableLogging = false,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final String appName;
  final bool enableLogging;

  bool get isProduction  => flavor == AppFlavor.prod;
  bool get isDevelopment => flavor == AppFlavor.dev;

  static const dev = AppConfig(
    flavor: AppFlavor.dev,
    baseUrl: 'https://api.dev.example.com',
    appName: 'App (Dev)',
    enableLogging: true,
  );

  static const staging = AppConfig(
    flavor: AppFlavor.staging,
    baseUrl: 'https://api.staging.example.com',
    appName: 'App (Staging)',
    enableLogging: true,
  );

  static const prod = AppConfig(
    flavor: AppFlavor.prod,
    baseUrl: 'https://api.example.com',
    appName: 'App',
  );
}


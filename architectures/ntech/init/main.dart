import 'core/bootstrap.dart';
import 'core/config/app_config.dart';

// Default entry point — maps to the dev flavor.
// Use flavor-specific targets for CI / release builds:
//   flutter run -t lib/main_dev.dart
//   flutter run -t lib/main_staging.dart
//   flutter run -t lib/main_prod.dart
void main() => bootstrap(AppConfig.dev);


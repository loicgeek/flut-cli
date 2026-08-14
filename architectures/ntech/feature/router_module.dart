import 'package:auto_route/auto_route.dart';

import 'package:{{pkg}}/core/custom_transition_builders.dart';
import '../screens/{{name}}_screen.dart';

part '{{name}}_router_module.g.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/{{name}}/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class {{Pascal}}RouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: {{Pascal}}Route.page),
        // TODO: add more routes for this feature
      ];
}


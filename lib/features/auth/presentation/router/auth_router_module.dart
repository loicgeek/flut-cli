import 'package:auto_route/auto_route.dart';

import 'package:your_app/core/custom_transition_builders.dart';
import '../screens/auth_screen.dart';

part 'auth_router_module.g.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/auth/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class AuthRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AuthRoute.page),
        // TODO: add more routes for this feature
      ];
}

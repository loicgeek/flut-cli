import 'package:auto_route/auto_route.dart';

import 'package:your_app/core/custom_transition_builders.dart';
import '../screens/user_profile_screen.dart';

part 'user_profile_router_module.g.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/user_profile/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class UserProfileRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: UserProfileRoute.page),
        // TODO: add more routes for this feature
      ];
}

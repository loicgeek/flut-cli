import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    // TODO: add routes
    // AutoRoute(page: LoginRoute.page, initial: true),
  ];
}


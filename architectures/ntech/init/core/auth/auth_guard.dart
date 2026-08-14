import 'package:auto_route/auto_route.dart';
import '../di/service_locator.dart';
import '../storage/secure_storage.dart';
// import '../../features/auth/presentation/screens/login_screen.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final token = await sl<SecureStorage>().accessToken;
    if (token != null) {
      resolver.next(true);
    } else {
      // router.replace(const LoginRoute());
    }
  }
}


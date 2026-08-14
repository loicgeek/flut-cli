import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({required this.enableLogging});
  final bool enableLogging;

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> t,
  ) {
    super.onTransition(bloc, t);
    if (enableLogging) {
      Logger().d(
        '[${bloc.runtimeType}] ${t.event.runtimeType} -> ${t.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stack) {
    Logger().e('[${bloc.runtimeType}]', error: error, stackTrace: stack);
    super.onError(bloc, error, stack);
  }
}


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({required this.enableLogging});
  final bool enableLogging;

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (enableLogging) {
      Logger().d(
        '[${bloc.runtimeType}] ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    Logger().e('[${bloc.runtimeType}]', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}


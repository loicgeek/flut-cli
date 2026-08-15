/// Base contract for every use case in the domain layer.
///
/// [R] is what the use case returns, [Params] what it needs to run. Use
/// [NoParams] for use cases that take no arguments.
///
/// Failures are signalled by throwing an AppFailure (see core/error), so call
/// sites can `try/catch` in one place instead of unwrapping a result type.
abstract interface class UseCase<R, Params> {
  Future<R> call(Params params);
}

/// Marker for use cases that take no arguments.
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}

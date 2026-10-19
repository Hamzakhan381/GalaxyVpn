/// Base contract for asynchronous use cases with parameters
abstract class UseCase<T, P> {
  Future<T> call(P params);
}

/// Base contract for asynchronous stream use cases with parameters
abstract class StreamUseCase<T, P> {
  Stream<T> call(P params);
}

/// Represents the absence of parameters for use cases that require none
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoParams;

  @override
  int get hashCode => 0;
}

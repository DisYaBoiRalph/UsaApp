abstract class UseCase<Output, Params> {
  const UseCase();

  Future<Output> call(Params params);
}

abstract class StreamUseCase<Output, Params> {
  const StreamUseCase();

  Stream<Output> call(Params params);
}

class NoParams {
  const NoParams();
}

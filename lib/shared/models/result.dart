/// A tiny success/failure wrapper for operations that can fail without
/// throwing. Use `switch` to handle both branches exhaustively.
///
/// ```dart
/// final result = await repo.doThing();
/// switch (result) {
///   case Success(:final data): print(data);
///   case Failure(:final message): print(message);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;
}

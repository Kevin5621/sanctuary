part of 'my_advisors_cubit.dart';

enum MyAdvisorsStatus { initial, loading, ready, failure }

class MyAdvisorsState extends Equatable {
  const MyAdvisorsState({
    this.status = MyAdvisorsStatus.initial,
    this.advisors = const MyAdvisors.empty(),
    this.errorMessage,
  });

  final MyAdvisorsStatus status;
  final MyAdvisors advisors;
  final String? errorMessage;

  bool get isLoading =>
      status == MyAdvisorsStatus.loading || status == MyAdvisorsStatus.initial;
  bool get isReady => status == MyAdvisorsStatus.ready;
  bool get isFailure => status == MyAdvisorsStatus.failure;

  MyAdvisorsState copyWith({
    MyAdvisorsStatus? status,
    MyAdvisors? advisors,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyAdvisorsState(
      status: status ?? this.status,
      advisors: advisors ?? this.advisors,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, advisors, errorMessage];
}

part of 'kaprodi_cubit.dart';

/// Status pemuatan bersama untuk keempat tab Kaprodi.
enum LoadStatus { initial, loading, ready, failure }

extension LoadStatusX on LoadStatus {
  bool get isLoading => this == LoadStatus.loading || this == LoadStatus.initial;
  bool get isFailure => this == LoadStatus.failure;
  bool get isReady => this == LoadStatus.ready;
}

class DashboardState extends Equatable {
  const DashboardState({
    this.status = LoadStatus.initial,
    this.dashboard = const ProgramDashboard.initial(),
    this.periodDays = 30,
    this.errorMessage,
  });

  final LoadStatus status;
  final ProgramDashboard dashboard;
  final int periodDays;
  final String? errorMessage;

  /// True bila server menolak mengeluarkan angka karena prodi < ambang.
  bool get isInsufficient => status.isReady && !dashboard.isSufficient;

  DashboardState copyWith({
    LoadStatus? status,
    ProgramDashboard? dashboard,
    int? periodDays,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      periodDays: periodDays ?? this.periodDays,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, dashboard, periodDays, errorMessage];
}

class PembimbingState extends Equatable {
  const PembimbingState({
    this.status = LoadStatus.initial,
    this.advisors = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<AdvisorLoad> advisors;
  final String? errorMessage;

  int get totalAdvisees =>
      advisors.fold(0, (sum, advisor) => sum + advisor.adviseeCount);

  bool get isEmpty => status.isReady && advisors.isEmpty;

  PembimbingState copyWith({
    LoadStatus? status,
    List<AdvisorLoad>? advisors,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PembimbingState(
      status: status ?? this.status,
      advisors: advisors ?? this.advisors,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, advisors, errorMessage];
}

class LaporanState extends Equatable {
  const LaporanState({
    this.status = LoadStatus.initial,
    this.reports = const [],
    this.periodDays = 90,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<CohortReport> reports;
  final int periodDays;
  final String? errorMessage;

  bool get isEmpty => status.isReady && reports.isEmpty;

  LaporanState copyWith({
    LoadStatus? status,
    List<CohortReport>? reports,
    int? periodDays,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LaporanState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      periodDays: periodDays ?? this.periodDays,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, reports, periodDays, errorMessage];
}

class KaprodiProfilState extends Equatable {
  const KaprodiProfilState({
    this.status = LoadStatus.initial,
    this.profile = const ProgramProfile.empty(),
    this.errorMessage,
  });

  final LoadStatus status;
  final ProgramProfile profile;
  final String? errorMessage;

  KaprodiProfilState copyWith({
    LoadStatus? status,
    ProgramProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return KaprodiProfilState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

@freezed
abstract class Patient with _$Patient {
  const factory Patient({
    required int id,
    @JsonKey(name: 'patientName') required String patientName,
    @JsonKey(name: 'lastVisitDate') String? lastVisitDate,
    @JsonKey(name: 'computedStatus') required String status,
    int? age,
    int? screeningCount,
    String? viaTestResult,
    List<Screening>? screenings,
    PatientHistory? history,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
}

@freezed
abstract class Screening with _$Screening {
  const factory Screening({
    required int id,
    required String date,
    required String status,
  }) = _Screening;

  factory Screening.fromJson(Map<String, dynamic> json) =>
      _$ScreeningFromJson(json);
}

@freezed
abstract class PatientHistory with _$PatientHistory {
  const factory PatientHistory({
    bool? hpvTest,
  }) = _PatientHistory;

  factory PatientHistory.fromJson(Map<String, dynamic> json) =>
      _$PatientHistoryFromJson(json);
}

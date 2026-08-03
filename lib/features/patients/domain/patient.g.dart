// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Patient _$PatientFromJson(Map<String, dynamic> json) => _Patient(
  id: (json['id'] as num).toInt(),
  patientName: json['patientName'] as String,
  lastVisitDate: json['lastVisitDate'] as String?,
  status: json['computedStatus'] as String,
  age: (json['age'] as num?)?.toInt(),
  screeningCount: (json['screeningCount'] as num?)?.toInt(),
  viaTestResult: json['viaTestResult'] as String?,
  screenings: (json['screenings'] as List<dynamic>?)
      ?.map((e) => Screening.fromJson(e as Map<String, dynamic>))
      .toList(),
  history: json['history'] == null
      ? null
      : PatientHistory.fromJson(json['history'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PatientToJson(_Patient instance) => <String, dynamic>{
  'id': instance.id,
  'patientName': instance.patientName,
  'lastVisitDate': instance.lastVisitDate,
  'computedStatus': instance.status,
  'age': instance.age,
  'screeningCount': instance.screeningCount,
  'viaTestResult': instance.viaTestResult,
  'screenings': instance.screenings,
  'history': instance.history,
};

_Screening _$ScreeningFromJson(Map<String, dynamic> json) => _Screening(
  id: (json['id'] as num).toInt(),
  date: json['date'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ScreeningToJson(_Screening instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'status': instance.status,
    };

_PatientHistory _$PatientHistoryFromJson(Map<String, dynamic> json) =>
    _PatientHistory(hpvTest: json['hpvTest'] as bool?);

Map<String, dynamic> _$PatientHistoryToJson(_PatientHistory instance) =>
    <String, dynamic>{'hpvTest': instance.hpvTest};

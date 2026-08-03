// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Patient {

 int get id;@JsonKey(name: 'patientName') String get patientName;@JsonKey(name: 'lastVisitDate') String? get lastVisitDate;@JsonKey(name: 'computedStatus') String get status; int? get age; int? get screeningCount; String? get viaTestResult; List<Screening>? get screenings; PatientHistory? get history;
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientCopyWith<Patient> get copyWith => _$PatientCopyWithImpl<Patient>(this as Patient, _$identity);

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.lastVisitDate, lastVisitDate) || other.lastVisitDate == lastVisitDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.age, age) || other.age == age)&&(identical(other.screeningCount, screeningCount) || other.screeningCount == screeningCount)&&(identical(other.viaTestResult, viaTestResult) || other.viaTestResult == viaTestResult)&&const DeepCollectionEquality().equals(other.screenings, screenings)&&(identical(other.history, history) || other.history == history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientName,lastVisitDate,status,age,screeningCount,viaTestResult,const DeepCollectionEquality().hash(screenings),history);

@override
String toString() {
  return 'Patient(id: $id, patientName: $patientName, lastVisitDate: $lastVisitDate, status: $status, age: $age, screeningCount: $screeningCount, viaTestResult: $viaTestResult, screenings: $screenings, history: $history)';
}


}

/// @nodoc
abstract mixin class $PatientCopyWith<$Res>  {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) _then) = _$PatientCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'patientName') String patientName,@JsonKey(name: 'lastVisitDate') String? lastVisitDate,@JsonKey(name: 'computedStatus') String status, int? age, int? screeningCount, String? viaTestResult, List<Screening>? screenings, PatientHistory? history
});


$PatientHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class _$PatientCopyWithImpl<$Res>
    implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._self, this._then);

  final Patient _self;
  final $Res Function(Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientName = null,Object? lastVisitDate = freezed,Object? status = null,Object? age = freezed,Object? screeningCount = freezed,Object? viaTestResult = freezed,Object? screenings = freezed,Object? history = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,lastVisitDate: freezed == lastVisitDate ? _self.lastVisitDate : lastVisitDate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,screeningCount: freezed == screeningCount ? _self.screeningCount : screeningCount // ignore: cast_nullable_to_non_nullable
as int?,viaTestResult: freezed == viaTestResult ? _self.viaTestResult : viaTestResult // ignore: cast_nullable_to_non_nullable
as String?,screenings: freezed == screenings ? _self.screenings : screenings // ignore: cast_nullable_to_non_nullable
as List<Screening>?,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as PatientHistory?,
  ));
}
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatientHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $PatientHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}


/// Adds pattern-matching-related methods to [Patient].
extension PatientPatterns on Patient {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Patient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Patient value)  $default,){
final _that = this;
switch (_that) {
case _Patient():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Patient value)?  $default,){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'patientName')  String patientName, @JsonKey(name: 'lastVisitDate')  String? lastVisitDate, @JsonKey(name: 'computedStatus')  String status,  int? age,  int? screeningCount,  String? viaTestResult,  List<Screening>? screenings,  PatientHistory? history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.patientName,_that.lastVisitDate,_that.status,_that.age,_that.screeningCount,_that.viaTestResult,_that.screenings,_that.history);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'patientName')  String patientName, @JsonKey(name: 'lastVisitDate')  String? lastVisitDate, @JsonKey(name: 'computedStatus')  String status,  int? age,  int? screeningCount,  String? viaTestResult,  List<Screening>? screenings,  PatientHistory? history)  $default,) {final _that = this;
switch (_that) {
case _Patient():
return $default(_that.id,_that.patientName,_that.lastVisitDate,_that.status,_that.age,_that.screeningCount,_that.viaTestResult,_that.screenings,_that.history);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'patientName')  String patientName, @JsonKey(name: 'lastVisitDate')  String? lastVisitDate, @JsonKey(name: 'computedStatus')  String status,  int? age,  int? screeningCount,  String? viaTestResult,  List<Screening>? screenings,  PatientHistory? history)?  $default,) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.patientName,_that.lastVisitDate,_that.status,_that.age,_that.screeningCount,_that.viaTestResult,_that.screenings,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Patient implements Patient {
  const _Patient({required this.id, @JsonKey(name: 'patientName') required this.patientName, @JsonKey(name: 'lastVisitDate') this.lastVisitDate, @JsonKey(name: 'computedStatus') required this.status, this.age, this.screeningCount, this.viaTestResult, final  List<Screening>? screenings, this.history}): _screenings = screenings;
  factory _Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);

@override final  int id;
@override@JsonKey(name: 'patientName') final  String patientName;
@override@JsonKey(name: 'lastVisitDate') final  String? lastVisitDate;
@override@JsonKey(name: 'computedStatus') final  String status;
@override final  int? age;
@override final  int? screeningCount;
@override final  String? viaTestResult;
 final  List<Screening>? _screenings;
@override List<Screening>? get screenings {
  final value = _screenings;
  if (value == null) return null;
  if (_screenings is EqualUnmodifiableListView) return _screenings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  PatientHistory? history;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientCopyWith<_Patient> get copyWith => __$PatientCopyWithImpl<_Patient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.lastVisitDate, lastVisitDate) || other.lastVisitDate == lastVisitDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.age, age) || other.age == age)&&(identical(other.screeningCount, screeningCount) || other.screeningCount == screeningCount)&&(identical(other.viaTestResult, viaTestResult) || other.viaTestResult == viaTestResult)&&const DeepCollectionEquality().equals(other._screenings, _screenings)&&(identical(other.history, history) || other.history == history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientName,lastVisitDate,status,age,screeningCount,viaTestResult,const DeepCollectionEquality().hash(_screenings),history);

@override
String toString() {
  return 'Patient(id: $id, patientName: $patientName, lastVisitDate: $lastVisitDate, status: $status, age: $age, screeningCount: $screeningCount, viaTestResult: $viaTestResult, screenings: $screenings, history: $history)';
}


}

/// @nodoc
abstract mixin class _$PatientCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$PatientCopyWith(_Patient value, $Res Function(_Patient) _then) = __$PatientCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'patientName') String patientName,@JsonKey(name: 'lastVisitDate') String? lastVisitDate,@JsonKey(name: 'computedStatus') String status, int? age, int? screeningCount, String? viaTestResult, List<Screening>? screenings, PatientHistory? history
});


@override $PatientHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class __$PatientCopyWithImpl<$Res>
    implements _$PatientCopyWith<$Res> {
  __$PatientCopyWithImpl(this._self, this._then);

  final _Patient _self;
  final $Res Function(_Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientName = null,Object? lastVisitDate = freezed,Object? status = null,Object? age = freezed,Object? screeningCount = freezed,Object? viaTestResult = freezed,Object? screenings = freezed,Object? history = freezed,}) {
  return _then(_Patient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,lastVisitDate: freezed == lastVisitDate ? _self.lastVisitDate : lastVisitDate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,screeningCount: freezed == screeningCount ? _self.screeningCount : screeningCount // ignore: cast_nullable_to_non_nullable
as int?,viaTestResult: freezed == viaTestResult ? _self.viaTestResult : viaTestResult // ignore: cast_nullable_to_non_nullable
as String?,screenings: freezed == screenings ? _self._screenings : screenings // ignore: cast_nullable_to_non_nullable
as List<Screening>?,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as PatientHistory?,
  ));
}

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatientHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $PatientHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}


/// @nodoc
mixin _$Screening {

 int get id; String get date; String get status;
/// Create a copy of Screening
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreeningCopyWith<Screening> get copyWith => _$ScreeningCopyWithImpl<Screening>(this as Screening, _$identity);

  /// Serializes this Screening to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Screening&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,status);

@override
String toString() {
  return 'Screening(id: $id, date: $date, status: $status)';
}


}

/// @nodoc
abstract mixin class $ScreeningCopyWith<$Res>  {
  factory $ScreeningCopyWith(Screening value, $Res Function(Screening) _then) = _$ScreeningCopyWithImpl;
@useResult
$Res call({
 int id, String date, String status
});




}
/// @nodoc
class _$ScreeningCopyWithImpl<$Res>
    implements $ScreeningCopyWith<$Res> {
  _$ScreeningCopyWithImpl(this._self, this._then);

  final Screening _self;
  final $Res Function(Screening) _then;

/// Create a copy of Screening
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Screening].
extension ScreeningPatterns on Screening {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Screening value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Screening() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Screening value)  $default,){
final _that = this;
switch (_that) {
case _Screening():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Screening value)?  $default,){
final _that = this;
switch (_that) {
case _Screening() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String date,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Screening() when $default != null:
return $default(_that.id,_that.date,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String date,  String status)  $default,) {final _that = this;
switch (_that) {
case _Screening():
return $default(_that.id,_that.date,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String date,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Screening() when $default != null:
return $default(_that.id,_that.date,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Screening implements Screening {
  const _Screening({required this.id, required this.date, required this.status});
  factory _Screening.fromJson(Map<String, dynamic> json) => _$ScreeningFromJson(json);

@override final  int id;
@override final  String date;
@override final  String status;

/// Create a copy of Screening
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScreeningCopyWith<_Screening> get copyWith => __$ScreeningCopyWithImpl<_Screening>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScreeningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Screening&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,status);

@override
String toString() {
  return 'Screening(id: $id, date: $date, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ScreeningCopyWith<$Res> implements $ScreeningCopyWith<$Res> {
  factory _$ScreeningCopyWith(_Screening value, $Res Function(_Screening) _then) = __$ScreeningCopyWithImpl;
@override @useResult
$Res call({
 int id, String date, String status
});




}
/// @nodoc
class __$ScreeningCopyWithImpl<$Res>
    implements _$ScreeningCopyWith<$Res> {
  __$ScreeningCopyWithImpl(this._self, this._then);

  final _Screening _self;
  final $Res Function(_Screening) _then;

/// Create a copy of Screening
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? status = null,}) {
  return _then(_Screening(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PatientHistory {

 bool? get hpvTest;
/// Create a copy of PatientHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientHistoryCopyWith<PatientHistory> get copyWith => _$PatientHistoryCopyWithImpl<PatientHistory>(this as PatientHistory, _$identity);

  /// Serializes this PatientHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientHistory&&(identical(other.hpvTest, hpvTest) || other.hpvTest == hpvTest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hpvTest);

@override
String toString() {
  return 'PatientHistory(hpvTest: $hpvTest)';
}


}

/// @nodoc
abstract mixin class $PatientHistoryCopyWith<$Res>  {
  factory $PatientHistoryCopyWith(PatientHistory value, $Res Function(PatientHistory) _then) = _$PatientHistoryCopyWithImpl;
@useResult
$Res call({
 bool? hpvTest
});




}
/// @nodoc
class _$PatientHistoryCopyWithImpl<$Res>
    implements $PatientHistoryCopyWith<$Res> {
  _$PatientHistoryCopyWithImpl(this._self, this._then);

  final PatientHistory _self;
  final $Res Function(PatientHistory) _then;

/// Create a copy of PatientHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hpvTest = freezed,}) {
  return _then(_self.copyWith(
hpvTest: freezed == hpvTest ? _self.hpvTest : hpvTest // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientHistory].
extension PatientHistoryPatterns on PatientHistory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientHistory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientHistory value)  $default,){
final _that = this;
switch (_that) {
case _PatientHistory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientHistory value)?  $default,){
final _that = this;
switch (_that) {
case _PatientHistory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? hpvTest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientHistory() when $default != null:
return $default(_that.hpvTest);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? hpvTest)  $default,) {final _that = this;
switch (_that) {
case _PatientHistory():
return $default(_that.hpvTest);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? hpvTest)?  $default,) {final _that = this;
switch (_that) {
case _PatientHistory() when $default != null:
return $default(_that.hpvTest);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientHistory implements PatientHistory {
  const _PatientHistory({this.hpvTest});
  factory _PatientHistory.fromJson(Map<String, dynamic> json) => _$PatientHistoryFromJson(json);

@override final  bool? hpvTest;

/// Create a copy of PatientHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientHistoryCopyWith<_PatientHistory> get copyWith => __$PatientHistoryCopyWithImpl<_PatientHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientHistory&&(identical(other.hpvTest, hpvTest) || other.hpvTest == hpvTest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hpvTest);

@override
String toString() {
  return 'PatientHistory(hpvTest: $hpvTest)';
}


}

/// @nodoc
abstract mixin class _$PatientHistoryCopyWith<$Res> implements $PatientHistoryCopyWith<$Res> {
  factory _$PatientHistoryCopyWith(_PatientHistory value, $Res Function(_PatientHistory) _then) = __$PatientHistoryCopyWithImpl;
@override @useResult
$Res call({
 bool? hpvTest
});




}
/// @nodoc
class __$PatientHistoryCopyWithImpl<$Res>
    implements _$PatientHistoryCopyWith<$Res> {
  __$PatientHistoryCopyWithImpl(this._self, this._then);

  final _PatientHistory _self;
  final $Res Function(_PatientHistory) _then;

/// Create a copy of PatientHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hpvTest = freezed,}) {
  return _then(_PatientHistory(
hpvTest: freezed == hpvTest ? _self.hpvTest : hpvTest // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

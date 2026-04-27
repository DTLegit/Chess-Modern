// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ApiError {
  String get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiErrorCopyWith<ApiError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiErrorCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) then) =
      _$ApiErrorCopyWithImpl<$Res, ApiError>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$ApiErrorCopyWithImpl<$Res, $Val extends ApiError>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_value.copyWith(
      field0: null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiError_GameNotFoundImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiError_GameNotFoundImplCopyWith(
          _$ApiError_GameNotFoundImpl value,
          $Res Function(_$ApiError_GameNotFoundImpl) then) =
      __$$ApiError_GameNotFoundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$ApiError_GameNotFoundImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiError_GameNotFoundImpl>
    implements _$$ApiError_GameNotFoundImplCopyWith<$Res> {
  __$$ApiError_GameNotFoundImplCopyWithImpl(_$ApiError_GameNotFoundImpl _value,
      $Res Function(_$ApiError_GameNotFoundImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$ApiError_GameNotFoundImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ApiError_GameNotFoundImpl extends ApiError_GameNotFound {
  const _$ApiError_GameNotFoundImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'ApiError.gameNotFound(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiError_GameNotFoundImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiError_GameNotFoundImplCopyWith<_$ApiError_GameNotFoundImpl>
      get copyWith => __$$ApiError_GameNotFoundImplCopyWithImpl<
          _$ApiError_GameNotFoundImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) {
    return gameNotFound(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) {
    return gameNotFound?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) {
    if (gameNotFound != null) {
      return gameNotFound(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) {
    return gameNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) {
    return gameNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) {
    if (gameNotFound != null) {
      return gameNotFound(this);
    }
    return orElse();
  }
}

abstract class ApiError_GameNotFound extends ApiError {
  const factory ApiError_GameNotFound(final String field0) =
      _$ApiError_GameNotFoundImpl;
  const ApiError_GameNotFound._() : super._();

  @override
  String get field0;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiError_GameNotFoundImplCopyWith<_$ApiError_GameNotFoundImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiError_IllegalMoveImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiError_IllegalMoveImplCopyWith(_$ApiError_IllegalMoveImpl value,
          $Res Function(_$ApiError_IllegalMoveImpl) then) =
      __$$ApiError_IllegalMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$ApiError_IllegalMoveImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiError_IllegalMoveImpl>
    implements _$$ApiError_IllegalMoveImplCopyWith<$Res> {
  __$$ApiError_IllegalMoveImplCopyWithImpl(_$ApiError_IllegalMoveImpl _value,
      $Res Function(_$ApiError_IllegalMoveImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$ApiError_IllegalMoveImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ApiError_IllegalMoveImpl extends ApiError_IllegalMove {
  const _$ApiError_IllegalMoveImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'ApiError.illegalMove(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiError_IllegalMoveImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiError_IllegalMoveImplCopyWith<_$ApiError_IllegalMoveImpl>
      get copyWith =>
          __$$ApiError_IllegalMoveImplCopyWithImpl<_$ApiError_IllegalMoveImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) {
    return illegalMove(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) {
    return illegalMove?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) {
    if (illegalMove != null) {
      return illegalMove(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) {
    return illegalMove(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) {
    return illegalMove?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) {
    if (illegalMove != null) {
      return illegalMove(this);
    }
    return orElse();
  }
}

abstract class ApiError_IllegalMove extends ApiError {
  const factory ApiError_IllegalMove(final String field0) =
      _$ApiError_IllegalMoveImpl;
  const ApiError_IllegalMove._() : super._();

  @override
  String get field0;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiError_IllegalMoveImplCopyWith<_$ApiError_IllegalMoveImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiError_InvalidInputImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiError_InvalidInputImplCopyWith(
          _$ApiError_InvalidInputImpl value,
          $Res Function(_$ApiError_InvalidInputImpl) then) =
      __$$ApiError_InvalidInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$ApiError_InvalidInputImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiError_InvalidInputImpl>
    implements _$$ApiError_InvalidInputImplCopyWith<$Res> {
  __$$ApiError_InvalidInputImplCopyWithImpl(_$ApiError_InvalidInputImpl _value,
      $Res Function(_$ApiError_InvalidInputImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$ApiError_InvalidInputImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ApiError_InvalidInputImpl extends ApiError_InvalidInput {
  const _$ApiError_InvalidInputImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'ApiError.invalidInput(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiError_InvalidInputImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiError_InvalidInputImplCopyWith<_$ApiError_InvalidInputImpl>
      get copyWith => __$$ApiError_InvalidInputImplCopyWithImpl<
          _$ApiError_InvalidInputImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) {
    return invalidInput(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) {
    return invalidInput?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) {
    if (invalidInput != null) {
      return invalidInput(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) {
    return invalidInput(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) {
    return invalidInput?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) {
    if (invalidInput != null) {
      return invalidInput(this);
    }
    return orElse();
  }
}

abstract class ApiError_InvalidInput extends ApiError {
  const factory ApiError_InvalidInput(final String field0) =
      _$ApiError_InvalidInputImpl;
  const ApiError_InvalidInput._() : super._();

  @override
  String get field0;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiError_InvalidInputImplCopyWith<_$ApiError_InvalidInputImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiError_EngineImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiError_EngineImplCopyWith(_$ApiError_EngineImpl value,
          $Res Function(_$ApiError_EngineImpl) then) =
      __$$ApiError_EngineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$ApiError_EngineImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiError_EngineImpl>
    implements _$$ApiError_EngineImplCopyWith<$Res> {
  __$$ApiError_EngineImplCopyWithImpl(
      _$ApiError_EngineImpl _value, $Res Function(_$ApiError_EngineImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$ApiError_EngineImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ApiError_EngineImpl extends ApiError_Engine {
  const _$ApiError_EngineImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'ApiError.engine(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiError_EngineImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiError_EngineImplCopyWith<_$ApiError_EngineImpl> get copyWith =>
      __$$ApiError_EngineImplCopyWithImpl<_$ApiError_EngineImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) {
    return engine(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) {
    return engine?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) {
    if (engine != null) {
      return engine(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) {
    return engine(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) {
    return engine?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) {
    if (engine != null) {
      return engine(this);
    }
    return orElse();
  }
}

abstract class ApiError_Engine extends ApiError {
  const factory ApiError_Engine(final String field0) = _$ApiError_EngineImpl;
  const ApiError_Engine._() : super._();

  @override
  String get field0;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiError_EngineImplCopyWith<_$ApiError_EngineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiError_InternalImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiError_InternalImplCopyWith(_$ApiError_InternalImpl value,
          $Res Function(_$ApiError_InternalImpl) then) =
      __$$ApiError_InternalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$ApiError_InternalImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiError_InternalImpl>
    implements _$$ApiError_InternalImplCopyWith<$Res> {
  __$$ApiError_InternalImplCopyWithImpl(_$ApiError_InternalImpl _value,
      $Res Function(_$ApiError_InternalImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$ApiError_InternalImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ApiError_InternalImpl extends ApiError_Internal {
  const _$ApiError_InternalImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'ApiError.internal(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiError_InternalImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiError_InternalImplCopyWith<_$ApiError_InternalImpl> get copyWith =>
      __$$ApiError_InternalImplCopyWithImpl<_$ApiError_InternalImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) gameNotFound,
    required TResult Function(String field0) illegalMove,
    required TResult Function(String field0) invalidInput,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) internal,
  }) {
    return internal(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? gameNotFound,
    TResult? Function(String field0)? illegalMove,
    TResult? Function(String field0)? invalidInput,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? internal,
  }) {
    return internal?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? gameNotFound,
    TResult Function(String field0)? illegalMove,
    TResult Function(String field0)? invalidInput,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ApiError_GameNotFound value) gameNotFound,
    required TResult Function(ApiError_IllegalMove value) illegalMove,
    required TResult Function(ApiError_InvalidInput value) invalidInput,
    required TResult Function(ApiError_Engine value) engine,
    required TResult Function(ApiError_Internal value) internal,
  }) {
    return internal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ApiError_GameNotFound value)? gameNotFound,
    TResult? Function(ApiError_IllegalMove value)? illegalMove,
    TResult? Function(ApiError_InvalidInput value)? invalidInput,
    TResult? Function(ApiError_Engine value)? engine,
    TResult? Function(ApiError_Internal value)? internal,
  }) {
    return internal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ApiError_GameNotFound value)? gameNotFound,
    TResult Function(ApiError_IllegalMove value)? illegalMove,
    TResult Function(ApiError_InvalidInput value)? invalidInput,
    TResult Function(ApiError_Engine value)? engine,
    TResult Function(ApiError_Internal value)? internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(this);
    }
    return orElse();
  }
}

abstract class ApiError_Internal extends ApiError {
  const factory ApiError_Internal(final String field0) =
      _$ApiError_InternalImpl;
  const ApiError_Internal._() : super._();

  @override
  String get field0;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiError_InternalImplCopyWith<_$ApiError_InternalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackendEvent {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MoveMadeEvent field0) moveMade,
    required TResult Function(AiProgressEvent field0) aiProgress,
    required TResult Function(GameOverEvent field0) gameOver,
    required TResult Function(ClockTickEvent field0) clockTick,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MoveMadeEvent field0)? moveMade,
    TResult? Function(AiProgressEvent field0)? aiProgress,
    TResult? Function(GameOverEvent field0)? gameOver,
    TResult? Function(ClockTickEvent field0)? clockTick,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MoveMadeEvent field0)? moveMade,
    TResult Function(AiProgressEvent field0)? aiProgress,
    TResult Function(GameOverEvent field0)? gameOver,
    TResult Function(ClockTickEvent field0)? clockTick,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BackendEvent_MoveMade value) moveMade,
    required TResult Function(BackendEvent_AiProgress value) aiProgress,
    required TResult Function(BackendEvent_GameOver value) gameOver,
    required TResult Function(BackendEvent_ClockTick value) clockTick,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BackendEvent_MoveMade value)? moveMade,
    TResult? Function(BackendEvent_AiProgress value)? aiProgress,
    TResult? Function(BackendEvent_GameOver value)? gameOver,
    TResult? Function(BackendEvent_ClockTick value)? clockTick,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BackendEvent_MoveMade value)? moveMade,
    TResult Function(BackendEvent_AiProgress value)? aiProgress,
    TResult Function(BackendEvent_GameOver value)? gameOver,
    TResult Function(BackendEvent_ClockTick value)? clockTick,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackendEventCopyWith<$Res> {
  factory $BackendEventCopyWith(
          BackendEvent value, $Res Function(BackendEvent) then) =
      _$BackendEventCopyWithImpl<$Res, BackendEvent>;
}

/// @nodoc
class _$BackendEventCopyWithImpl<$Res, $Val extends BackendEvent>
    implements $BackendEventCopyWith<$Res> {
  _$BackendEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$BackendEvent_MoveMadeImplCopyWith<$Res> {
  factory _$$BackendEvent_MoveMadeImplCopyWith(
          _$BackendEvent_MoveMadeImpl value,
          $Res Function(_$BackendEvent_MoveMadeImpl) then) =
      __$$BackendEvent_MoveMadeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MoveMadeEvent field0});
}

/// @nodoc
class __$$BackendEvent_MoveMadeImplCopyWithImpl<$Res>
    extends _$BackendEventCopyWithImpl<$Res, _$BackendEvent_MoveMadeImpl>
    implements _$$BackendEvent_MoveMadeImplCopyWith<$Res> {
  __$$BackendEvent_MoveMadeImplCopyWithImpl(_$BackendEvent_MoveMadeImpl _value,
      $Res Function(_$BackendEvent_MoveMadeImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$BackendEvent_MoveMadeImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MoveMadeEvent,
    ));
  }
}

/// @nodoc

class _$BackendEvent_MoveMadeImpl extends BackendEvent_MoveMade {
  const _$BackendEvent_MoveMadeImpl(this.field0) : super._();

  @override
  final MoveMadeEvent field0;

  @override
  String toString() {
    return 'BackendEvent.moveMade(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackendEvent_MoveMadeImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackendEvent_MoveMadeImplCopyWith<_$BackendEvent_MoveMadeImpl>
      get copyWith => __$$BackendEvent_MoveMadeImplCopyWithImpl<
          _$BackendEvent_MoveMadeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MoveMadeEvent field0) moveMade,
    required TResult Function(AiProgressEvent field0) aiProgress,
    required TResult Function(GameOverEvent field0) gameOver,
    required TResult Function(ClockTickEvent field0) clockTick,
  }) {
    return moveMade(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MoveMadeEvent field0)? moveMade,
    TResult? Function(AiProgressEvent field0)? aiProgress,
    TResult? Function(GameOverEvent field0)? gameOver,
    TResult? Function(ClockTickEvent field0)? clockTick,
  }) {
    return moveMade?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MoveMadeEvent field0)? moveMade,
    TResult Function(AiProgressEvent field0)? aiProgress,
    TResult Function(GameOverEvent field0)? gameOver,
    TResult Function(ClockTickEvent field0)? clockTick,
    required TResult orElse(),
  }) {
    if (moveMade != null) {
      return moveMade(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BackendEvent_MoveMade value) moveMade,
    required TResult Function(BackendEvent_AiProgress value) aiProgress,
    required TResult Function(BackendEvent_GameOver value) gameOver,
    required TResult Function(BackendEvent_ClockTick value) clockTick,
  }) {
    return moveMade(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BackendEvent_MoveMade value)? moveMade,
    TResult? Function(BackendEvent_AiProgress value)? aiProgress,
    TResult? Function(BackendEvent_GameOver value)? gameOver,
    TResult? Function(BackendEvent_ClockTick value)? clockTick,
  }) {
    return moveMade?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BackendEvent_MoveMade value)? moveMade,
    TResult Function(BackendEvent_AiProgress value)? aiProgress,
    TResult Function(BackendEvent_GameOver value)? gameOver,
    TResult Function(BackendEvent_ClockTick value)? clockTick,
    required TResult orElse(),
  }) {
    if (moveMade != null) {
      return moveMade(this);
    }
    return orElse();
  }
}

abstract class BackendEvent_MoveMade extends BackendEvent {
  const factory BackendEvent_MoveMade(final MoveMadeEvent field0) =
      _$BackendEvent_MoveMadeImpl;
  const BackendEvent_MoveMade._() : super._();

  @override
  MoveMadeEvent get field0;

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackendEvent_MoveMadeImplCopyWith<_$BackendEvent_MoveMadeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BackendEvent_AiProgressImplCopyWith<$Res> {
  factory _$$BackendEvent_AiProgressImplCopyWith(
          _$BackendEvent_AiProgressImpl value,
          $Res Function(_$BackendEvent_AiProgressImpl) then) =
      __$$BackendEvent_AiProgressImplCopyWithImpl<$Res>;
  @useResult
  $Res call({AiProgressEvent field0});
}

/// @nodoc
class __$$BackendEvent_AiProgressImplCopyWithImpl<$Res>
    extends _$BackendEventCopyWithImpl<$Res, _$BackendEvent_AiProgressImpl>
    implements _$$BackendEvent_AiProgressImplCopyWith<$Res> {
  __$$BackendEvent_AiProgressImplCopyWithImpl(
      _$BackendEvent_AiProgressImpl _value,
      $Res Function(_$BackendEvent_AiProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$BackendEvent_AiProgressImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as AiProgressEvent,
    ));
  }
}

/// @nodoc

class _$BackendEvent_AiProgressImpl extends BackendEvent_AiProgress {
  const _$BackendEvent_AiProgressImpl(this.field0) : super._();

  @override
  final AiProgressEvent field0;

  @override
  String toString() {
    return 'BackendEvent.aiProgress(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackendEvent_AiProgressImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackendEvent_AiProgressImplCopyWith<_$BackendEvent_AiProgressImpl>
      get copyWith => __$$BackendEvent_AiProgressImplCopyWithImpl<
          _$BackendEvent_AiProgressImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MoveMadeEvent field0) moveMade,
    required TResult Function(AiProgressEvent field0) aiProgress,
    required TResult Function(GameOverEvent field0) gameOver,
    required TResult Function(ClockTickEvent field0) clockTick,
  }) {
    return aiProgress(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MoveMadeEvent field0)? moveMade,
    TResult? Function(AiProgressEvent field0)? aiProgress,
    TResult? Function(GameOverEvent field0)? gameOver,
    TResult? Function(ClockTickEvent field0)? clockTick,
  }) {
    return aiProgress?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MoveMadeEvent field0)? moveMade,
    TResult Function(AiProgressEvent field0)? aiProgress,
    TResult Function(GameOverEvent field0)? gameOver,
    TResult Function(ClockTickEvent field0)? clockTick,
    required TResult orElse(),
  }) {
    if (aiProgress != null) {
      return aiProgress(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BackendEvent_MoveMade value) moveMade,
    required TResult Function(BackendEvent_AiProgress value) aiProgress,
    required TResult Function(BackendEvent_GameOver value) gameOver,
    required TResult Function(BackendEvent_ClockTick value) clockTick,
  }) {
    return aiProgress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BackendEvent_MoveMade value)? moveMade,
    TResult? Function(BackendEvent_AiProgress value)? aiProgress,
    TResult? Function(BackendEvent_GameOver value)? gameOver,
    TResult? Function(BackendEvent_ClockTick value)? clockTick,
  }) {
    return aiProgress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BackendEvent_MoveMade value)? moveMade,
    TResult Function(BackendEvent_AiProgress value)? aiProgress,
    TResult Function(BackendEvent_GameOver value)? gameOver,
    TResult Function(BackendEvent_ClockTick value)? clockTick,
    required TResult orElse(),
  }) {
    if (aiProgress != null) {
      return aiProgress(this);
    }
    return orElse();
  }
}

abstract class BackendEvent_AiProgress extends BackendEvent {
  const factory BackendEvent_AiProgress(final AiProgressEvent field0) =
      _$BackendEvent_AiProgressImpl;
  const BackendEvent_AiProgress._() : super._();

  @override
  AiProgressEvent get field0;

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackendEvent_AiProgressImplCopyWith<_$BackendEvent_AiProgressImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BackendEvent_GameOverImplCopyWith<$Res> {
  factory _$$BackendEvent_GameOverImplCopyWith(
          _$BackendEvent_GameOverImpl value,
          $Res Function(_$BackendEvent_GameOverImpl) then) =
      __$$BackendEvent_GameOverImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameOverEvent field0});
}

/// @nodoc
class __$$BackendEvent_GameOverImplCopyWithImpl<$Res>
    extends _$BackendEventCopyWithImpl<$Res, _$BackendEvent_GameOverImpl>
    implements _$$BackendEvent_GameOverImplCopyWith<$Res> {
  __$$BackendEvent_GameOverImplCopyWithImpl(_$BackendEvent_GameOverImpl _value,
      $Res Function(_$BackendEvent_GameOverImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$BackendEvent_GameOverImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as GameOverEvent,
    ));
  }
}

/// @nodoc

class _$BackendEvent_GameOverImpl extends BackendEvent_GameOver {
  const _$BackendEvent_GameOverImpl(this.field0) : super._();

  @override
  final GameOverEvent field0;

  @override
  String toString() {
    return 'BackendEvent.gameOver(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackendEvent_GameOverImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackendEvent_GameOverImplCopyWith<_$BackendEvent_GameOverImpl>
      get copyWith => __$$BackendEvent_GameOverImplCopyWithImpl<
          _$BackendEvent_GameOverImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MoveMadeEvent field0) moveMade,
    required TResult Function(AiProgressEvent field0) aiProgress,
    required TResult Function(GameOverEvent field0) gameOver,
    required TResult Function(ClockTickEvent field0) clockTick,
  }) {
    return gameOver(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MoveMadeEvent field0)? moveMade,
    TResult? Function(AiProgressEvent field0)? aiProgress,
    TResult? Function(GameOverEvent field0)? gameOver,
    TResult? Function(ClockTickEvent field0)? clockTick,
  }) {
    return gameOver?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MoveMadeEvent field0)? moveMade,
    TResult Function(AiProgressEvent field0)? aiProgress,
    TResult Function(GameOverEvent field0)? gameOver,
    TResult Function(ClockTickEvent field0)? clockTick,
    required TResult orElse(),
  }) {
    if (gameOver != null) {
      return gameOver(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BackendEvent_MoveMade value) moveMade,
    required TResult Function(BackendEvent_AiProgress value) aiProgress,
    required TResult Function(BackendEvent_GameOver value) gameOver,
    required TResult Function(BackendEvent_ClockTick value) clockTick,
  }) {
    return gameOver(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BackendEvent_MoveMade value)? moveMade,
    TResult? Function(BackendEvent_AiProgress value)? aiProgress,
    TResult? Function(BackendEvent_GameOver value)? gameOver,
    TResult? Function(BackendEvent_ClockTick value)? clockTick,
  }) {
    return gameOver?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BackendEvent_MoveMade value)? moveMade,
    TResult Function(BackendEvent_AiProgress value)? aiProgress,
    TResult Function(BackendEvent_GameOver value)? gameOver,
    TResult Function(BackendEvent_ClockTick value)? clockTick,
    required TResult orElse(),
  }) {
    if (gameOver != null) {
      return gameOver(this);
    }
    return orElse();
  }
}

abstract class BackendEvent_GameOver extends BackendEvent {
  const factory BackendEvent_GameOver(final GameOverEvent field0) =
      _$BackendEvent_GameOverImpl;
  const BackendEvent_GameOver._() : super._();

  @override
  GameOverEvent get field0;

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackendEvent_GameOverImplCopyWith<_$BackendEvent_GameOverImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BackendEvent_ClockTickImplCopyWith<$Res> {
  factory _$$BackendEvent_ClockTickImplCopyWith(
          _$BackendEvent_ClockTickImpl value,
          $Res Function(_$BackendEvent_ClockTickImpl) then) =
      __$$BackendEvent_ClockTickImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ClockTickEvent field0});
}

/// @nodoc
class __$$BackendEvent_ClockTickImplCopyWithImpl<$Res>
    extends _$BackendEventCopyWithImpl<$Res, _$BackendEvent_ClockTickImpl>
    implements _$$BackendEvent_ClockTickImplCopyWith<$Res> {
  __$$BackendEvent_ClockTickImplCopyWithImpl(
      _$BackendEvent_ClockTickImpl _value,
      $Res Function(_$BackendEvent_ClockTickImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$BackendEvent_ClockTickImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ClockTickEvent,
    ));
  }
}

/// @nodoc

class _$BackendEvent_ClockTickImpl extends BackendEvent_ClockTick {
  const _$BackendEvent_ClockTickImpl(this.field0) : super._();

  @override
  final ClockTickEvent field0;

  @override
  String toString() {
    return 'BackendEvent.clockTick(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackendEvent_ClockTickImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackendEvent_ClockTickImplCopyWith<_$BackendEvent_ClockTickImpl>
      get copyWith => __$$BackendEvent_ClockTickImplCopyWithImpl<
          _$BackendEvent_ClockTickImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MoveMadeEvent field0) moveMade,
    required TResult Function(AiProgressEvent field0) aiProgress,
    required TResult Function(GameOverEvent field0) gameOver,
    required TResult Function(ClockTickEvent field0) clockTick,
  }) {
    return clockTick(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MoveMadeEvent field0)? moveMade,
    TResult? Function(AiProgressEvent field0)? aiProgress,
    TResult? Function(GameOverEvent field0)? gameOver,
    TResult? Function(ClockTickEvent field0)? clockTick,
  }) {
    return clockTick?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MoveMadeEvent field0)? moveMade,
    TResult Function(AiProgressEvent field0)? aiProgress,
    TResult Function(GameOverEvent field0)? gameOver,
    TResult Function(ClockTickEvent field0)? clockTick,
    required TResult orElse(),
  }) {
    if (clockTick != null) {
      return clockTick(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BackendEvent_MoveMade value) moveMade,
    required TResult Function(BackendEvent_AiProgress value) aiProgress,
    required TResult Function(BackendEvent_GameOver value) gameOver,
    required TResult Function(BackendEvent_ClockTick value) clockTick,
  }) {
    return clockTick(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BackendEvent_MoveMade value)? moveMade,
    TResult? Function(BackendEvent_AiProgress value)? aiProgress,
    TResult? Function(BackendEvent_GameOver value)? gameOver,
    TResult? Function(BackendEvent_ClockTick value)? clockTick,
  }) {
    return clockTick?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BackendEvent_MoveMade value)? moveMade,
    TResult Function(BackendEvent_AiProgress value)? aiProgress,
    TResult Function(BackendEvent_GameOver value)? gameOver,
    TResult Function(BackendEvent_ClockTick value)? clockTick,
    required TResult orElse(),
  }) {
    if (clockTick != null) {
      return clockTick(this);
    }
    return orElse();
  }
}

abstract class BackendEvent_ClockTick extends BackendEvent {
  const factory BackendEvent_ClockTick(final ClockTickEvent field0) =
      _$BackendEvent_ClockTickImpl;
  const BackendEvent_ClockTick._() : super._();

  @override
  ClockTickEvent get field0;

  /// Create a copy of BackendEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackendEvent_ClockTickImplCopyWith<_$BackendEvent_ClockTickImpl>
      get copyWith => throw _privateConstructorUsedError;
}

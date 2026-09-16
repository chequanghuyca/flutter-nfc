import 'dart:ffi';
import 'dart:math';
import 'dart:collection';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'utils.dart' show getDynamicLibrary;

final _nativeLib =
    getDynamicLibrary('facesdk', libShortName: 'fsdk', iOSStatic: true);

enum ImageMode { Grayscale8bit, Color24bit, Color32bit }

enum VideoCompressionType { MJPEG }

class Error implements Exception {
  static const Ok = 0;
  static const Failed = -1;
  static const NotActivated = -2;
  static const OutOfMemory = -3;
  static const InvalidArgument = -4;
  static const IoError = -5;
  static const ImageTooSmall = -6;
  static const FaceNotFound = -7;
  static const InsufficientBufferSize = -8;
  static const UnsupportedImageExtension = -9;
  static const CannotOpenFile = -10;
  static const CannotCreateFile = -11;
  static const BadFileFormat = -12;
  static const FileNotFound = -13;
  static const ConnectionClosed = -14;
  static const ConnectionFailed = -15;
  static const IpInitFailed = -16;
  static const NeedServerActivation = -17;
  static const IdNotFound = -18;
  static const AttributeNotDetected = -19;
  static const InsufficientTrackerMemoryLimit = -20;
  static const UnknownAttribute = -21;
  static const UnsupportedFileVersion = -22;
  static const SyntaxError = -23;
  static const ParameterNotFound = -24;
  static const InvalidTemplate = -25;
  static const UnsupportedTemplateVersion = -26;
  static const CameraIndexDoesNotExist = -27;
  static const PlatformNotLicensed = -28;

  int _code;
  Object? _info;
  String _callee;

  Error(int code, String callee, [Object? info = null])
      : _code = code,
        _callee = callee,
        _info = info;

  int get code => _code;

  String get callee => _callee;

  Object? get info => _info;
}

class FailedError extends Error {
  FailedError(String callee, [Object? info = null])
      : super(Error.Failed, callee, info);
}

class NotActivatedError extends Error {
  NotActivatedError(String callee, [Object? info = null])
      : super(Error.NotActivated, callee, info);
}

class OutOfMemoryError extends Error {
  OutOfMemoryError(String callee, [Object? info = null])
      : super(Error.OutOfMemory, callee, info);
}

class InvalidArgumentError extends Error {
  InvalidArgumentError(String callee, [Object? info = null])
      : super(Error.InvalidArgument, callee, info);
}

class IoError extends Error {
  IoError(String callee, [Object? info = null])
      : super(Error.IoError, callee, info);
}

class ImageTooSmallError extends Error {
  ImageTooSmallError(String callee, [Object? info = null])
      : super(Error.ImageTooSmall, callee, info);
}

class FaceNotFoundError extends Error {
  FaceNotFoundError(String callee, [Object? info = null])
      : super(Error.FaceNotFound, callee, info);
}

class InsufficientBufferSizeError extends Error {
  InsufficientBufferSizeError(String callee, [Object? info = null])
      : super(Error.InsufficientBufferSize, callee, info);
}

class UnsupportedImageExtensionError extends Error {
  UnsupportedImageExtensionError(String callee, [Object? info = null])
      : super(Error.UnsupportedImageExtension, callee, info);
}

class CannotOpenFileError extends Error {
  CannotOpenFileError(String callee, [Object? info = null])
      : super(Error.CannotOpenFile, callee, info);
}

class CannotCreateFileError extends Error {
  CannotCreateFileError(String callee, [Object? info = null])
      : super(Error.CannotCreateFile, callee, info);
}

class BadFileFormatError extends Error {
  BadFileFormatError(String callee, [Object? info = null])
      : super(Error.BadFileFormat, callee, info);
}

class FileNotFoundError extends Error {
  FileNotFoundError(String callee, [Object? info = null])
      : super(Error.FileNotFound, callee, info);
}

class ConnectionClosedError extends Error {
  ConnectionClosedError(String callee, [Object? info = null])
      : super(Error.ConnectionClosed, callee, info);
}

class ConnectionFailedError extends Error {
  ConnectionFailedError(String callee, [Object? info = null])
      : super(Error.ConnectionFailed, callee, info);
}

class IpInitFailedError extends Error {
  IpInitFailedError(String callee, [Object? info = null])
      : super(Error.IpInitFailed, callee, info);
}

class NeedServerActivationError extends Error {
  NeedServerActivationError(String callee, [Object? info = null])
      : super(Error.NeedServerActivation, callee, info);
}

class IdNotFoundError extends Error {
  IdNotFoundError(String callee, [Object? info = null])
      : super(Error.IdNotFound, callee, info);
}

class AttributeNotDetectedError extends Error {
  AttributeNotDetectedError(String callee, [Object? info = null])
      : super(Error.AttributeNotDetected, callee, info);
}

class InsufficientTrackerMemoryLimitError extends Error {
  InsufficientTrackerMemoryLimitError(String callee, [Object? info = null])
      : super(Error.InsufficientTrackerMemoryLimit, callee, info);
}

class UnknownAttributeError extends Error {
  UnknownAttributeError(String callee, [Object? info = null])
      : super(Error.UnknownAttribute, callee, info);
}

class UnsupportedFileVersionError extends Error {
  UnsupportedFileVersionError(String callee, [Object? info = null])
      : super(Error.UnsupportedFileVersion, callee, info);
}

class SyntaxError extends Error {
  SyntaxError(String callee, [Object? info = null])
      : super(Error.SyntaxError, callee, info);
}

class ParameterNotFoundError extends Error {
  ParameterNotFoundError(String callee, [Object? info = null])
      : super(Error.ParameterNotFound, callee, info);
}

class InvalidTemplateError extends Error {
  InvalidTemplateError(String callee, [Object? info = null])
      : super(Error.InvalidTemplate, callee, info);
}

class UnsupportedTemplateVersionError extends Error {
  UnsupportedTemplateVersionError(String callee, [Object? info = null])
      : super(Error.UnsupportedTemplateVersion, callee, info);
}

class CameraIndexDoesNotExistError extends Error {
  CameraIndexDoesNotExistError(String callee, [Object? info = null])
      : super(Error.CameraIndexDoesNotExist, callee, info);
}

class PlatformNotLicensedError extends Error {
  PlatformNotLicensedError(String callee, [Object? info = null])
      : super(Error.PlatformNotLicensed, callee, info);
}

final _ErrorTypes = {
  Error.Failed: (String callee, [Object? info = null]) =>
      FailedError(callee, info),
  Error.NotActivated: (String callee, [Object? info = null]) =>
      NotActivatedError(callee, info),
  Error.OutOfMemory: (String callee, [Object? info = null]) =>
      OutOfMemoryError(callee, info),
  Error.InvalidArgument: (String callee, [Object? info = null]) =>
      InvalidArgumentError(callee, info),
  Error.IoError: (String callee, [Object? info = null]) =>
      IoError(callee, info),
  Error.ImageTooSmall: (String callee, [Object? info = null]) =>
      ImageTooSmallError(callee, info),
  Error.FaceNotFound: (String callee, [Object? info = null]) =>
      FaceNotFoundError(callee, info),
  Error.InsufficientBufferSize: (String callee, [Object? info = null]) =>
      InsufficientBufferSizeError(callee, info),
  Error.UnsupportedImageExtension: (String callee, [Object? info = null]) =>
      UnsupportedImageExtensionError(callee, info),
  Error.CannotOpenFile: (String callee, [Object? info = null]) =>
      CannotOpenFileError(callee, info),
  Error.CannotCreateFile: (String callee, [Object? info = null]) =>
      CannotCreateFileError(callee, info),
  Error.BadFileFormat: (String callee, [Object? info = null]) =>
      BadFileFormatError(callee, info),
  Error.FileNotFound: (String callee, [Object? info = null]) =>
      FileNotFoundError(callee, info),
  Error.ConnectionClosed: (String callee, [Object? info = null]) =>
      ConnectionClosedError(callee, info),
  Error.ConnectionFailed: (String callee, [Object? info = null]) =>
      ConnectionFailedError(callee, info),
  Error.IpInitFailed: (String callee, [Object? info = null]) =>
      IpInitFailedError(callee, info),
  Error.NeedServerActivation: (String callee, [Object? info = null]) =>
      NeedServerActivationError(callee, info),
  Error.IdNotFound: (String callee, [Object? info = null]) =>
      IdNotFoundError(callee, info),
  Error.AttributeNotDetected: (String callee, [Object? info = null]) =>
      AttributeNotDetectedError(callee, info),
  Error.InsufficientTrackerMemoryLimit: (String callee,
          [Object? info = null]) =>
      InsufficientTrackerMemoryLimitError(callee, info),
  Error.UnknownAttribute: (String callee, [Object? info = null]) =>
      UnknownAttributeError(callee, info),
  Error.UnsupportedFileVersion: (String callee, [Object? info = null]) =>
      UnsupportedFileVersionError(callee, info),
  Error.SyntaxError: (String callee, [Object? info = null]) =>
      SyntaxError(callee, info),
  Error.ParameterNotFound: (String callee, [Object? info = null]) =>
      ParameterNotFoundError(callee, info),
  Error.InvalidTemplate: (String callee, [Object? info = null]) =>
      InvalidTemplateError(callee, info),
  Error.UnsupportedTemplateVersion: (String callee, [Object? info = null]) =>
      UnsupportedTemplateVersionError(callee, info),
  Error.CameraIndexDoesNotExist: (String callee, [Object? info = null]) =>
      CameraIndexDoesNotExistError(callee, info),
  Error.PlatformNotLicensed: (String callee, [Object? info = null]) =>
      PlatformNotLicensedError(callee, info)
};

const FacialFeatureCount = 70;

class Freeable {
  void free() {}
}

class _NativePointer<T extends NativeType> extends Freeable {
  final bool _owner;
  final Pointer<T> pointer;

  _NativePointer(this.pointer, [this._owner = false]);

  factory _NativePointer.fromAddress(int address) {
    return _NativePointer(Pointer<T>.fromAddress(address));
  }

  factory _NativePointer.allocate(int count) {
    return _NativePointer(malloc.allocate<T>(count), true);
  }

  @override
  void free() {
    if (_owner) {
      malloc.free(pointer);
    }
  }
}

class _AutoNativePointer<T extends NativeType> extends _NativePointer<T> {
  final Finalizer<Pointer<T>> _finalizer =
      Finalizer((pointer) => malloc.free(pointer));

  _AutoNativePointer(Pointer<T> pointer) : super(pointer) {
    _finalizer.attach(this, pointer, detach: this);
  }

  factory _AutoNativePointer.allocate(int count) {
    return _AutoNativePointer(malloc.allocate<T>(count));
  }

  @override
  void free() {
    _finalizer.detach(this);
    super.free();
  }
}

class BufferInfo {
  final int _dataAddress;
  final int _lengthAddress;

  BufferInfo(this._dataAddress, this._lengthAddress);
}

class DataBuffer extends ListBase<int> implements Freeable {
  late Uint8List _data;
  late _NativePointer<Int32> _length;
  late _NativePointer<Uint8> _nativeData;

  DataBuffer.allocate(int length) {
    _length = _AutoNativePointer<Int32>.allocate(sizeOf<Int32>())
      ..pointer.value = length;
    _nativeData = _AutoNativePointer<Uint8>.allocate(sizeOf<Uint8>() * length);
    _data = _nativeData.pointer.asTypedList(length);
  }

  factory DataBuffer._allocate(int length) {
    return DataBuffer.allocate(length);
  }

  DataBuffer.fromPointers(Pointer<Uint8> nativeData, Pointer<Int32> length) {
    _length = _NativePointer<Int32>(length);
    _nativeData = _NativePointer<Uint8>(nativeData);
    _data = _nativeData.pointer.asTypedList(_length.pointer.value);
  }

  DataBuffer.fromAddresses(int nativeDataAddress, int lengthAddress) {
    _length = _NativePointer<Int32>.fromAddress(lengthAddress);
    _nativeData = _NativePointer<Uint8>.fromAddress(nativeDataAddress);
    _data = _nativeData.pointer.asTypedList(_length.pointer.value);
  }

  factory DataBuffer.fromInfo(BufferInfo info) {
    return DataBuffer.fromAddresses(info._dataAddress, info._lengthAddress);
  }

  factory DataBuffer.fromByteBuffer(ByteBuffer buffer) {
    final result = DataBuffer.allocate(buffer.lengthInBytes);
    result._data.setRange(0, buffer.lengthInBytes, buffer.asUint8List());
    return result;
  }

  int get capacity => _data.length;
  int get length => _length.pointer.value;
  Uint8List get data => _data;

  void set length(int newLength) {
    if (newLength <= capacity) {
      _length.pointer.value = newLength;
      return;
    }

    if (!_nativeData._owner) {
      throw UnsupportedError("Cannot reallocate non owned pointers");
    }

    final newNativeData =
        _AutoNativePointer<Uint8>.allocate(sizeOf<Uint8>() * newLength);
    final newData = newNativeData.pointer.asTypedList(newLength);
    newData.setRange(0, length, _data);

    _nativeData.free();

    _data = newData;
    _nativeData = newNativeData;
    _length.pointer.value = newLength;
  }

  Pointer<Uint8> get pointer => _nativeData.pointer;
  Pointer<Int32> get _lengthPointer => _length.pointer;

  int operator [](int index) => _data[index];
  void operator []=(int index, int value) => _data[index] = value;

  BufferInfo getInfo() {
    return BufferInfo(pointer.address, _lengthPointer.address);
  }

  void free() {
    _nativeData.free();
    _length.free();
  }
}

class Int64Buffer extends ListBase<int> implements Freeable {
  late Int64List _data;
  late _NativePointer<Int64> _length;
  late _NativePointer<Int64> _nativeData;

  Int64Buffer.allocate(int length) {
    _length = _AutoNativePointer<Int64>.allocate(sizeOf<Int64>())
      ..pointer.value = length;
    _nativeData = _AutoNativePointer<Int64>.allocate(sizeOf<Int64>() * length);
    _data = _nativeData.pointer.asTypedList(length);
  }

  factory Int64Buffer._allocate(int length) {
    return Int64Buffer.allocate(length);
  }

  Int64Buffer.fromPointers(Pointer<Int64> nativeData, Pointer<Int64> length) {
    _length = _NativePointer<Int64>(length);
    _nativeData = _NativePointer<Int64>(nativeData);
    _data = _nativeData.pointer.asTypedList(_length.pointer.value);
  }

  Int64Buffer.fromAddresses(int nativeDataAddress, int lengthAddress) {
    _length = _NativePointer<Int64>.fromAddress(lengthAddress);
    _nativeData = _NativePointer<Int64>.fromAddress(nativeDataAddress);
    _data = _nativeData.pointer.asTypedList(_length.pointer.value);
  }

  factory Int64Buffer.fromInfo(BufferInfo info) {
    return Int64Buffer.fromAddresses(info._dataAddress, info._lengthAddress);
  }

  factory Int64Buffer.fromByteBuffer(ByteBuffer buffer) {
    final length = buffer.lengthInBytes ~/ sizeOf<Int64>();
    final result = Int64Buffer.allocate(length);
    result._data.setRange(0, length, buffer.asInt64List());
    return result;
  }

  int get capacity => _data.length;
  int get length => _length.pointer.value;

  void set length(int newLength) {
    if (newLength <= capacity) {
      _length.pointer.value = newLength;
      return;
    }

    if (!_nativeData._owner) {
      throw UnsupportedError("Cannot reallocate non owned pointers");
    }

    final newNativeData =
        _AutoNativePointer<Int64>.allocate(sizeOf<Int64>() * newLength);
    final newData = newNativeData.pointer.asTypedList(newLength);
    newData.setRange(0, length, _data);

    _nativeData.free();

    _data = newData;
    _nativeData = newNativeData;
    _length.pointer.value = newLength;
  }

  Pointer<Int64> get pointer => _nativeData.pointer;
  Pointer<Int64> get _lengthPointer => _length.pointer;

  int operator [](int index) => _data[index];
  void operator []=(int index, int value) => _data[index] = value;

  BufferInfo getInfo() {
    return BufferInfo(pointer.address, _lengthPointer.address);
  }

  void free() {
    _nativeData.free();
    _length.free();
  }
}

class _FacePosition extends Struct {
  @Int32()
  external int xc;

  @Int32()
  external int yc;

  @Int32()
  external int w;

  @Int32()
  external int padding;

  @Double()
  external double angle;
}

class FacePosition extends Freeable {
  final _NativePointer<_FacePosition> _nativePointer;

  Pointer<_FacePosition> get pointer => _nativePointer.pointer;

  int get xc => pointer.ref.xc;
  int get yc => pointer.ref.yc;
  int get w => pointer.ref.w;

  void set xc(int value) => pointer.ref.xc = value;
  void set yc(int value) => pointer.ref.yc = value;
  void set w(int value) => pointer.ref.w = value;

  double get angle => pointer.ref.angle;
  void set angle(double value) => pointer.ref.angle = value;

  FacePosition(this._nativePointer);

  factory FacePosition.allocate() {
    return FacePosition(
        _AutoNativePointer<_FacePosition>.allocate(sizeOf<_FacePosition>()));
  }

  factory FacePosition._allocate() {
    return FacePosition.allocate();
  }

  factory FacePosition.fromPointer(Pointer<_FacePosition> pointer) {
    return FacePosition(_NativePointer<_FacePosition>(pointer));
  }

  void free() {
    _nativePointer.free();
  }
}

class FacePositions extends ListBase<FacePosition> implements Freeable {
  late int _capacity;
  late _NativePointer<Int32> _length;
  late _NativePointer<_FacePosition> _nativeData;

  FacePositions.allocate(int length) {
    _capacity = length;
    _length = _AutoNativePointer<Int32>.allocate(sizeOf<Int32>())
      ..pointer.value = length;
    _nativeData = _AutoNativePointer<_FacePosition>.allocate(
        sizeOf<_FacePosition>() * length);
  }

  factory FacePositions._allocate(int length) {
    return FacePositions.allocate(length);
  }

  FacePositions.fromPointers(
      Pointer<_FacePosition> nativeData, Pointer<Int32> length) {
    _length = _NativePointer<Int32>(length);
    _nativeData = _NativePointer<_FacePosition>(nativeData);
    _capacity = this.length;
  }

  FacePositions.fromAddresses(int nativeDataAddress, int lengthAddress) {
    _length = _NativePointer<Int32>.fromAddress(lengthAddress);
    _nativeData = _NativePointer<_FacePosition>.fromAddress(nativeDataAddress);
    _capacity = length;
  }

  factory FacePositions.fromInfo(BufferInfo info) {
    return FacePositions.fromAddresses(info._dataAddress, info._lengthAddress);
  }

  int get capacity => _capacity;
  int get length => _length.pointer.value;
  Pointer<_FacePosition> get pointer => _nativeData.pointer;
  Pointer<Int32> get _lengthPointer => _length.pointer;

  void set length(int newLength) {
    if (newLength <= _capacity) {
      _length.pointer.value = newLength;
      return;
    }

    if (!_nativeData._owner) {
      throw UnsupportedError("Cannot reallocate non owned pointers");
    }

    final _newNativeData = _AutoNativePointer<_FacePosition>.allocate(
        sizeOf<_FacePosition>() * newLength);
    for (int i = 0; i < min(length, newLength); ++i) {
      _assign(_newNativeData.pointer[i], _nativeData.pointer[i]);
    }

    _nativeData.free();

    _nativeData = _newNativeData;
    _length.pointer.value = newLength;
    _capacity = newLength;
  }

  void _assign(_FacePosition a, _FacePosition b) {
    a.xc = b.xc;
    a.yc = b.yc;
    a.w = b.w;
    a.padding = b.padding;
    a.angle = b.angle;
  }

  FacePosition operator [](int index) =>
      FacePosition.fromPointer(pointer.elementAt(index));

  void operator []=(int index, FacePosition pos) =>
      _assign(_nativeData.pointer[index], pos.pointer.ref);

  BufferInfo getInfo() {
    return BufferInfo(_nativeData.pointer.address, _length.pointer.address);
  }

  void free() {
    _length.free();
    _nativeData.free();
  }
}

class Point extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}

class Eyes extends Freeable {
  final _NativePointer<Point> _nativePointer;

  Eyes(this._nativePointer);

  factory Eyes.allocate() {
    return Eyes(_AutoNativePointer.allocate(sizeOf<Point>() * 2));
  }

  factory Eyes._allocate() {
    return Eyes.allocate();
  }

  factory Eyes.fromPointer(Pointer<Point> pointer) {
    return Eyes(_NativePointer<Point>(pointer));
  }

  factory Eyes.fromAddress(int address) {
    return Eyes(_NativePointer<Point>.fromAddress(address));
  }

  Pointer<Point> get pointer => _nativePointer.pointer;

  Point get left => pointer[0];
  Point get right => pointer[1];

  void set left(Point point) => _setPoint(0, point);
  void set right(Point point) => _setPoint(1, point);

  void _setPoint(int index, Point point) {
    final value = pointer[index];
    value.x = point.x;
    value.y = point.y;
  }

  @override
  void free() {
    _nativePointer.free();
  }
}

class FacialFeatures extends ListBase<Point> implements Freeable {
  static const LeftEye = 0;
  static const RightEye = 1;
  static const NoseTip = 2;
  static const MouthRightCorner = 3;
  static const MouthLeftCorner = 4;
  static const FaceContour2 = 5;
  static const FaceContour12 = 6;
  static const FaceContour1 = 7;
  static const FaceContour13 = 8;
  static const ChinLeft = 9;
  static const ChinRight = 10;
  static const ChinBottom = 11;
  static const LeftEyebrowOuterCorner = 12;
  static const LeftEyebrowInnerCorner = 13;
  static const RightEyebrowInnerCorner = 14;
  static const RightEyebrowOuterCorner = 15;
  static const LeftEyebrowMiddle = 16;
  static const RightEyebrowMiddle = 17;
  static const LeftEyebrowMiddleLeft = 18;
  static const LeftEyebrowMiddleRight = 19;
  static const RightEyebrowMiddleLeft = 20;
  static const RightEyebrowMiddleRight = 21;
  static const NoseBridge = 22;
  static const LeftEyeOuterCorner = 23;
  static const LeftEyeInnerCorner = 24;
  static const RightEyeInnerCorner = 25;
  static const RightEyeOuterCorner = 26;
  static const LeftEyeLowerLine2 = 27;
  static const LeftEyeUpperLine2 = 28;
  static const LeftEyeLeftIrisCorner = 29;
  static const LeftEyeRightIrisCorner = 30;
  static const RightEyeLowerLine2 = 31;
  static const RightEyeUpperLine2 = 32;
  static const RightEyeLeftIrisCorner = 33;
  static const RightEyeRightIrisCorner = 34;
  static const LeftEyeUpperLine1 = 35;
  static const LeftEyeUpperLine3 = 36;
  static const LeftEyeLowerLine3 = 37;
  static const LeftEyeLowerLine1 = 38;
  static const RightEyeUpperLine3 = 39;
  static const RightEyeUpperLine1 = 40;
  static const RightEyeLowerLine1 = 41;
  static const RightEyeLowerLine3 = 42;
  static const NoseLeftWing = 43;
  static const NoseRightWing = 44;
  static const NoseLeftWingOuter = 45;
  static const NoseRightWingOuter = 46;
  static const NoseLeftWingLower = 47;
  static const NoseRightWingLower = 48;
  static const NoseBottom = 49;
  static const NasolabialFoldLeftUpper = 50;
  static const NasolabialFoldRightUpper = 51;
  static const NasolabialFoldLeftLower = 52;
  static const NasolabialFoldRightLower = 53;
  static const MouthTop = 54;
  static const MouthBottom = 55;
  static const MouthLeftTop = 56;
  static const MouthRightTop = 57;
  static const MouthLeftBottom = 58;
  static const MouthRightBottom = 59;
  static const MouthLeftTopInner = 60;
  static const MouthTopInner = 61;
  static const MouthRightTopInner = 62;
  static const MouthLeftBottomInner = 63;
  static const MouthBottomInner = 64;
  static const MouthRightBottomInner = 65;
  static const FaceContour14 = 66;
  static const FaceContour15 = 67;
  static const FaceContour16 = 68;
  static const FaceContour17 = 69;

  _NativePointer<Point> _nativePointer;

  FacialFeatures(this._nativePointer);

  factory FacialFeatures.allocate() {
    return FacialFeatures(_AutoNativePointer<Point>.allocate(
        sizeOf<Point>() * FacialFeatureCount));
  }

  factory FacialFeatures._allocate() {
    return FacialFeatures.allocate();
  }

  factory FacialFeatures.fromPointer(Pointer<Point> pointer) {
    return FacialFeatures(_NativePointer<Point>(pointer));
  }

  factory FacialFeatures.fromAddress(int address) {
    return FacialFeatures(_NativePointer<Point>.fromAddress(address));
  }

  int get length => FacialFeatureCount;

  void set length(int newLength) {
    throw UnsupportedError('Cannot resize FacialFeatures object');
  }

  Pointer<Point> get pointer => _nativePointer.pointer;

  Point operator [](int index) => pointer[index];

  void operator []=(int index, Point point) {
    final value = pointer[index];
    value.x = point.x;
    value.y = point.y;
  }

  Eyes get eyes => Eyes.fromPointer(pointer);

  void free() {
    _nativePointer.free();
  }
}

class FaceTemplate extends Freeable {
  final DataBuffer _buffer;

  FaceTemplate(this._buffer);

  factory FaceTemplate.allocate() {
    return FaceTemplate(DataBuffer.allocate(1040));
  }

  factory FaceTemplate._allocate() {
    return FaceTemplate.allocate();
  }

  DataBuffer get buffer => _buffer;
  Pointer<Uint8> get pointer => _buffer.pointer;

  double match(FaceTemplate other) {
    return MatchFaces(this, other);
  }

  void free() {
    _buffer.free();
  }
}

class ExtractedFace {
  final Image image;
  final FacialFeatures features;

  ExtractedFace(this.image, this.features);
}

typedef _getInfoFunction = Object Function();

void _checkErrorCode(int code, String callee,
    [_getInfoFunction? getInfo = null]) {
  if (code == Error.Ok) {
    return;
  }

  final info = getInfo?.call();

  if (!_ErrorTypes.containsKey(code)) {
    throw Error(code, callee, info);
  }

  throw _ErrorTypes[code]!(callee, info);
}

class Image extends Freeable {
  late _NativePointer<Uint32> _native;

  Image._fromNativePointer(_NativePointer<Uint32> pointer) {
    _native = pointer;
  }

  factory Image._allocate() {
    return Image._fromNativePointer(
        _AutoNativePointer<Uint32>.allocate(sizeOf<Uint32>()));
  }

  factory Image.fromHandle(int handle) {
    return Image._fromNativePointer(
        _AutoNativePointer<Uint32>.allocate(sizeOf<Uint32>())
          ..pointer.value = handle);
  }

  factory Image.fromPointer(Pointer<Uint32> pointer) {
    return Image._fromNativePointer(_NativePointer<Uint32>(pointer));
  }

  int get handle => _native.pointer.value;
  Pointer<Uint32> get pointer => _native.pointer;

  factory Image({Image? image = null}) {
    return CreateEmptyImage(image: image);
  }

  @override
  void free({bool freePointer = true}) {
    FreeImage(this);
    if (freePointer) {
      _native.free();
    }
  }

  factory Image.fromFile(String fileName, {Image? image = null}) {
    return LoadImageFromFile(fileName, image: image);
  }

  factory Image.fromFileWithAlpha(String fileName, {Image? image = null}) {
    return LoadImageFromFileWithAlpha(fileName, image: image);
  }

  void saveToFile(String fileName) {
    SaveImageToFile(this, fileName);
  }

  int get width {
    return GetImageWidth(this);
  }

  int get height {
    return GetImageHeight(this);
  }

  factory Image.fromBuffer(DataBuffer buffer, int width, int height,
      int scanLine, ImageMode imageMode,
      {Image? image = null}) {
    return LoadImageFromBuffer(buffer, width, height, scanLine, imageMode,
        image: image);
  }

  int getBufferSize(ImageMode imageMode) {
    return GetImageBufferSize(this, imageMode);
  }

  DataBuffer saveToBuffer(ImageMode imageMode, {DataBuffer? buffer = null}) {
    return SaveImageToBuffer(this, imageMode, buffer: buffer);
  }

  factory Image.fromJpegBuffer(DataBuffer buffer, {Image? image = null}) {
    return LoadImageFromJpegBuffer(buffer, image: image);
  }

  factory Image.fromPngBuffer(DataBuffer buffer, {Image? image = null}) {
    return LoadImageFromPngBuffer(buffer, image: image);
  }

  factory Image.fromPngBufferWithAlpha(DataBuffer buffer,
      {Image? image = null}) {
    return LoadImageFromPngBufferWithAlpha(buffer, image: image);
  }

  FacePosition detectFace({FacePosition? facePosition = null}) {
    return DetectFace(this, facePosition: facePosition);
  }

  FacePositions detectMultipleFaces(
      {FacePositions? faces = null, int maxSize = 256}) {
    return DetectMultipleFaces(this, faces: faces, maxSize: maxSize);
  }

  FacialFeatures detectFacialFeatures({FacialFeatures? facialFeatures = null}) {
    return DetectFacialFeatures(this, facialFeatures: facialFeatures);
  }

  FacialFeatures detectFacialFeaturesInRegion(FacePosition facePosition,
      {FacialFeatures? facialFeatures = null}) {
    return DetectFacialFeaturesInRegion(this, facePosition,
        facialFeatures: facialFeatures);
  }

  Eyes detectEyes({Eyes? eyes = null}) {
    return DetectEyes(this, eyes: eyes);
  }

  Eyes detectEyesInRegion(FacePosition facePosition, {Eyes? eyes = null}) {
    return DetectEyesInRegion(this, facePosition, eyes: eyes);
  }

  Image copy() {
    return CopyImage(this);
  }

  Image resize(double ratio) {
    return ResizeImage(this, ratio);
  }

  Image rotate90(int multiplier) {
    return RotateImage90(this, multiplier);
  }

  Image rotate(double angle) {
    return RotateImage(this, angle);
  }

  Image rotateCenter(double angle, double xCenter, double yCenter) {
    return RotateImageCenter(this, angle, xCenter, yCenter);
  }

  Image copyRect(int x1, int y1, int x2, int y2) {
    return CopyRect(this, x1, y1, x2, y2);
  }

  Image copyRectReplicateBorder(int x1, int y1, int x2, int y2) {
    return CopyRectReplicateBorder(this, x1, y1, x2, y2);
  }

  void mirror(bool useVerticalMirroringInsteadOfHorizontal) {
    MirrorImage(this, useVerticalMirroringInsteadOfHorizontal);
  }

  ExtractedFace extractFace(
      FacialFeatures facialFeatures, int width, int height,
      {Image? extractedFaceImage = null,
      FacialFeatures? resizedFeatures = null}) {
    return ExtractFaceImage(this, facialFeatures, width, height,
        extractedFaceImage: extractedFaceImage,
        resizedFeatures: resizedFeatures);
  }

  FaceTemplate getFaceTemplate({FaceTemplate? faceTemplate = null}) {
    return GetFaceTemplate(this, faceTemplate: faceTemplate);
  }

  FaceTemplate getFaceTemplateInRegion(FacePosition facePosition,
      {FaceTemplate? faceTemplate = null}) {
    return GetFaceTemplateInRegion(this, facePosition,
        faceTemplate: faceTemplate);
  }

  FaceTemplate getFaceTemplateUsingFeatures(FacialFeatures facialFeatures,
      {FaceTemplate? faceTemplate = null}) {
    return GetFaceTemplateUsingFeatures(this, facialFeatures,
        faceTemplate: faceTemplate);
  }

  FaceTemplate getFaceTemplateUsingEyes(Eyes eyeCoords,
      {FaceTemplate? faceTemplate = null}) {
    return GetFaceTemplateUsingEyes(this, eyeCoords,
        faceTemplate: faceTemplate);
  }

  String detectFacialAttributeUsingFeatures(
      FacialFeatures facialFeatures, String attributeName,
      {int maxSizeInBytes = 256}) {
    return DetectFacialAttributeUsingFeatures(
        this, facialFeatures, attributeName,
        maxSizeInBytes: maxSizeInBytes);
  }
}

class Camera extends Freeable {
  late _NativePointer<Int32> _native;

  Camera._fromNativePointer(_NativePointer<Int32> pointer) {
    _native = pointer;
  }

  factory Camera._allocate() {
    return Camera._fromNativePointer(
        _AutoNativePointer<Int32>.allocate(sizeOf<Int32>()));
  }

  factory Camera.fromHandle(int handle) {
    return Camera._fromNativePointer(
        _AutoNativePointer<Int32>.allocate(sizeOf<Int32>())
          ..pointer.value = handle);
  }

  factory Camera.fromPointer(Pointer<Int32> pointer) {
    return Camera._fromNativePointer(_NativePointer<Int32>(pointer));
  }

  int get handle => _native.pointer.value;
  Pointer<Int32> get pointer => _native.pointer;

  factory Camera.openIP(VideoCompressionType compressionType, String url,
      String username, String password, int timeoutSeconds,
      {Camera? cameraHandle = null}) {
    return OpenIPVideoCamera(
        compressionType, url, username, password, timeoutSeconds,
        cameraHandle: cameraHandle);
  }

  void close() {
    CloseVideoCamera(this);
  }

  Image grabFrame({Image? image = null}) {
    return GrabFrame(this, image: image);
  }
}

class Tracker extends Freeable {
  late _NativePointer<Uint32> _native;

  Tracker._fromNativePointer(_NativePointer<Uint32> pointer) {
    _native = pointer;
  }

  factory Tracker._allocate() {
    return Tracker._fromNativePointer(
        _AutoNativePointer<Uint32>.allocate(sizeOf<Uint32>()));
  }

  factory Tracker.fromHandle(int handle) {
    return Tracker._fromNativePointer(
        _AutoNativePointer<Uint32>.allocate(sizeOf<Uint32>())
          ..pointer.value = handle);
  }

  factory Tracker.fromPointer(Pointer<Uint32> pointer) {
    return Tracker._fromNativePointer(_NativePointer<Uint32>(pointer));
  }

  int get handle => _native.pointer.value;
  Pointer<Uint32> get pointer => _native.pointer;

  factory Tracker({Tracker? tracker = null}) {
    return CreateTracker(tracker: tracker);
  }

  @override
  void free({bool freePointer = true}) {
    FreeTracker(this);
    if (freePointer) {
      _native.free();
    }
  }

  void clear() {
    ClearTracker(this);
  }

  void setParameter(String parameterName, String parameterValue) {
    SetTrackerParameter(this, parameterName, parameterValue);
  }

  void setMultipleParameters(Map<String, dynamic> parameters) {
    SetTrackerMultipleParameters(this, parameters);
  }

  String getParameter(String parameterName, {int maxSizeInBytes = 256}) {
    return GetTrackerParameter(this, parameterName,
        maxSizeInBytes: maxSizeInBytes);
  }

  Int64Buffer feedFrame(int cameraIdx, Image image,
      {Int64Buffer? ids = null, int maxSize = 256}) {
    return FeedFrame(this, cameraIdx, image, ids: ids, maxSize: maxSize);
  }

  Eyes getEyes(int cameraIdx, int id, {Eyes? eyes = null}) {
    return GetTrackerEyes(this, cameraIdx, id, eyes: eyes);
  }

  FacialFeatures getFacialFeatures(int cameraIdx, int id,
      {FacialFeatures? facialFeatures = null}) {
    return GetTrackerFacialFeatures(this, cameraIdx, id,
        facialFeatures: facialFeatures);
  }

  FacePosition getFacePosition(int cameraIdx, int id,
      {FacePosition? facePosition = null}) {
    return GetTrackerFacePosition(this, cameraIdx, id,
        facePosition: facePosition);
  }

  void lockID(int id) {
    LockID(this, id);
  }

  void unlockID(int id) {
    UnlockID(this, id);
  }

  void purgeID(int id) {
    PurgeID(this, id);
  }

  void setName(int id, String name) {
    SetName(this, id, name);
  }

  String getName(int id, {int maxSizeInBytes = 256}) {
    return GetName(this, id, maxSizeInBytes: maxSizeInBytes);
  }

  String getAllNames(int id, {int maxSizeInBytes = 256}) {
    return GetAllNames(this, id, maxSizeInBytes: maxSizeInBytes);
  }

  int getIDReassignment(int id) {
    return GetIDReassignment(this, id);
  }

  int getSimilarIDCount(int id) {
    return GetSimilarIDCount(this, id);
  }

  Int64Buffer getSimilarIDList(int id, {Int64Buffer? similarIDList = null}) {
    return GetSimilarIDList(this, id, similarIDList: similarIDList);
  }

  void saveToFile(String fileName) {
    SaveTrackerMemoryToFile(this, fileName);
  }

  factory Tracker.fromFile(String fileName, {Tracker? tracker = null}) {
    return LoadTrackerMemoryFromFile(fileName, tracker: tracker);
  }

  int get bufferSize {
    return GetTrackerMemoryBufferSize(this);
  }

  DataBuffer saveToBuffer({DataBuffer? buffer = null}) {
    return SaveTrackerMemoryToBuffer(this, buffer: buffer);
  }

  factory Tracker.fromBuffer(DataBuffer buffer, {Tracker? tracker = null}) {
    return LoadTrackerMemoryFromBuffer(buffer, tracker: tracker);
  }

  String getFacialAttribute(int cameraIdx, int id, String attributeName,
      {int maxSizeInBytes = 256}) {
    return GetTrackerFacialAttribute(this, cameraIdx, id, attributeName,
        maxSizeInBytes: maxSizeInBytes);
  }
}

class _ActivateLibraryWrapper {
  late int Function(Pointer<Utf8>) _func;

  _ActivateLibraryWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
            'FSDK_ActivateLibrary')
        .asFunction();
  }

  void call(String licenseKey) {
    final var1 = licenseKey.toNativeUtf8();
    try {
      _checkErrorCode(_func(var1), 'ActivateLibrary');
    } finally {
      malloc.free(var1);
    }
  }
}

final ActivateLibrary = _ActivateLibraryWrapper();

class _GetHardware_IDWrapper {
  late int Function(Pointer<Utf8>) _func;

  _GetHardware_IDWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
            'FSDK_GetHardware_ID')
        .asFunction();
  }

  String call({int maxSize = 256}) {
    final var1 = malloc.allocate<Utf8>(maxSize);
    try {
      _checkErrorCode(_func(var1), 'GetHardware_ID');
      return var1.toDartString();
    } finally {
      malloc.free(var1);
    }
  }
}

final GetHardware_ID = _GetHardware_IDWrapper();

class _GetLicenseInfoWrapper {
  late int Function(Pointer<Utf8>) _func;

  _GetLicenseInfoWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
            'FSDK_GetLicenseInfo')
        .asFunction();
  }

  String call({int maxSize = 256}) {
    final var1 = malloc.allocate<Utf8>(maxSize);
    try {
      _checkErrorCode(_func(var1), 'GetLicenseInfo');
      return var1.toDartString();
    } finally {
      malloc.free(var1);
    }
  }
}

final GetLicenseInfo = _GetLicenseInfoWrapper();

class _GetVersionInfoWrapper {
  late int Function(Pointer<Pointer<Utf8>>) _func;

  _GetVersionInfoWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Pointer<Utf8>>)>>(
          'FSDK_GetVersionInfo',
        )
        .asFunction();
  }

  String call() {
    final versionInfo = malloc.allocate<Pointer<Utf8>>(sizeOf<Pointer<Utf8>>());
    try {
      _checkErrorCode(_func(versionInfo), 'GetVersionInfo');
      return versionInfo.value.toDartString();
    } finally {
      malloc.free(versionInfo);
    }
  }
}

final GetVersionInfo = _GetVersionInfoWrapper();

class _SetNumThreadsWrapper {
  late int Function(int) _func;

  _SetNumThreadsWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Int32)>>('FSDK_SetNumThreads')
        .asFunction();
  }

  void call(int num) {
    _checkErrorCode(_func(num), 'SetNumThreads');
  }
}

final SetNumThreads = _SetNumThreadsWrapper();

class _GetNumThreadsWrapper {
  late int Function(Pointer<Int32>) _func;

  _GetNumThreadsWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Int32>)>>(
            'FSDK_GetNumThreads')
        .asFunction();
  }

  int call() {
    final var1 = malloc.allocate<Int32>(sizeOf<Int32>() * 1);
    try {
      _checkErrorCode(_func(var1), 'GetNumThreads');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetNumThreads = _GetNumThreadsWrapper();

class _InitializeWrapper {
  late int Function() _func;

  _InitializeWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function()>>('FSDK_Initialize')
        .asFunction();
  }

  void call() {
    _checkErrorCode(_func(), 'Initialize');
  }
}

final Initialize = _InitializeWrapper();

class _FinalizeWrapper {
  late int Function() _func;

  _FinalizeWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function()>>('FSDK_Finalize')
        .asFunction();
  }

  void call() {
    _checkErrorCode(_func(), 'Finalize');
  }
}

final Finalize = _FinalizeWrapper();

class _CreateEmptyImageWrapper {
  late int Function(Pointer<Uint32>) _func;

  _CreateEmptyImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Uint32>)>>(
            'FSDK_CreateEmptyImage')
        .asFunction();
  }

  Image call({Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(_func(image.pointer), 'CreateEmptyImage');
    return image;
  }
}

final CreateEmptyImage = _CreateEmptyImageWrapper();

class _FreeImageWrapper {
  late int Function(int) _func;

  _FreeImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32)>>('FSDK_FreeImage')
        .asFunction();
  }

  void call(Image image) {
    _checkErrorCode(_func(image.handle), 'FreeImage');
  }
}

final FreeImage = _FreeImageWrapper();

class _LoadImageFromFileWrapper {
  late int Function(Pointer<Uint32>, Pointer<Utf8>) _func;

  _LoadImageFromFileWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Uint32>, Pointer<Utf8>)>>(
            'FSDK_LoadImageFromFile')
        .asFunction();
  }

  Image call(String fileName, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    final var1 = fileName.toNativeUtf8();
    try {
      _checkErrorCode(_func(image.pointer, var1), 'LoadImageFromFile');
      return image;
    } finally {
      malloc.free(var1);
    }
  }
}

final LoadImageFromFile = _LoadImageFromFileWrapper();

class _LoadImageFromFileWithAlphaWrapper {
  late int Function(Pointer<Uint32>, Pointer<Utf8>) _func;

  _LoadImageFromFileWithAlphaWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Uint32>, Pointer<Utf8>)>>(
            'FSDK_LoadImageFromFileWithAlpha')
        .asFunction();
  }

  Image call(String fileName, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    final var1 = fileName.toNativeUtf8();
    try {
      _checkErrorCode(_func(image.pointer, var1), 'LoadImageFromFileWithAlpha');
      return image;
    } finally {
      malloc.free(var1);
    }
  }
}

final LoadImageFromFileWithAlpha = _LoadImageFromFileWithAlphaWrapper();

class _SaveImageToFileWrapper {
  late int Function(int, Pointer<Utf8>) _func;

  _SaveImageToFileWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Utf8>)>>(
            'FSDK_SaveImageToFile')
        .asFunction();
  }

  void call(Image image, String fileName) {
    final var1 = fileName.toNativeUtf8();
    try {
      _checkErrorCode(_func(image.handle, var1), 'SaveImageToFile');
    } finally {
      malloc.free(var1);
    }
  }
}

final SaveImageToFile = _SaveImageToFileWrapper();

class _SetJpegCompressionQualityWrapper {
  late int Function(int) _func;

  _SetJpegCompressionQualityWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Int32)>>(
            'FSDK_SetJpegCompressionQuality')
        .asFunction();
  }

  void call(int quality) {
    _checkErrorCode(_func(quality), 'SetJpegCompressionQuality');
  }
}

final SetJpegCompressionQuality = _SetJpegCompressionQualityWrapper();

class _GetImageWidthWrapper {
  late int Function(int, Pointer<Int32>) _func;

  _GetImageWidthWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Int32>)>>(
            'FSDK_GetImageWidth')
        .asFunction();
  }

  int call(Image image) {
    final var1 = malloc.allocate<Int32>(sizeOf<Int32>() * 1);
    try {
      _checkErrorCode(_func(image.handle, var1), 'GetImageWidth');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetImageWidth = _GetImageWidthWrapper();

class _GetImageHeightWrapper {
  late int Function(int, Pointer<Int32>) _func;

  _GetImageHeightWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Int32>)>>(
            'FSDK_GetImageHeight')
        .asFunction();
  }

  int call(Image image) {
    final var1 = malloc.allocate<Int32>(sizeOf<Int32>() * 1);
    try {
      _checkErrorCode(_func(image.handle, var1), 'GetImageHeight');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetImageHeight = _GetImageHeightWrapper();

class _LoadImageFromBufferWrapper {
  late int Function(Pointer<Uint32>, Pointer<Uint8>, int, int, int, int) _func;

  _LoadImageFromBufferWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint32>, Pointer<Uint8>, Int32, Int32,
                    Int32, Int32)>>('FSDK_LoadImageFromBuffer')
        .asFunction();
  }

  Image call(DataBuffer buffer, int width, int height, int scanLine,
      ImageMode imageMode,
      {Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(
        _func(image.pointer, buffer.pointer, width, height, scanLine,
            imageMode.index),
        'LoadImageFromBuffer');
    return image;
  }
}

final LoadImageFromBuffer = _LoadImageFromBufferWrapper();

class _GetImageBufferSizeWrapper {
  late int Function(int, Pointer<Int32>, int) _func;

  _GetImageBufferSizeWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Int32>, Int32)>>(
            'FSDK_GetImageBufferSize')
        .asFunction();
  }

  int call(Image image, ImageMode imageMode) {
    final var1 = malloc.allocate<Int32>(sizeOf<Int32>() * 1);
    try {
      _checkErrorCode(
          _func(image.handle, var1, imageMode.index), 'GetImageBufferSize');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetImageBufferSize = _GetImageBufferSizeWrapper();

class _SaveImageToBufferWrapper {
  late int Function(int, Pointer<Uint8>, int) _func;

  _SaveImageToBufferWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Uint8>, Int32)>>(
            'FSDK_SaveImageToBuffer')
        .asFunction();
  }

  DataBuffer call(Image image, ImageMode imageMode,
      {DataBuffer? buffer = null}) {
    if (buffer == null) {
      buffer = DataBuffer._allocate(image.getBufferSize(imageMode));
    }
    _checkErrorCode(_func(image.handle, buffer.pointer, imageMode.index),
        'SaveImageToBuffer');
    return buffer;
  }
}

final SaveImageToBuffer = _SaveImageToBufferWrapper();

class _LoadImageFromJpegBufferWrapper {
  late int Function(Pointer<Uint32>, Pointer<Uint8>, int) _func;

  _LoadImageFromJpegBufferWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint32>, Pointer<Uint8>,
                    Int32)>>('FSDK_LoadImageFromJpegBuffer')
        .asFunction();
  }

  Image call(DataBuffer buffer, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(_func(image.pointer, buffer.pointer, buffer.length),
        'LoadImageFromJpegBuffer');
    return image;
  }
}

final LoadImageFromJpegBuffer = _LoadImageFromJpegBufferWrapper();

class _LoadImageFromPngBufferWrapper {
  late int Function(Pointer<Uint32>, Pointer<Uint8>, int) _func;

  _LoadImageFromPngBufferWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint32>, Pointer<Uint8>,
                    Int32)>>('FSDK_LoadImageFromPngBuffer')
        .asFunction();
  }

  Image call(DataBuffer buffer, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(_func(image.pointer, buffer.pointer, buffer.length),
        'LoadImageFromPngBuffer');
    return image;
  }
}

final LoadImageFromPngBuffer = _LoadImageFromPngBufferWrapper();

class _LoadImageFromPngBufferWithAlphaWrapper {
  late int Function(Pointer<Uint32>, Pointer<Uint8>, int) _func;

  _LoadImageFromPngBufferWithAlphaWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint32>, Pointer<Uint8>,
                    Int32)>>('FSDK_LoadImageFromPngBufferWithAlpha')
        .asFunction();
  }

  Image call(DataBuffer buffer, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(_func(image.pointer, buffer.pointer, buffer.length),
        'LoadImageFromPngBufferWithAlpha');
    return image;
  }
}

final LoadImageFromPngBufferWithAlpha =
    _LoadImageFromPngBufferWithAlphaWrapper();

class _DetectFaceWrapper {
  late int Function(int, Pointer<_FacePosition>) _func;

  _DetectFaceWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<_FacePosition>)>>(
            'FSDK_DetectFace')
        .asFunction();
  }

  FacePosition call(Image image, {FacePosition? facePosition = null}) {
    if (facePosition == null) facePosition = FacePosition._allocate();
    _checkErrorCode(_func(image.handle, facePosition.pointer), 'DetectFace');
    return facePosition;
  }
}

final DetectFace = _DetectFaceWrapper();

class _DetectMultipleFacesWrapper {
  late int Function(int, Pointer<Int32>, Pointer<_FacePosition>, int) _func;

  _DetectMultipleFacesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Int32>, Pointer<_FacePosition>,
                    Int32)>>('FSDK_DetectMultipleFaces')
        .asFunction();
  }

  FacePositions call(Image image,
      {FacePositions? faces = null, int maxSize = 256}) {
    if (faces == null) faces = FacePositions._allocate(maxSize);
    _checkErrorCode(
        _func(image.handle, faces._lengthPointer, faces.pointer,
            sizeOf<_FacePosition>() * faces.capacity),
        'DetectMultipleFaces');
    return faces;
  }
}

final DetectMultipleFaces = _DetectMultipleFacesWrapper();

class _SetFaceDetectionParametersWrapper {
  late int Function(int, int, int) _func;

  _SetFaceDetectionParametersWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint8, Uint8, Int32)>>(
            'FSDK_SetFaceDetectionParameters')
        .asFunction();
  }

  void call(bool handleArbitraryRotations, bool determineFaceRotationAngle,
      int internalResizeWidth) {
    _checkErrorCode(
        _func(handleArbitraryRotations ? 1 : 0,
            determineFaceRotationAngle ? 1 : 0, internalResizeWidth),
        'SetFaceDetectionParameters');
  }
}

final SetFaceDetectionParameters = _SetFaceDetectionParametersWrapper();

class _SetFaceDetectionThresholdWrapper {
  late int Function(int) _func;

  _SetFaceDetectionThresholdWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Int32)>>(
            'FSDK_SetFaceDetectionThreshold')
        .asFunction();
  }

  void call(int threshold) {
    _checkErrorCode(_func(threshold), 'SetFaceDetectionThreshold');
  }
}

final SetFaceDetectionThreshold = _SetFaceDetectionThresholdWrapper();

class _GetDetectedFaceConfidenceWrapper {
  late int Function(Pointer<Int32>) _func;

  _GetDetectedFaceConfidenceWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Int32>)>>(
            'FSDK_GetDetectedFaceConfidence')
        .asFunction();
  }

  int call() {
    final var1 = malloc.allocate<Int32>(sizeOf<Int32>() * 1);
    try {
      _checkErrorCode(_func(var1), 'GetDetectedFaceConfidence');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetDetectedFaceConfidence = _GetDetectedFaceConfidenceWrapper();

class _DetectFacialFeaturesWrapper {
  late int Function(int, Pointer<Point>) _func;

  _DetectFacialFeaturesWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Point>)>>(
            'FSDK_DetectFacialFeatures')
        .asFunction();
  }

  FacialFeatures call(Image image, {FacialFeatures? facialFeatures = null}) {
    if (facialFeatures == null) facialFeatures = FacialFeatures._allocate();
    _checkErrorCode(
        _func(image.handle, facialFeatures.pointer), 'DetectFacialFeatures');
    return facialFeatures;
  }
}

final DetectFacialFeatures = _DetectFacialFeaturesWrapper();

class _DetectFacialFeaturesInRegionWrapper {
  late int Function(int, Pointer<_FacePosition>, Pointer<Point>) _func;

  _DetectFacialFeaturesInRegionWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<_FacePosition>,
                    Pointer<Point>)>>('FSDK_DetectFacialFeaturesInRegion')
        .asFunction();
  }

  FacialFeatures call(Image image, FacePosition facePosition,
      {FacialFeatures? facialFeatures = null}) {
    if (facialFeatures == null) facialFeatures = FacialFeatures._allocate();
    _checkErrorCode(
        _func(image.handle, facePosition.pointer, facialFeatures.pointer),
        'DetectFacialFeaturesInRegion');
    return facialFeatures;
  }
}

final DetectFacialFeaturesInRegion = _DetectFacialFeaturesInRegionWrapper();

class _DetectEyesWrapper {
  late int Function(int, Pointer<Point>) _func;

  _DetectEyesWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Point>)>>(
            'FSDK_DetectEyes')
        .asFunction();
  }

  Eyes call(Image image, {Eyes? eyes = null}) {
    if (eyes == null) eyes = Eyes._allocate();
    _checkErrorCode(_func(image.handle, eyes.pointer), 'DetectEyes');
    return eyes;
  }
}

final DetectEyes = _DetectEyesWrapper();

class _DetectEyesInRegionWrapper {
  late int Function(int, Pointer<_FacePosition>, Pointer<Point>) _func;

  _DetectEyesInRegionWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<_FacePosition>,
                    Pointer<Point>)>>('FSDK_DetectEyesInRegion')
        .asFunction();
  }

  Eyes call(Image image, FacePosition facePosition, {Eyes? eyes = null}) {
    if (eyes == null) eyes = Eyes._allocate();
    _checkErrorCode(_func(image.handle, facePosition.pointer, eyes.pointer),
        'DetectEyesInRegion');
    return eyes;
  }
}

final DetectEyesInRegion = _DetectEyesInRegionWrapper();

class _CopyImageWrapper {
  late int Function(int, int) _func;

  _CopyImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Uint32)>>(
            'FSDK_CopyImage')
        .asFunction();
  }

  Image call(Image sourceImage) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(_func(sourceImage.handle, var1), 'CopyImage');
    return Image.fromHandle(var1);
  }
}

final CopyImage = _CopyImageWrapper();

class _ResizeImageWrapper {
  late int Function(int, double, int) _func;

  _ResizeImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Double, Uint32)>>(
            'FSDK_ResizeImage')
        .asFunction();
  }

  Image call(Image sourceImage, double ratio) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(_func(sourceImage.handle, ratio, var1), 'ResizeImage');
    return Image.fromHandle(var1);
  }
}

final ResizeImage = _ResizeImageWrapper();

class _RotateImage90Wrapper {
  late int Function(int, int, int) _func;

  _RotateImage90Wrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int32, Uint32)>>(
            'FSDK_RotateImage90')
        .asFunction();
  }

  Image call(Image sourceImage, int multiplier) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(
        _func(sourceImage.handle, multiplier, var1), 'RotateImage90');
    return Image.fromHandle(var1);
  }
}

final RotateImage90 = _RotateImage90Wrapper();

class _RotateImageWrapper {
  late int Function(int, double, int) _func;

  _RotateImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Double, Uint32)>>(
            'FSDK_RotateImage')
        .asFunction();
  }

  Image call(Image sourceImage, double angle) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(_func(sourceImage.handle, angle, var1), 'RotateImage');
    return Image.fromHandle(var1);
  }
}

final RotateImage = _RotateImageWrapper();

class _RotateImageCenterWrapper {
  late int Function(int, double, double, double, int) _func;

  _RotateImageCenterWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Double, Double, Double,
                    Uint32)>>('FSDK_RotateImageCenter')
        .asFunction();
  }

  Image call(Image sourceImage, double angle, double xCenter, double yCenter) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(_func(sourceImage.handle, angle, xCenter, yCenter, var1),
        'RotateImageCenter');
    return Image.fromHandle(var1);
  }
}

final RotateImageCenter = _RotateImageCenterWrapper();

class _CopyRectWrapper {
  late int Function(int, int, int, int, int, int) _func;

  _CopyRectWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int32, Int32, Int32, Int32,
                    Uint32)>>('FSDK_CopyRect')
        .asFunction();
  }

  Image call(Image sourceImage, int x1, int y1, int x2, int y2) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(
        _func(sourceImage.handle, x1, y1, x2, y2, var1), 'CopyRect');
    return Image.fromHandle(var1);
  }
}

final CopyRect = _CopyRectWrapper();

class _CopyRectReplicateBorderWrapper {
  late int Function(int, int, int, int, int, int) _func;

  _CopyRectReplicateBorderWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int32, Int32, Int32, Int32,
                    Uint32)>>('FSDK_CopyRectReplicateBorder')
        .asFunction();
  }

  Image call(Image sourceImage, int x1, int y1, int x2, int y2) {
    final var1 = CreateEmptyImage().handle;
    _checkErrorCode(_func(sourceImage.handle, x1, y1, x2, y2, var1),
        'CopyRectReplicateBorder');
    return Image.fromHandle(var1);
  }
}

final CopyRectReplicateBorder = _CopyRectReplicateBorderWrapper();

class _MirrorImageWrapper {
  late int Function(int, int) _func;

  _MirrorImageWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Uint8)>>(
            'FSDK_MirrorImage')
        .asFunction();
  }

  void call(Image image, bool useVerticalMirroringInsteadOfHorizontal) {
    _checkErrorCode(
        _func(image.handle, useVerticalMirroringInsteadOfHorizontal ? 1 : 0),
        'MirrorImage');
  }
}

final MirrorImage = _MirrorImageWrapper();

class _ExtractFaceImageWrapper {
  late int Function(
      int, Pointer<Point>, int, int, Pointer<Uint32>, Pointer<Point>) _func;

  _ExtractFaceImageWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Point>, Int32, Int32,
                    Pointer<Uint32>, Pointer<Point>)>>('FSDK_ExtractFaceImage')
        .asFunction();
  }

  ExtractedFace call(
      Image image, FacialFeatures facialFeatures, int width, int height,
      {Image? extractedFaceImage = null,
      FacialFeatures? resizedFeatures = null}) {
    if (extractedFaceImage == null) extractedFaceImage = Image._allocate();
    if (resizedFeatures == null) resizedFeatures = FacialFeatures.allocate();
    _checkErrorCode(
        _func(image.handle, facialFeatures.pointer, width, height,
            extractedFaceImage.pointer, resizedFeatures.pointer),
        'ExtractFaceImage');
    return ExtractedFace(extractedFaceImage, resizedFeatures);
  }
}

final ExtractFaceImage = _ExtractFaceImageWrapper();

class _GetFaceTemplateWrapper {
  late int Function(int, Pointer<Uint8>) _func;

  _GetFaceTemplateWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Uint8>)>>(
            'FSDK_GetFaceTemplate')
        .asFunction();
  }

  FaceTemplate call(Image image, {FaceTemplate? faceTemplate = null}) {
    if (faceTemplate == null) faceTemplate = FaceTemplate._allocate();
    _checkErrorCode(
        _func(image.handle, faceTemplate.pointer), 'GetFaceTemplate');
    return faceTemplate;
  }
}

final GetFaceTemplate = _GetFaceTemplateWrapper();

class _GetFaceTemplateInRegionWrapper {
  late int Function(int, Pointer<_FacePosition>, Pointer<Uint8>) _func;

  _GetFaceTemplateInRegionWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<_FacePosition>,
                    Pointer<Uint8>)>>('FSDK_GetFaceTemplateInRegion')
        .asFunction();
  }

  FaceTemplate call(Image image, FacePosition facePosition,
      {FaceTemplate? faceTemplate = null}) {
    if (faceTemplate == null) faceTemplate = FaceTemplate._allocate();
    _checkErrorCode(
        _func(image.handle, facePosition.pointer, faceTemplate.pointer),
        'GetFaceTemplateInRegion');
    return faceTemplate;
  }
}

final GetFaceTemplateInRegion = _GetFaceTemplateInRegionWrapper();

class _GetFaceTemplateUsingFeaturesWrapper {
  late int Function(int, Pointer<Point>, Pointer<Uint8>) _func;

  _GetFaceTemplateUsingFeaturesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Point>,
                    Pointer<Uint8>)>>('FSDK_GetFaceTemplateUsingFeatures')
        .asFunction();
  }

  FaceTemplate call(Image image, FacialFeatures facialFeatures,
      {FaceTemplate? faceTemplate = null}) {
    if (faceTemplate == null) faceTemplate = FaceTemplate._allocate();
    _checkErrorCode(
        _func(image.handle, facialFeatures.pointer, faceTemplate.pointer),
        'GetFaceTemplateUsingFeatures');
    return faceTemplate;
  }
}

final GetFaceTemplateUsingFeatures = _GetFaceTemplateUsingFeaturesWrapper();

class _GetFaceTemplateUsingEyesWrapper {
  late int Function(int, Pointer<Point>, Pointer<Uint8>) _func;

  _GetFaceTemplateUsingEyesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Point>,
                    Pointer<Uint8>)>>('FSDK_GetFaceTemplateUsingEyes')
        .asFunction();
  }

  FaceTemplate call(Image image, Eyes eyeCoords,
      {FaceTemplate? faceTemplate = null}) {
    if (faceTemplate == null) faceTemplate = FaceTemplate._allocate();
    _checkErrorCode(
        _func(image.handle, eyeCoords.pointer, faceTemplate.pointer),
        'GetFaceTemplateUsingEyes');
    return faceTemplate;
  }
}

final GetFaceTemplateUsingEyes = _GetFaceTemplateUsingEyesWrapper();

class _MatchFacesWrapper {
  late int Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Float>) _func;

  _MatchFacesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                    Pointer<Float>)>>('FSDK_MatchFaces')
        .asFunction();
  }

  double call(FaceTemplate faceTemplate1, FaceTemplate faceTemplate2) {
    final var1 = malloc.allocate<Float>(sizeOf<Float>() * 1);
    try {
      _checkErrorCode(_func(faceTemplate1.pointer, faceTemplate2.pointer, var1),
          'MatchFaces');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final MatchFaces = _MatchFacesWrapper();

class _GetMatchingThresholdAtFARWrapper {
  late int Function(double, Pointer<Float>) _func;

  _GetMatchingThresholdAtFARWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Float, Pointer<Float>)>>(
            'FSDK_GetMatchingThresholdAtFAR')
        .asFunction();
  }

  double call(double fARValue) {
    final var1 = malloc.allocate<Float>(sizeOf<Float>() * 1);
    try {
      _checkErrorCode(_func(fARValue, var1), 'GetMatchingThresholdAtFAR');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetMatchingThresholdAtFAR = _GetMatchingThresholdAtFARWrapper();

class _GetMatchingThresholdAtFRRWrapper {
  late int Function(double, Pointer<Float>) _func;

  _GetMatchingThresholdAtFRRWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Float, Pointer<Float>)>>(
            'FSDK_GetMatchingThresholdAtFRR')
        .asFunction();
  }

  double call(double fRRValue) {
    final var1 = malloc.allocate<Float>(sizeOf<Float>() * 1);
    try {
      _checkErrorCode(_func(fRRValue, var1), 'GetMatchingThresholdAtFRR');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetMatchingThresholdAtFRR = _GetMatchingThresholdAtFRRWrapper();

class _CreateTrackerWrapper {
  late int Function(Pointer<Uint32>) _func;

  _CreateTrackerWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Uint32>)>>(
            'FSDK_CreateTracker')
        .asFunction();
  }

  Tracker call({Tracker? tracker = null}) {
    if (tracker == null) tracker = Tracker._allocate();
    _checkErrorCode(_func(tracker.pointer), 'CreateTracker');
    return tracker;
  }
}

final CreateTracker = _CreateTrackerWrapper();

class _FreeTrackerWrapper {
  late int Function(int) _func;

  _FreeTrackerWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32)>>('FSDK_FreeTracker')
        .asFunction();
  }

  void call(Tracker tracker) {
    _checkErrorCode(_func(tracker.handle), 'FreeTracker');
  }
}

final FreeTracker = _FreeTrackerWrapper();

class _ClearTrackerWrapper {
  late int Function(int) _func;

  _ClearTrackerWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32)>>('FSDK_ClearTracker')
        .asFunction();
  }

  void call(Tracker tracker) {
    _checkErrorCode(_func(tracker.handle), 'ClearTracker');
  }
}

final ClearTracker = _ClearTrackerWrapper();

class _SetTrackerParameterWrapper {
  late int Function(int, Pointer<Utf8>, Pointer<Utf8>) _func;

  _SetTrackerParameterWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Utf8>,
                    Pointer<Utf8>)>>('FSDK_SetTrackerParameter')
        .asFunction();
  }

  void call(Tracker tracker, String parameterName, String parameterValue) {
    final var1 = parameterName.toNativeUtf8();
    final var2 = parameterValue.toNativeUtf8();
    try {
      _checkErrorCode(_func(tracker.handle, var1, var2), 'SetTrackerParameter');
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final SetTrackerParameter = _SetTrackerParameterWrapper();

class _SetTrackerMultipleParametersWrapper {
  late int Function(int, Pointer<Utf8>, Pointer<Int32>) _func;

  _SetTrackerMultipleParametersWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Utf8>,
                    Pointer<Int32>)>>('FSDK_SetTrackerMultipleParameters')
        .asFunction();
  }

  void call(Tracker tracker, Map<String, dynamic> parameters) {
    final var1 = parameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(';')
        .toNativeUtf8();
    final var2 = malloc.allocate<Int32>(sizeOf<Int32>());
    try {
      _checkErrorCode(_func(tracker.handle, var1, var2),
          'SetTrackerMultipleParameters', () => var2.value);
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final SetTrackerMultipleParameters = _SetTrackerMultipleParametersWrapper();

class _GetTrackerParameterWrapper {
  late int Function(int, Pointer<Utf8>, Pointer<Utf8>, int) _func;

  _GetTrackerParameterWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Pointer<Utf8>, Pointer<Utf8>,
                    Int32)>>('FSDK_GetTrackerParameter')
        .asFunction();
  }

  String call(Tracker tracker, String parameterName,
      {int maxSizeInBytes = 256}) {
    final var1 = parameterName.toNativeUtf8();
    final var2 = malloc.allocate<Utf8>(maxSizeInBytes);
    try {
      _checkErrorCode(_func(tracker.handle, var1, var2, maxSizeInBytes),
          'GetTrackerParameter');
      return var2.toDartString();
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final GetTrackerParameter = _GetTrackerParameterWrapper();

class _FeedFrameWrapper {
  late int Function(int, int, int, Pointer<Int64>, Pointer<Int64>, int) _func;

  _FeedFrameWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Uint32, Pointer<Int64>,
                    Pointer<Int64>, Int64)>>('FSDK_FeedFrame')
        .asFunction();
  }

  Int64Buffer call(Tracker tracker, int cameraIdx, Image image,
      {Int64Buffer? ids = null, int maxSize = 256}) {
    if (ids == null) ids = Int64Buffer._allocate(maxSize);
    _checkErrorCode(
        _func(tracker.handle, cameraIdx, image.handle, ids._lengthPointer,
            ids.pointer, sizeOf<Int64>() * ids.capacity),
        'FeedFrame');
    return ids;
  }
}

final FeedFrame = _FeedFrameWrapper();

class _GetTrackerEyesWrapper {
  late int Function(int, int, int, Pointer<Point>) _func;

  _GetTrackerEyesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Int64,
                    Pointer<Point>)>>('FSDK_GetTrackerEyes')
        .asFunction();
  }

  Eyes call(Tracker tracker, int cameraIdx, int id, {Eyes? eyes = null}) {
    if (eyes == null) eyes = Eyes._allocate();
    _checkErrorCode(
        _func(tracker.handle, cameraIdx, id, eyes.pointer), 'GetTrackerEyes');
    return eyes;
  }
}

final GetTrackerEyes = _GetTrackerEyesWrapper();

class _GetTrackerFacialFeaturesWrapper {
  late int Function(int, int, int, Pointer<Point>) _func;

  _GetTrackerFacialFeaturesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Int64,
                    Pointer<Point>)>>('FSDK_GetTrackerFacialFeatures')
        .asFunction();
  }

  FacialFeatures call(Tracker tracker, int cameraIdx, int id,
      {FacialFeatures? facialFeatures = null}) {
    if (facialFeatures == null) facialFeatures = FacialFeatures._allocate();
    _checkErrorCode(
        _func(tracker.handle, cameraIdx, id, facialFeatures.pointer),
        'GetTrackerFacialFeatures');
    return facialFeatures;
  }
}

final GetTrackerFacialFeatures = _GetTrackerFacialFeaturesWrapper();

class _GetTrackerFacePositionWrapper {
  late int Function(int, int, int, Pointer<_FacePosition>) _func;

  _GetTrackerFacePositionWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Int64,
                    Pointer<_FacePosition>)>>('FSDK_GetTrackerFacePosition')
        .asFunction();
  }

  FacePosition call(Tracker tracker, int cameraIdx, int id,
      {FacePosition? facePosition = null}) {
    if (facePosition == null) facePosition = FacePosition._allocate();
    _checkErrorCode(_func(tracker.handle, cameraIdx, id, facePosition.pointer),
        'GetTrackerFacePosition');
    return facePosition;
  }
}

final GetTrackerFacePosition = _GetTrackerFacePositionWrapper();

class _LockIDWrapper {
  late int Function(int, int) _func;

  _LockIDWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64)>>('FSDK_LockID')
        .asFunction();
  }

  void call(Tracker tracker, int id) {
    _checkErrorCode(_func(tracker.handle, id), 'LockID');
  }
}

final LockID = _LockIDWrapper();

class _UnlockIDWrapper {
  late int Function(int, int) _func;

  _UnlockIDWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64)>>('FSDK_UnlockID')
        .asFunction();
  }

  void call(Tracker tracker, int id) {
    _checkErrorCode(_func(tracker.handle, id), 'UnlockID');
  }
}

final UnlockID = _UnlockIDWrapper();

class _PurgeIDWrapper {
  late int Function(int, int) _func;

  _PurgeIDWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64)>>('FSDK_PurgeID')
        .asFunction();
  }

  void call(Tracker tracker, int id) {
    _checkErrorCode(_func(tracker.handle, id), 'PurgeID');
  }
}

final PurgeID = _PurgeIDWrapper();

class _SetNameWrapper {
  late int Function(int, int, Pointer<Utf8>) _func;

  _SetNameWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64, Pointer<Utf8>)>>(
            'FSDK_SetName')
        .asFunction();
  }

  void call(Tracker tracker, int id, String name) {
    final var1 = name.toNativeUtf8();
    try {
      _checkErrorCode(_func(tracker.handle, id, var1), 'SetName');
    } finally {
      malloc.free(var1);
    }
  }
}

final SetName = _SetNameWrapper();

class _GetNameWrapper {
  late int Function(int, int, Pointer<Utf8>, int) _func;

  _GetNameWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Uint32, Int64, Pointer<Utf8>, Int64)>>('FSDK_GetName')
        .asFunction();
  }

  String call(Tracker tracker, int id, {int maxSizeInBytes = 256}) {
    final var1 = malloc.allocate<Utf8>(maxSizeInBytes);
    try {
      _checkErrorCode(
          _func(tracker.handle, id, var1, maxSizeInBytes), 'GetName');
      return var1.toDartString();
    } finally {
      malloc.free(var1);
    }
  }
}

final GetName = _GetNameWrapper();

class _GetAllNamesWrapper {
  late int Function(int, int, Pointer<Utf8>, int) _func;

  _GetAllNamesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Uint32, Int64, Pointer<Utf8>, Int64)>>('FSDK_GetAllNames')
        .asFunction();
  }

  String call(Tracker tracker, int id, {int maxSizeInBytes = 256}) {
    final var1 = malloc.allocate<Utf8>(maxSizeInBytes);
    try {
      _checkErrorCode(
          _func(tracker.handle, id, var1, maxSizeInBytes), 'GetAllNames');
      return var1.toDartString();
    } finally {
      malloc.free(var1);
    }
  }
}

final GetAllNames = _GetAllNamesWrapper();

class _GetIDReassignmentWrapper {
  late int Function(int, int, Pointer<Int64>) _func;

  _GetIDReassignmentWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64, Pointer<Int64>)>>(
            'FSDK_GetIDReassignment')
        .asFunction();
  }

  int call(Tracker tracker, int id) {
    final var1 = malloc.allocate<Int64>(sizeOf<Int64>() * 1);
    try {
      _checkErrorCode(_func(tracker.handle, id, var1), 'GetIDReassignment');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetIDReassignment = _GetIDReassignmentWrapper();

class _GetSimilarIDCountWrapper {
  late int Function(int, int, Pointer<Int64>) _func;

  _GetSimilarIDCountWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Int64, Pointer<Int64>)>>(
            'FSDK_GetSimilarIDCount')
        .asFunction();
  }

  int call(Tracker tracker, int id) {
    final var1 = malloc.allocate<Int64>(sizeOf<Int64>() * 1);
    try {
      _checkErrorCode(_func(tracker.handle, id, var1), 'GetSimilarIDCount');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetSimilarIDCount = _GetSimilarIDCountWrapper();

class _GetSimilarIDListWrapper {
  late int Function(int, int, Pointer<Int64>, int) _func;

  _GetSimilarIDListWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Pointer<Int64>,
                    Int64)>>('FSDK_GetSimilarIDList')
        .asFunction();
  }

  Int64Buffer call(Tracker tracker, int id,
      {Int64Buffer? similarIDList = null}) {
    if (similarIDList == null)
      similarIDList = Int64Buffer._allocate(GetSimilarIDCount(tracker, id));
    _checkErrorCode(
        _func(tracker.handle, id, similarIDList.pointer,
            sizeOf<Int64>() * similarIDList.capacity),
        'GetSimilarIDList');
    return similarIDList;
  }
}

final GetSimilarIDList = _GetSimilarIDListWrapper();

class _SaveTrackerMemoryToFileWrapper {
  late int Function(int, Pointer<Utf8>) _func;

  _SaveTrackerMemoryToFileWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Utf8>)>>(
            'FSDK_SaveTrackerMemoryToFile')
        .asFunction();
  }

  void call(Tracker tracker, String fileName) {
    final var1 = fileName.toNativeUtf8();
    try {
      _checkErrorCode(_func(tracker.handle, var1), 'SaveTrackerMemoryToFile');
    } finally {
      malloc.free(var1);
    }
  }
}

final SaveTrackerMemoryToFile = _SaveTrackerMemoryToFileWrapper();

class _LoadTrackerMemoryFromFileWrapper {
  late int Function(Pointer<Uint32>, Pointer<Utf8>) _func;

  _LoadTrackerMemoryFromFileWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Uint32>, Pointer<Utf8>)>>(
            'FSDK_LoadTrackerMemoryFromFile')
        .asFunction();
  }

  Tracker call(String fileName, {Tracker? tracker = null}) {
    if (tracker == null) tracker = Tracker._allocate();
    final var1 = fileName.toNativeUtf8();
    try {
      _checkErrorCode(
          _func(tracker.pointer, var1), 'LoadTrackerMemoryFromFile');
      return tracker;
    } finally {
      malloc.free(var1);
    }
  }
}

final LoadTrackerMemoryFromFile = _LoadTrackerMemoryFromFileWrapper();

class _GetTrackerMemoryBufferSizeWrapper {
  late int Function(int, Pointer<Int64>) _func;

  _GetTrackerMemoryBufferSizeWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Int64>)>>(
            'FSDK_GetTrackerMemoryBufferSize')
        .asFunction();
  }

  int call(Tracker tracker) {
    final var1 = malloc.allocate<Int64>(sizeOf<Int64>() * 1);
    try {
      _checkErrorCode(
          _func(tracker.handle, var1), 'GetTrackerMemoryBufferSize');
      return var1.value;
    } finally {
      malloc.free(var1);
    }
  }
}

final GetTrackerMemoryBufferSize = _GetTrackerMemoryBufferSizeWrapper();

class _SaveTrackerMemoryToBufferWrapper {
  late int Function(int, Pointer<Uint8>) _func;

  _SaveTrackerMemoryToBufferWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Uint32, Pointer<Uint8>)>>(
            'FSDK_SaveTrackerMemoryToBuffer')
        .asFunction();
  }

  DataBuffer call(Tracker tracker, {DataBuffer? buffer = null}) {
    if (buffer == null) buffer = DataBuffer._allocate(tracker.bufferSize);
    _checkErrorCode(
        _func(tracker.handle, buffer.pointer), 'SaveTrackerMemoryToBuffer');
    return buffer;
  }
}

final SaveTrackerMemoryToBuffer = _SaveTrackerMemoryToBufferWrapper();

class _LoadTrackerMemoryFromBufferWrapper {
  late int Function(Pointer<Uint32>, Pointer<Uint8>) _func;

  _LoadTrackerMemoryFromBufferWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Uint32>,
                    Pointer<Uint8>)>>('FSDK_LoadTrackerMemoryFromBuffer')
        .asFunction();
  }

  Tracker call(DataBuffer buffer, {Tracker? tracker = null}) {
    if (tracker == null) tracker = Tracker._allocate();
    _checkErrorCode(
        _func(tracker.pointer, buffer.pointer), 'LoadTrackerMemoryFromBuffer');
    return tracker;
  }
}

final LoadTrackerMemoryFromBuffer = _LoadTrackerMemoryFromBufferWrapper();

class _GetTrackerFacialAttributeWrapper {
  late int Function(int, int, int, Pointer<Utf8>, Pointer<Utf8>, int) _func;

  _GetTrackerFacialAttributeWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Uint32, Int64, Int64, Pointer<Utf8>,
                    Pointer<Utf8>, Int64)>>('FSDK_GetTrackerFacialAttribute')
        .asFunction();
  }

  String call(Tracker tracker, int cameraIdx, int id, String attributeName,
      {int maxSizeInBytes = 256}) {
    final var1 = attributeName.toNativeUtf8();
    final var2 = malloc.allocate<Utf8>(maxSizeInBytes);
    try {
      _checkErrorCode(
          _func(tracker.handle, cameraIdx, id, var1, var2, maxSizeInBytes),
          'GetTrackerFacialAttribute');
      return var2.toDartString();
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final GetTrackerFacialAttribute = _GetTrackerFacialAttributeWrapper();

class _DetectFacialAttributeUsingFeaturesWrapper {
  late int Function(int, Pointer<Point>, Pointer<Utf8>, Pointer<Utf8>, int)
      _func;

  _DetectFacialAttributeUsingFeaturesWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Uint32,
                    Pointer<Point>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Int64)>>('FSDK_DetectFacialAttributeUsingFeatures')
        .asFunction();
  }

  String call(Image image, FacialFeatures facialFeatures, String attributeName,
      {int maxSizeInBytes = 256}) {
    final var1 = attributeName.toNativeUtf8();
    final var2 = malloc.allocate<Utf8>(maxSizeInBytes);
    try {
      _checkErrorCode(
          _func(
              image.handle, facialFeatures.pointer, var1, var2, maxSizeInBytes),
          'DetectFacialAttributeUsingFeatures');
      return var2.toDartString();
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final DetectFacialAttributeUsingFeatures =
    _DetectFacialAttributeUsingFeaturesWrapper();

class _GetValueConfidenceWrapper {
  late int Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Float>) _func;

  _GetValueConfidenceWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Float>)>>('FSDK_GetValueConfidence')
        .asFunction();
  }

  double call(String attributeValues, String value) {
    final var1 = attributeValues.toNativeUtf8();
    final var2 = value.toNativeUtf8();
    final var3 = malloc.allocate<Float>(sizeOf<Float>() * 1);
    try {
      _checkErrorCode(_func(var1, var2, var3), 'GetValueConfidence');
      return var3.value;
    } finally {
      malloc.free(var3);
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final GetValueConfidence = _GetValueConfidenceWrapper();

class _SetHTTPProxyWrapper {
  late int Function(Pointer<Utf8>, int, Pointer<Utf8>, Pointer<Utf8>) _func;

  _SetHTTPProxyWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Utf8>, Int16, Pointer<Utf8>,
                    Pointer<Utf8>)>>('FSDK_SetHTTPProxy')
        .asFunction();
  }

  void call(String serverNameOrIPAddress, int port, String userName,
      String password) {
    final var1 = serverNameOrIPAddress.toNativeUtf8();
    final var2 = userName.toNativeUtf8();
    final var3 = password.toNativeUtf8();
    try {
      _checkErrorCode(_func(var1, port, var2, var3), 'SetHTTPProxy');
    } finally {
      malloc.free(var3);
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final SetHTTPProxy = _SetHTTPProxyWrapper();

class _OpenIPVideoCameraWrapper {
  late int Function(
          int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Int32>)
      _func;

  _OpenIPVideoCameraWrapper() {
    _func = _nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Int32,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Int32,
                    Pointer<Int32>)>>('FSDK_OpenIPVideoCamera')
        .asFunction();
  }

  Camera call(VideoCompressionType compressionType, String url, String username,
      String password, int timeoutSeconds,
      {Camera? cameraHandle = null}) {
    final var1 = url.toNativeUtf8();
    final var2 = username.toNativeUtf8();
    final var3 = password.toNativeUtf8();
    if (cameraHandle == null) cameraHandle = Camera._allocate();
    try {
      _checkErrorCode(
          _func(compressionType.index, var1, var2, var3, timeoutSeconds,
              cameraHandle.pointer),
          'OpenIPVideoCamera');
      return cameraHandle;
    } finally {
      malloc.free(var3);
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final OpenIPVideoCamera = _OpenIPVideoCameraWrapper();

class _CloseVideoCameraWrapper {
  late int Function(int) _func;

  _CloseVideoCameraWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Int32)>>('FSDK_CloseVideoCamera')
        .asFunction();
  }

  void call(Camera cameraHandle) {
    _checkErrorCode(_func(cameraHandle.handle), 'CloseVideoCamera');
  }
}

final CloseVideoCamera = _CloseVideoCameraWrapper();

class _GrabFrameWrapper {
  late int Function(int, Pointer<Uint32>) _func;

  _GrabFrameWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Int32, Pointer<Uint32>)>>(
            'FSDK_GrabFrame')
        .asFunction();
  }

  Image call(Camera cameraHandle, {Image? image = null}) {
    if (image == null) image = Image._allocate();
    _checkErrorCode(_func(cameraHandle.handle, image.pointer), 'GrabFrame');
    return image;
  }
}

final GrabFrame = _GrabFrameWrapper();

class _InitializeCapturingWrapper {
  late int Function() _func;

  _InitializeCapturingWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function()>>('FSDK_InitializeCapturing')
        .asFunction();
  }

  void call() {
    _checkErrorCode(_func(), 'InitializeCapturing');
  }
}

final InitializeCapturing = _InitializeCapturingWrapper();

class _FinalizeCapturingWrapper {
  late int Function() _func;

  _FinalizeCapturingWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function()>>('FSDK_FinalizeCapturing')
        .asFunction();
  }

  void call() {
    _checkErrorCode(_func(), 'FinalizeCapturing');
  }
}

final FinalizeCapturing = _FinalizeCapturingWrapper();

class _SetParameterWrapper {
  late int Function(Pointer<Utf8>, Pointer<Utf8>) _func;

  _SetParameterWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>)>>(
            'FSDK_SetParameter')
        .asFunction();
  }

  void call(String parameterName, String parameterValue) {
    final var1 = parameterName.toNativeUtf8();
    final var2 = parameterValue.toNativeUtf8();
    try {
      _checkErrorCode(_func(var1, var2), 'SetParameter');
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final SetParameter = _SetParameterWrapper();

class _SetParametersWrapper {
  late int Function(Pointer<Utf8>, Pointer<Int32>) _func;

  _SetParametersWrapper() {
    _func = _nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Int32>)>>(
            'FSDK_SetParameters')
        .asFunction();
  }

  void call(Map<String, dynamic> parameters) {
    final var1 = parameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(';')
        .toNativeUtf8();
    final var2 = malloc.allocate<Int32>(sizeOf<Int32>());
    try {
      _checkErrorCode(_func(var1, var2), 'SetParameters', () => var2.value);
    } finally {
      malloc.free(var2);
      malloc.free(var1);
    }
  }
}

final SetParameters = _SetParametersWrapper();

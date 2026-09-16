import 'dart:ffi';

import 'package:camera/camera.dart';

import 'flutter_face_sdk.dart' show DataBuffer, Image, ImageMode;
import 'utils.dart' show getDynamicLibrary;

final DynamicLibrary _nativeLib = getDynamicLibrary('flutter_face_sdk');

typedef _Yuv420ToRgb = void Function(Pointer<Uint8>, Pointer<Uint8>,
    Pointer<Uint8>, int, int, int, int, int, Pointer<Uint8>);
final _Yuv420ToRgb _yuv420ToRGB = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32,
                Int32, Int32, Int32, Int32, Pointer<Uint8>)>>('YUV420ToRGB')
    .asFunction();

typedef _BgraToRgb = void Function(
    Pointer<Uint8>, int, int, int, Pointer<Uint8>);
final _BgraToRgb _bgraToRGB = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(Pointer<Uint8>, Int32, Int32, Int32,
                Pointer<Uint8>)>>('BGRAToRGB')
    .asFunction();

class ImageInfo {
  int width;
  int height;
  final int yBytesPerRow;
  int bytesPerRow;
  final int bytesPerPixel;
  final ImageFormatGroup imageFormatGroup;

  ImageInfo(
      [this.height = -1,
      this.width = -1,
      this.yBytesPerRow = -1,
      this.bytesPerRow = -1,
      this.bytesPerPixel = -1,
      this.imageFormatGroup = ImageFormatGroup.unknown]);

  factory ImageInfo.forImage(CameraImage image) {
    final index = image.format.group == ImageFormatGroup.yuv420 ? 1 : 0;

    return ImageInfo(
      image.height,
      image.width,
      image.planes[0].bytesPerRow,
      image.planes[index].bytesPerRow,
      image.planes[index].bytesPerPixel ?? 1,
      image.format.group,
    );
  }

  @override
  int get hashCode => Object.hash(width, height, yBytesPerRow, bytesPerRow,
      bytesPerPixel, imageFormatGroup);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is ImageInfo &&
        width == other.width &&
        height == other.height &&
        yBytesPerRow == other.yBytesPerRow &&
        bytesPerRow == other.bytesPerRow &&
        bytesPerPixel == other.bytesPerPixel &&
        imageFormatGroup == other.imageFormatGroup;
  }
}

class ImageConverter {
  ImageInfo _info = ImageInfo();

  DataBuffer _buffer = DataBuffer.allocate(1);
  List<DataBuffer> _planes = <DataBuffer>[];

  int get width => _info.width;
  int get height => _info.height;

  ImageConverter();

  void free() {
    _buffer.free();

    for (final plane in _planes) {
      plane.free();
    }

    _planes.length = 0;
  }

  static void _planeToBuffer(Plane plane, DataBuffer buffer) {
    final pointerList = buffer.pointer.asTypedList(plane.bytes.length);
    pointerList.setAll(0, plane.bytes);
  }

  Image convert(CameraImage image) {
    final info = ImageInfo.forImage(image);
    if (info != _info) {
      free();

      _buffer = DataBuffer.allocate(image.width * image.height * 3);

      _planes = image.planes
          .map((plane) => DataBuffer.allocate(plane.bytes.length))
          .toList();

      _info = info;
    }

    for (int i = 0; i < _planes.length; ++i) {
      _planeToBuffer(image.planes[i], _planes[i]);
    }
    switch (_info.imageFormatGroup) {
      case ImageFormatGroup.unknown:
        throw ArgumentError('Unknown image format');
      case ImageFormatGroup.yuv420:
        _yuv420ToRGB(
            _planes[0].pointer,
            _planes[1].pointer,
            _planes[2].pointer,
            _info.width,
            _info.height,
            _info.yBytesPerRow,
            _info.bytesPerPixel,
            _info.bytesPerRow,
            _buffer.pointer);

        break;
      case ImageFormatGroup.bgra8888:
        _bgraToRGB(_planes[0].pointer, _info.width, _info.height,
            _info.bytesPerRow, _buffer.pointer);

        break;
      default:
        throw ArgumentError('Unsupported image format');
    }

    return Image.fromBuffer(_buffer, _info.width, _info.height, _info.width * 3,
        ImageMode.Color24bit);
  }
}

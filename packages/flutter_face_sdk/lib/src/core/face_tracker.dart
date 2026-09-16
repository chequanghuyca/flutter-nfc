import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_face_sdk/src/core/converter.dart';
import 'package:flutter_face_sdk/src/core/face_motion_challenge.dart';
import 'package:flutter_face_sdk/src/core/face_verification_policy.dart';
import 'package:flutter_face_sdk/src/core/flutter_face_sdk.dart';
import 'package:path_provider/path_provider.dart';

class _FacesTrackerIsolateInfo {
  final SendPort port;
  final int trackerHandle;
  final BufferInfo idsBufferInfo;

  _FacesTrackerIsolateInfo(this.port, this.trackerHandle, this.idsBufferInfo);
}

class _WorkerData {
  final int image;
  final int orientation;
  final bool frontFacing;

  _WorkerData(this.image, this.orientation, this.frontFacing);
}

class FaceWrapper {
  final int? _id;
  final Tracker? _tracker;

  String? _name;
  FacePosition? _position;
  FacialFeatures? _features;
  double? _liveness;

  FaceWrapper(this._id, this._tracker);

  int get id => _id!;

  String get name {
    if (_name == null) {
      _tracker!.lockID(_id!);
      _name = _tracker!.getAllNames(_id!);
      _tracker!.unlockID(_id!);
    }

    return _name!;
  }

  FacePosition get position {
    _position ??= _tracker!.getFacePosition(0, _id!);
    return _position!;
  }

  FacialFeatures get features {
    _features ??= _tracker!.getFacialFeatures(0, _id!);
    return _features!;
  }

  FacePoseMetrics? poseMetrics(double roll) {
    FacialFeatures? landmarks;
    try {
      landmarks = _tracker!.getFacialFeatures(0, _id!);
      final leftEye = landmarks[FacialFeatures.LeftEye];
      final rightEye = landmarks[FacialFeatures.RightEye];
      final nose = landmarks[FacialFeatures.NoseTip];
      final mouthLeft = landmarks[FacialFeatures.MouthLeftCorner];
      final mouthRight = landmarks[FacialFeatures.MouthRightCorner];
      return estimateFacePose(
        leftEyeX: leftEye.x.toDouble(),
        leftEyeY: leftEye.y.toDouble(),
        rightEyeX: rightEye.x.toDouble(),
        rightEyeY: rightEye.y.toDouble(),
        noseX: nose.x.toDouble(),
        noseY: nose.y.toDouble(),
        mouthLeftX: mouthLeft.x.toDouble(),
        mouthLeftY: mouthLeft.y.toDouble(),
        mouthRightX: mouthRight.x.toDouble(),
        mouthRightY: mouthRight.y.toDouble(),
        roll: roll,
      );
    } on AttributeNotDetectedError {
      return null;
    } on FaceNotFoundError {
      return null;
    } finally {
      landmarks?.free();
    }
  }

  double? get liveness {
    try {
      _liveness = double.parse(
          _tracker!.getFacialAttribute(0, _id!, 'Liveness').split("=")[1]);
      return _liveness;
    } on FaceNotFoundError {
      return null;
    } on AttributeNotDetectedError {
      // Luxand needs several stable frames before the liveness attribute is
      // available. This is a pending state, not a spoofing failure.
      return null;
    } catch (e) {
      //debugPrint('rethrow');
      rethrow;
    }
  }
}

enum _FaceTrackerState {
  notInitialized,
  initializing,
  waitingForImage,
  waitingForIds,
  idsReady
}

class FacesTracker extends ChangeNotifier {
  static const _path = 'tracker.bin';

  final int internalResizeWidth;
  final int faceDetectionThreshold;
  final bool trimOutOfScreenFaces;
  final bool persistTracker;

  FacesTracker({
    this.internalResizeWidth = 256,
    this.faceDetectionThreshold = 5,
    this.trimOutOfScreenFaces = true,
    this.persistTracker = true,
  })  : assert(internalResizeWidth >= 256),
        assert(faceDetectionThreshold >= 1);

  String _trackerPath = "";
  _FaceTrackerState _state = _FaceTrackerState.notInitialized;

  static double livenessStatic = 0;

  SendPort? _send;
  Isolate? _isolate;
  Image? fsdkImage;
  CameraImage? cameraImage;

  final tracker = Tracker();
  final _receive = ReceivePort();
  final _converter = ImageConverter();
  final _ids = Int64Buffer.allocate(5);
  bool _isReady = false;
  bool _didLogCameraFormat = false;
  int _completedFrameCount = 0;
  int get completedFrameCount => _completedFrameCount;
  int _lastLoggedFaceCount = -1;
  DateTime? _frameStartedAt;

  int get width => _converter.width;

  int get height => _converter.height;

  bool get isReady => _isReady;

  void saveTracker() {
    tracker.saveToFile(_trackerPath);
  }

  void setReady() {
    _isReady = true;
    debugPrint('FaceID tracker ready');
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);

    _converter.free();

    if (persistTracker && _trackerPath.isNotEmpty) {
      saveTracker();
    }
    tracker.free();

    super.dispose();
  }

  Future<void> _openTracker() async {
    if (persistTracker) {
      final directory = await getApplicationDocumentsDirectory();
      _trackerPath = '${directory.path}/$_path';

      try {
        Tracker.fromFile(_trackerPath, tracker: tracker);
      } on Error {
        // Couldn't load tracker from memory, file may not exist
      }
    }

    tracker.clear();

    _setTrackerParameters();
  }

  void _setTrackerParameters() {
    tracker.setMultipleParameters({
      'HandleArbitraryRotations': false,
      'DetermineFaceRotationAngle': false,
      // Embedded order activation uses a larger resize width and a more
      // sensitive threshold so a second, smaller face near the frame edge is
      // not discarded. Full-screen attendance keeps its original settings.
      'InternalResizeWidth': internalResizeWidth,
      'FaceDetectionThreshold': faceDetectionThreshold,
      'TrimOutOfScreenFaces': trimOutOfScreenFaces,
      'DetectLiveness': true,
      'AttributeLivenessSmoothingAlpha': 100,
      'LivenessFramesCount': 5,
    });
  }

  static void _worker(_FacesTrackerIsolateInfo info) {
    final sendPort = info.port;
    final trackerr = Tracker.fromHandle(info.trackerHandle);
    final ids = Int64Buffer.fromInfo(info.idsBufferInfo);

    final receivePort = ReceivePort();
    receivePort.listen((data) {
      var image = Image.fromHandle(data.image);
      final rotation = Platform.isAndroid
          ? androidFrontCameraImageQuarterTurns()
          : -(data.orientation ~/ 90) + 1;
      if (rotation != 0) {
        final rotatedImage = image.rotate90(rotation);
        image.free();
        image = rotatedImage;
      }
      if (data.frontFacing && !Platform.isIOS) {
        //FIXME
        image.mirror(true);
      }
      ids.length = 0;
      try {
        trackerr.feedFrame(0, image, ids: ids);
      } on FaceNotFoundError {
        /*No faces were found*/
        debugPrint('No face');
      } on AttributeNotDetectedError {
        // The tracker may not have accumulated enough frames for liveness yet.
        // Return control to the UI so it can feed the next frame.
      } catch (e) {
        debugPrint('rethrow');
        rethrow;
      }
      image.free();
      sendPort.send(null);
    });

    sendPort.send(receivePort.sendPort);
  }

  void _initialize() async {
    await _openTracker();

    _receive.listen((msg) {
      if (msg is SendPort) {
        _send = msg;

        _state = _FaceTrackerState.waitingForImage;
        return;
      }

      _completedFrameCount++;
      final elapsed = _frameStartedAt == null
          ? -1
          : DateTime.now().difference(_frameStartedAt!).inMilliseconds;
      final faceCount = _ids.length;
      if (faceCount != _lastLoggedFaceCount ||
          _completedFrameCount <= 3 ||
          _completedFrameCount % 30 == 0) {
        debugPrint(
          'FaceID tracker frame=$_completedFrameCount '
          'faces=$faceCount elapsedMs=$elapsed',
        );
        _lastLoggedFaceCount = faceCount;
      }
      _state = _FaceTrackerState.idsReady;
      notifyListeners();
    });

    _isolate = await Isolate.spawn(
        _worker,
        _FacesTrackerIsolateInfo(
          _receive.sendPort,
          tracker.handle,
          _ids.getInfo(),
        ));
  }

  void process(CameraImage image, int orientation, bool frontFacing) {
    if (!_didLogCameraFormat) {
      _didLogCameraFormat = true;
      final planes = image.planes
          .map(
            (plane) =>
                '${plane.bytes.length}/${plane.bytesPerRow}/${plane.bytesPerPixel}',
          )
          .join(',');
      debugPrint(
        'FaceID frame format: ${image.width}x${image.height} '
        '${image.format.group.name} planes=$planes orientation=$orientation',
      );
    }
    if (_state == _FaceTrackerState.notInitialized) {
      _state = _FaceTrackerState.initializing;
      _initialize();
      return;
    }

    if (_state != _FaceTrackerState.waitingForImage) {
      return;
    }

    _state = _FaceTrackerState.waitingForIds;
    _frameStartedAt = DateTime.now();
    fsdkImage = _converter.convert(image);
    cameraImage = image;
    _send!.send(_WorkerData(fsdkImage!.handle, orientation, frontFacing));
  }

  List<FaceWrapper> faces() {
    if (_state != _FaceTrackerState.idsReady) {
      return <FaceWrapper>[];
    }
    return _ids.map((id) => FaceWrapper(id, tracker)).toList(growable: false);
  }

  void resetTracker() {
    tracker.clear();
    _setTrackerParameters();
  }

  void setNameForId(int id, String name) {
    tracker.lockID(id);
    tracker.setName(id, name);
    tracker.unlockID(id);
  }

  String getNameForId(int id) {
    tracker.lockID(id);
    final name = tracker.getName(id);
    tracker.unlockID(id);

    return name;
  }

  void next() {
    if (_state == _FaceTrackerState.idsReady) {
      _state = _FaceTrackerState.waitingForImage;
    }
  }
}

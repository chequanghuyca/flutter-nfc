class HelpText {
  String moveFaceIn;
  String moveFaceOut;
  String detecting;
  String faceInvalid;
  String faceNotMatch;
  String initial;
  String multiFace;
  String? moveFaceCenter;
  String verifying;
  String retryTitle;
  String retryAction;
  String closeAction;

  HelpText({
    required this.faceInvalid,
    required this.faceNotMatch,
    required this.moveFaceIn,
    required this.detecting,
    required this.moveFaceOut,
    required this.initial,
    required this.multiFace,
    this.moveFaceCenter,
    this.verifying = 'Đang xác thực khuôn mặt...',
    this.retryTitle = 'Chưa xác thực được',
    this.retryAction = 'Thử lại',
    this.closeAction = 'Thoát',
  });
}

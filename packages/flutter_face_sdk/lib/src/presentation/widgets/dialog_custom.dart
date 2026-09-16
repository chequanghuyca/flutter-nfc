import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'loading_widget.dart';

class DialogCustom {
  static void showLoadingDialog(BuildContext context,
          {int timeout = 15, bool isShowDuration = true}) =>
      showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black87,
          builder: (BuildContext context) {
            Future.delayed(Duration(seconds: timeout == -1 ? 99999 : timeout),
                () {
              try {
                Navigator.of(context).pop(true);
              } catch (e) {
                debugPrint(e.toString());
              }
            });
            return WillPopScope(
                onWillPop: () async => false,
                child: LoadingWidget(
                  isShowDuration: isShowDuration,
                ));
          });

  static void showMessageDialogIOS(
    BuildContext context, {
    String title = '',
    String description = '',
    String html = '',
    Function()? onPress,
    Function()? onPressX,
    bool enableButton = true,
    bool enableCancel = false,
    String buttonText = 'Ok',
    String buttonNoText = 'Cancel',
    Function()? callback,
  }) =>
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return WillPopScope(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: CupertinoAlertDialog(
                    title: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontFamily: 'SFProDisplay-Bold'),
                    ),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: Text(
                            description,
                            style: const TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      if (enableButton)
                        CupertinoDialogAction(
                          onPressed: onPress,
                          child: Text(buttonText),
                        ),
                      if (enableCancel)
                        CupertinoDialogAction(
                          onPressed: onPressX,
                          child: Text(
                            buttonNoText,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
                onWillPop: () async => false);
          }).then((value) {
        if (callback != null) {
          callback();
        }
      });
}

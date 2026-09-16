import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingWidget extends StatelessWidget {
  final RxInt durationObs = 15.obs;
  final bool isShowDuration;
  final String title;
  LoadingWidget({
    super.key,
    this.isShowDuration = true,
    this.title = '',
  });

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    Timer.periodic(
      oneSec,
      (Timer timer) {
        if (durationObs.value == 0) {
          timer.cancel();
        } else {
          durationObs.value--;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    startTimer();
    return SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Theme(
            data: ThemeData(
                cupertinoOverrideTheme:
                    const CupertinoThemeData(brightness: Brightness.dark)),
            child: WillPopScope(
                child: CupertinoAlertDialog(
                  title: const CupertinoActivityIndicator(),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Visibility(
                        visible: isShowDuration,
                        child: Obx(
                          () => Container(
                            margin: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${durationObs.value}',
                              style: const TextStyle(fontSize: 28),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onWillPop: () async => false)));
  }
}

import 'package:flutter/material.dart';

PreferredSizeWidget appbarWidget(BuildContext context) => AppBar(
      flexibleSpace: Container(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.grey,
          )),
      centerTitle: true,
      title: const Text(
        '',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    );

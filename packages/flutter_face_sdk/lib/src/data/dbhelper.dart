import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FaceIDDBHelper {
  late Database db;
  bool _isDatabaseOpen = false;
  String dbpath = 'faceid.db';
  late Directory tempDir;

  Future<void> openDB({bool enableLogging = true}) async {
    tempDir = await getTemporaryDirectory();
    if (!enableLogging) return;
    try {
      db = await openDatabase(dbpath, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE tb_faceid_log (id INTEGER PRIMARY KEY, description TEXT, liveness REAL, matching REAL, image TEXT, deviceName TEXT)');
      });
      _isDatabaseOpen = true;

      await clearData();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> closeDB() async {
    if (!_isDatabaseOpen) {
      return;
    }
    _isDatabaseOpen = false;
    if (db.isOpen) {
      await db.close();
    }
  }

  Future<void> addData({
    String description = '',
    double liveness = 0.0,
    double matching = 0.0,
    String imagePath = '',
    String deviceName = '',
    String? sub = '',
    int? countAllowSave,
    required Function(String desc, List<http.MultipartFile>) callback,
  }) async {
    try {
      await db.rawInsert(
          'INSERT INTO tb_faceid_log(description, liveness, matching, image, deviceName) VALUES(\'$description\', $liveness, $matching, \'$imagePath\', \'$deviceName\')');
    } catch (e) {
      log(e.toString());
    }

    saveDataToServer(callback: callback, countAllowSave: countAllowSave ?? -1);
  }

  Future<void> clearData() async {
    try {
      await db.rawDelete('DELETE FROM tb_faceid_log');
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> saveDataToServer(
      {required Function(String desc, List<http.MultipartFile> files) callback,
      int countAllowSave = -1}) async {
    try {
      var query = await db.rawQuery('SELECT * FROM tb_faceid_log');

      if (countAllowSave != -1 && query.length < countAllowSave) {
        return;
      }

      List<dynamic> data = jsonDecode(jsonEncode(query));

      if (data.isEmpty) {
        return;
      }

      List<http.MultipartFile> multipartFile = [];

      List<dynamic> desc = [];

      for (var item in data) {
        desc.add({
          'description': item['description'],
          'deviceName': item['deviceName'],
          'liveness': item['liveness'],
          'matching': item['matching'],
        });
        if (item['image'] == '' || !File(item['image']).existsSync()) {
          continue;
        }

        // final Uint8List list = await Utils.resizeImageUtil(file: File(item['image']));
        final multipartFile0 = http.MultipartFile.fromBytes(
          'imagesUrl',
          List<int>.from(File(item['image']).readAsBytesSync()),
          filename: path.basename(File(item['image']).path),
        );
        multipartFile.add(multipartFile0);

        // File(item['image']).delete();
      }

      callback(jsonEncode(desc), multipartFile);
      clearData();
    } catch (e) {
      log(e.toString());
    }
  }
}
